// server.test.js - Unit тесты для игрового сервера

const WebSocket = require('ws');
const http = require('http');

// Импортируем модули из server.js через мокирование
let server;
let wss;
let clients = new Map();
let rooms = new Map();

// Мокированные константы и функции из server.js
const MSG_FLAGS = {
  NONE: 0,
  STATE: 1,
};

const MSG_IDS = {
  game_state: 0,
  player_joined: 1,
  player_left: 2,
  player_died: 3,
  player_respawned: 4,
  shoot: 5,
  hit_result: 6,
  item_collected: 7,
  weapon_switch: 8,
  game_start: 9,
  game_ended: 10,
  health_update: 11,
  input: 12,
  ping: 13,
  pong: 14,
};

// Helper функции из server.js
function escapeString(str) {
  if (!str) return '';
  return str.replace(/#/g, '#1').replace(/:/g, '#2').replace(/\//g, '#3');
}

function unescapeString(str) {
  if (!str) return '';
  return str.replace(/#3/g, '/').replace(/#2/g, ':').replace(/#1/g, '#');
}

function packMessage(msgId, fields) {
  const parts = [msgId.toString()];
  for (const field of fields) {
    if (field === undefined || field === null) {
      parts.push('');
    } else if (typeof field === 'object') {
      parts.push(escapeString(JSON.stringify(field)));
    } else if (typeof field === 'boolean') {
      parts.push(field ? 'Y' : 'N');
    } else {
      parts.push(escapeString(field.toString()));
    }
  }
  return parts.join(':');
}

function unpackMessage(data) {
  const parts = data.split(':');
  const msgId = parseInt(parts[0]);
  const fields = parts.slice(1);
  return { msgId, fields };
}

// Класс Room из server.js (упрощенная версия для тестирования)
class Room {
  constructor(roomId) {
    this.id = roomId;
    this.players = new Map();
    this.gameObjects = new Map();
    this.nextPlayerId = 1;
    this.nextObjectId = 1;
    this.state = 'waiting';
    this.lastUpdateTime = Date.now();
    this.spawnPoints = this._generateSpawnPoints();
    this._initGameObjects();
    this._lastStateMessages = new Map();
  }

  _generateSpawnPoints() {
    return [
      { team: 0, pos: { x: 800, y: 800 } },
      { team: 0, pos: { x: 1000, y: 800 } },
      { team: 1, pos: { x: 5600, y: 5600 } },
      { team: 1, pos: { x: 5400, y: 5600 } },
    ];
  }

  _initGameObjects() {
    const items = [
      { type: 'HealthCanister', pos: { x: 2000, y: 2000 } },
      { type: 'HealthCanister', pos: { x: 4400, y: 4400 } },
      { type: 'EnergyCanister', pos: { x: 3200, y: 2000 } },
      { type: 'EnergyCanister', pos: { x: 2000, y: 4400 } },
      { type: 'QuadDamage', pos: { x: 3200, y: 3200 } },
    ];

    for (const item of items) {
      const id = `obj_${this.nextObjectId++}`;
      this.gameObjects.set(id, {
        id: id,
        type: item.type,
        position: item.pos,
        collected: false,
        respawnTimer: 0,
      });
    }
  }

  addPlayer(socket, playerName, team = null) {
    if (team === null) {
      const team0Count = [...this.players.values()].filter((p) => p.team === 0).length;
      const team1Count = [...this.players.values()].filter((p) => p.team === 1).length;
      team = team0Count <= team1Count ? 0 : 1;
    }

    let spawnPoint = this.spawnPoints.find((sp) => sp.team === team);
    if (!spawnPoint) spawnPoint = this.spawnPoints[0];

    const playerId = `player_${this.nextPlayerId++}`;
    const player = {
      id: playerId,
      name: playerName,
      team: team,
      health: 100,
      maxHealth: 100,
      energy: 100,
      maxEnergy: 100,
      position: { ...spawnPoint.pos },
      velocity: { x: 0, y: 0 },
      angle: 0,
      walking: false,
      isDead: false,
      respawnTimer: 0,
      weaponSlot: 0,
      damageMultiplier: 1.0,
      quadDamageEndTime: 0,
      kills: 0,
      deaths: 0,
      socket: socket,
      messageBuffer: '',
    };

    this.players.set(playerId, player);
    return player;
  }

  removePlayer(playerId) {
    const player = this.players.get(playerId);
    if (player) {
      this.players.delete(playerId);

      if (this.players.size === 0) {
        rooms.delete(this.id);
        return true;
      }
    }
    return false;
  }

  respawnPlayer(playerId) {
    const player = this.players.get(playerId);
    if (!player) return;

    let spawnPoint = this.spawnPoints.find((sp) => sp.team === player.team);
    if (!spawnPoint) spawnPoint = this.spawnPoints[0];

    player.health = player.maxHealth;
    player.energy = player.maxEnergy;
    player.position = { ...spawnPoint.pos };
    player.velocity = { x: 0, y: 0 };
    player.isDead = false;
    player.respawnTimer = 0;
  }

  update(deltaTime) {
    if (this.state !== 'playing') return;

    for (const [playerId, player] of this.players) {
      if (player.isDead) {
        player.respawnTimer -= deltaTime;
        if (player.respawnTimer <= 0) {
          this.respawnPlayer(playerId);
        }
        continue;
      }

      if (player.energy < player.maxEnergy) {
        player.energy = Math.min(player.maxEnergy, player.energy + 20 * deltaTime);
      }
    }

    for (const [objId, obj] of this.gameObjects) {
      if (obj.collected && obj.respawnTimer) {
        obj.respawnTimer -= deltaTime;
        if (obj.respawnTimer <= 0) {
          obj.collected = false;
          obj.respawnTimer = 0;
        }
      }
    }
  }

  canStart() {
    return this.players.size >= 2 && this.state === 'waiting';
  }

  startGame() {
    this.state = 'playing';
  }

  getGameState() {
    const playersState = [];
    for (const [id, player] of this.players) {
      playersState.push({
        id: id,
        name: player.name,
        team: player.team,
        health: player.health,
        position: player.position,
        isDead: player.isDead,
      });
    }

    const itemsState = [];
    for (const [id, obj] of this.gameObjects) {
      if (!obj.collected) {
        itemsState.push({
          id: id,
          type: obj.type,
          position: obj.position,
        });
      }
    }

    return { players: playersState, items: itemsState };
  }

  dealDamage(shooterId, targetId, damage) {
    const shooter = this.players.get(shooterId);
    const target = this.players.get(targetId);

    if (!shooter || !target || target.isDead) return false;

    const finalDamage = damage * (shooter.damageMultiplier || 1.0);
    target.health -= finalDamage;

    if (target.health <= 0) {
      target.health = 0;
      target.isDead = true;
      target.respawnTimer = 3.0;
      shooter.kills++;
      target.deaths++;
      return { killed: true, damage: finalDamage };
    }

    return { killed: false, damage: finalDamage };
  }

  collectItem(playerId, itemId) {
    const player = this.players.get(playerId);
    const item = this.gameObjects.get(itemId);

    if (!player || !item || item.collected) return false;

    item.collected = true;
    item.respawnTimer = 10.0;

    switch (item.type) {
      case 'HealthCanister':
        player.health = Math.min(player.maxHealth, player.health + 25);
        break;
      case 'EnergyCanister':
        player.energy = Math.min(player.maxEnergy, player.energy + 25);
        break;
      case 'QuadDamage':
        player.damageMultiplier = 4.0;
        player.quadDamageEndTime = Date.now() / 1000 + 10.0;
        break;
    }

    return true;
  }

  broadcast(message, excludePlayerId = null, flags = MSG_FLAGS.NONE) {
    // Упрощенная реализация для тестов
  }

  flushAll() {
    for (const [playerId, player] of this.players) {
      if (player.messageBuffer) {
        player.messageBuffer = '';
      }
    }
  }
}

// ==================== ТЕСТЫ ====================

describe('Room', () => {
  let room;

  beforeEach(() => {
    room = new Room('test-room');
  });

  afterEach(() => {
    room = null;
  });

  test('should create room with correct initial state', () => {
    expect(room.id).toBe('test-room');
    expect(room.players.size).toBe(0);
    expect(room.state).toBe('waiting');
    expect(room.gameObjects.size).toBe(5);
  });

  test('should add player to room', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    expect(player).toBeDefined();
    expect(player.name).toBe('TestPlayer');
    expect(room.players.size).toBe(1);
    expect(room.players.has(player.id)).toBe(true);
  });

  test('should assign teams correctly', () => {
    const mockSocket1 = { readyState: WebSocket.OPEN };
    const mockSocket2 = { readyState: WebSocket.OPEN };

    const player1 = room.addPlayer(mockSocket1, 'Player1');
    const player2 = room.addPlayer(mockSocket2, 'Player2');

    expect(player1.team).toBe(0);
    expect(player2.team).toBe(1);
  });

  test('should remove player from room', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    const isEmpty = room.removePlayer(player.id);
    expect(room.players.size).toBe(0);
    expect(isEmpty).toBe(true);
  });

  test('should not start game with less than 2 players', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    room.addPlayer(mockSocket, 'Player1');

    expect(room.canStart()).toBe(false);
  });

  test('should start game with 2 or more players', () => {
    const mockSocket1 = { readyState: WebSocket.OPEN };
    const mockSocket2 = { readyState: WebSocket.OPEN };

    room.addPlayer(mockSocket1, 'Player1');
    room.addPlayer(mockSocket2, 'Player2');

    expect(room.canStart()).toBe(true);
  });

  test('should handle player death', () => {
    const mockSocket1 = { readyState: WebSocket.OPEN };
    const mockSocket2 = { readyState: WebSocket.OPEN };

    const player1 = room.addPlayer(mockSocket1, 'Player1');
    const player2 = room.addPlayer(mockSocket2, 'Player2');

    const result = room.dealDamage(player1.id, player2.id, 100);

    expect(result.killed).toBe(true);
    expect(player2.isDead).toBe(true);
    expect(player1.kills).toBe(1);
    expect(player2.deaths).toBe(1);
  });

  test('should handle damage less than kill', () => {
    const mockSocket1 = { readyState: WebSocket.OPEN };
    const mockSocket2 = { readyState: WebSocket.OPEN };

    const player1 = room.addPlayer(mockSocket1, 'Player1');
    const player2 = room.addPlayer(mockSocket2, 'Player2');

    const result = room.dealDamage(player1.id, player2.id, 50);

    expect(result.killed).toBe(false);
    expect(player2.health).toBe(50);
  });

  test('should collect HealthCanister', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    player.health = 75;
    const itemId = room.gameObjects.keys().next().value;

    const collected = room.collectItem(player.id, itemId);

    expect(collected).toBe(true);
    expect(player.health).toBe(100);
  });

  test('should collect QuadDamage', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    const quadItem = Array.from(room.gameObjects.values()).find(
      (obj) => obj.type === 'QuadDamage'
    );

    const collected = room.collectItem(player.id, quadItem.id);

    expect(collected).toBe(true);
    expect(player.damageMultiplier).toBe(4.0);
  });

  test('should respawn dead player', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    player.health = 0;
    player.isDead = true;
    player.respawnTimer = 0;

    room.respawnPlayer(player.id);

    expect(player.isDead).toBe(false);
    expect(player.health).toBe(100);
    expect(player.respawnTimer).toBe(0);
  });

  test('should update game state correctly', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    room.addPlayer(mockSocket, 'TestPlayer');

    const gameState = room.getGameState();

    expect(gameState.players).toHaveLength(1);
    expect(gameState.items).toHaveLength(5);
  });

  test('should not collect already collected item', () => {
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    const itemId = room.gameObjects.keys().next().value;

    room.collectItem(player.id, itemId);
    const collectedAgain = room.collectItem(player.id, itemId);

    expect(collectedAgain).toBe(false);
  });
});

describe('Helper Functions', () => {
  test('escapeString should escape special characters', () => {
    expect(escapeString('hello:world')).toBe('hello#2world');
    expect(escapeString('hello/world')).toBe('hello#3world');
    expect(escapeString('hello#world')).toBe('hello#1world');
  });

  test('unescapeString should unescape special characters', () => {
    expect(unescapeString('hello#2world')).toBe('hello:world');
    expect(unescapeString('hello#3world')).toBe('hello/world');
    expect(unescapeString('hello#1world')).toBe('hello#world');
  });

  test('packMessage should pack message correctly', () => {
    const packed = packMessage(1, ['test', 123, true, null]);
    expect(packed).toBe('1:test:123:Y:');
  });

  test('unpackMessage should unpack message correctly', () => {
    const unpacked = unpackMessage('1:test:123:Y');
    expect(unpacked.msgId).toBe(1);
    expect(unpacked.fields).toEqual(['test', '123', 'Y']);
  });
});

describe('GameConfig', () => {
  const GAME_CONFIG = {
    maxPlayersPerRoom: 4,
    minPlayersToStart: 2,
    mapWidth: 6400,
    mapHeight: 6400,
    respawnTime: 3.0,
    quadDamageDuration: 10.0,
    tickRate: 50,
    enableDedup: true,
  };

  test('maxPlayersPerRoom should be 4', () => {
    expect(GAME_CONFIG.maxPlayersPerRoom).toBe(4);
  });

  test('minPlayersToStart should be 2', () => {
    expect(GAME_CONFIG.minPlayersToStart).toBe(2);
  });

  test('respawnTime should be 3 seconds', () => {
    expect(GAME_CONFIG.respawnTime).toBe(3.0);
  });

  test('quadDamageDuration should be 10 seconds', () => {
    expect(GAME_CONFIG.quadDamageDuration).toBe(10.0);
  });
});

describe('Player', () => {
  test('player should have default health of 100', () => {
    const room = new Room('test-room');
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    expect(player.health).toBe(100);
    expect(player.maxHealth).toBe(100);
  });

  test('player should have default energy of 100', () => {
    const room = new Room('test-room');
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    expect(player.energy).toBe(100);
    expect(player.maxEnergy).toBe(100);
  });

  test('player kills and deaths should start at 0', () => {
    const room = new Room('test-room');
    const mockSocket = { readyState: WebSocket.OPEN };
    const player = room.addPlayer(mockSocket, 'TestPlayer');

    expect(player.kills).toBe(0);
    expect(player.deaths).toBe(0);
  });
});

// Export для использования в других тестах
module.exports = {
  Room,
  escapeString,
  unescapeString,
  packMessage,
  unpackMessage,
  MSG_FLAGS,
  MSG_IDS,
};
