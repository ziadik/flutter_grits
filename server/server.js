// server.js
// Сервер для Grits Game - улучшенная версия с поддержкой дедупликации и пакетной обработки

const WebSocket = require("ws");
const http = require("http");
const express = require("express");

// ==================== КОНФИГУРАЦИЯ ====================
const PORT = 8080;
const GAME_CONFIG = {
  maxPlayersPerRoom: 4,
  minPlayersToStart: 2,
  mapWidth: 6400,
  mapHeight: 6400,
  respawnTime: 3.0,
  quadDamageDuration: 10.0,
  tickRate: 50, // мс между тиками (20 FPS для сервера)
  enableDedup: true, // Дедупликация state сообщений
};

// ==================== ПРОТОКОЛ ====================
// Флаги сообщений
const MSG_FLAGS = {
  NONE: 0,
  STATE: 1, // Сообщения с этим флагом дедуплицируются
};

// ID сообщений для компактной передачи
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

// ==================== HELPER ФУНКЦИИ ====================
function escapeString(str) {
  if (!str) return "";
  return str.replace(/#/g, "#1").replace(/:/g, "#2").replace(/\//g, "#3");
}

function unescapeString(str) {
  if (!str) return "";
  return str.replace(/#3/g, "/").replace(/#2/g, ":").replace(/#1/g, "#");
}

function packMessage(msgId, fields) {
  const parts = [msgId.toString()];
  for (const field of fields) {
    if (field === undefined || field === null) {
      parts.push("");
    } else if (typeof field === "object") {
      parts.push(escapeString(JSON.stringify(field)));
    } else if (typeof field === "boolean") {
      parts.push(field ? "Y" : "N");
    } else {
      parts.push(escapeString(field.toString()));
    }
  }
  return parts.join(":");
}

function unpackMessage(data) {
  const parts = data.split(":");
  const msgId = parseInt(parts[0]);
  const fields = parts.slice(1);
  return { msgId, fields };
}

// ==================== ИГРОВЫЕ КОМНАТЫ ====================
const rooms = new Map();

class Room {
  constructor(roomId) {
    this.id = roomId;
    this.players = new Map(); // playerId -> Player
    this.gameObjects = new Map();
    this.nextPlayerId = 1;
    this.nextObjectId = 1;
    this.state = "waiting"; // waiting, playing, ended
    this.lastUpdateTime = Date.now();
    this.spawnPoints = this._generateSpawnPoints();
    this._initGameObjects();

    // Для дедупликации
    this._lastStateMessages = new Map(); // playerId -> lastMessageHash

    console.log(`🏠 Комната ${roomId} создана`);
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
      { type: "HealthCanister", pos: { x: 2000, y: 2000 } },
      { type: "HealthCanister", pos: { x: 4400, y: 4400 } },
      { type: "EnergyCanister", pos: { x: 3200, y: 2000 } },
      { type: "EnergyCanister", pos: { x: 2000, y: 4400 } },
      { type: "QuadDamage", pos: { x: 3200, y: 3200 } },
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
      const team0Count = [...this.players.values()].filter(
        (p) => p.team === 0,
      ).length;
      const team1Count = [...this.players.values()].filter(
        (p) => p.team === 1,
      ).length;
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
      messageBuffer: "", // Буфер для пакетной отправки
    };

    this.players.set(playerId, player);
    console.log(
      `👤 Игрок ${playerName} (${playerId}) присоединился, команда ${team}`,
    );

    return player;
  }

  removePlayer(playerId) {
    const player = this.players.get(playerId);
    if (player) {
      console.log(`👋 Игрок ${player.name} покинул комнату ${this.id}`);
      this.players.delete(playerId);

      if (this.players.size === 0) {
        rooms.delete(this.id);
        console.log(`🏠 Комната ${this.id} удалена`);
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

    console.log(`🔄 Игрок ${player.name} воскрес`);
  }

  update(deltaTime) {
    if (this.state !== "playing") return;

    for (const [playerId, player] of this.players) {
      if (player.isDead) {
        player.respawnTimer -= deltaTime;
        if (player.respawnTimer <= 0) {
          this.respawnPlayer(playerId);
          this.broadcast({
            type: "player_respawned",
            playerId: playerId,
            x: player.position.x,
            y: player.position.y,
          });
        }
        continue;
      }

      if (
        player.damageMultiplier > 1.0 &&
        Date.now() / 1000 > player.quadDamageEndTime
      ) {
        player.damageMultiplier = 1.0;
      }

      if (player.energy < player.maxEnergy) {
        player.energy = Math.min(
          player.maxEnergy,
          player.energy + 20 * deltaTime,
        );
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
    return (
      this.players.size >= GAME_CONFIG.minPlayersToStart &&
      this.state === "waiting"
    );
  }

  startGame() {
    this.state = "playing";
    console.log(`🎮 Игра в комнате ${this.id} началась!`);
    this.broadcast({ type: "game_start" });
  }

  getGameState() {
    const playersState = [];
    for (const [id, player] of this.players) {
      playersState.push({
        id: id,
        name: player.name,
        team: player.team,
        health: player.health,
        maxHealth: player.maxHealth,
        energy: player.energy,
        maxEnergy: player.maxEnergy,
        position: player.position,
        velocity: player.velocity,
        angle: player.angle,
        walking: player.walking,
        isDead: player.isDead,
        weaponSlot: player.weaponSlot,
        kills: player.kills,
        deaths: player.deaths,
        damageMultiplier: player.damageMultiplier,
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

    this.broadcast({
      type: "health_update",
      playerId: targetId,
      health: target.health,
    });

    if (target.health <= 0) {
      target.health = 0;
      target.isDead = true;
      target.respawnTimer = GAME_CONFIG.respawnTime;
      shooter.kills++;
      target.deaths++;

      console.log(`💀 ${shooter.name} убил ${target.name}!`);

      this.broadcast({
        type: "player_died",
        playerId: targetId,
        killerId: shooterId,
      });

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
      case "HealthCanister":
        player.health = Math.min(player.maxHealth, player.health + 25);
        break;
      case "EnergyCanister":
        player.energy = Math.min(player.maxEnergy, player.energy + 25);
        break;
      case "QuadDamage":
        player.damageMultiplier = 4.0;
        player.quadDamageEndTime =
          Date.now() / 1000 + GAME_CONFIG.quadDamageDuration;
        break;
    }

    this.broadcast({
      type: "item_collected",
      itemId: itemId,
      playerId: playerId,
    });

    return true;
  }

  // Улучшенный бродкаст с буферизацией и дедупликацией
  broadcast(message, excludePlayerId = null, flags = MSG_FLAGS.NONE) {
    const messageStr = JSON.stringify(message);

    for (const [playerId, player] of this.players) {
      if (playerId === excludePlayerId) continue;
      if (!player.socket || player.socket.readyState !== WebSocket.OPEN)
        continue;

      // Дедупликация для STATE сообщений
      if (GAME_CONFIG.enableDedup && flags & MSG_FLAGS.STATE) {
        const key = `${message.type}_${JSON.stringify(message)}`;
        if (player._lastStateMessage === key) continue;
        player._lastStateMessage = key;
      }

      // Буферизация
      const msgToSend = JSON.stringify(message);
      if (player.messageBuffer) {
        player.messageBuffer += "/";
      }
      player.messageBuffer += msgToSend;
    }
  }

  // Отправка всех накопленных сообщений
  flushAll() {
    for (const [playerId, player] of this.players) {
      if (
        player.messageBuffer &&
        player.socket &&
        player.socket.readyState === WebSocket.OPEN
      ) {
        player.socket.send(player.messageBuffer);
        player.messageBuffer = "";
      }
    }
  }
}

// ==================== WEB SOCKET СЕРВЕР ====================
const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.use(express.static("public"));

// Хранилище активных соединений
const clients = new Map(); // ws -> { room, playerId }

wss.on("connection", (ws) => {
  console.log("🔌 Новое WebSocket соединение");

  let currentRoom = null;
  let currentPlayerId = null;
  let lastInputTime = Date.now();

  ws.on("message", (data) => {
    try {
      const message = JSON.parse(data.toString());
      handleMessage(ws, message);
    } catch (e) {
      console.error("Ошибка парсинга сообщения:", e);
    }
  });

  ws.on("close", () => {
    console.log("🔌 WebSocket соединение закрыто");
    if (currentRoom && currentPlayerId) {
      const room = rooms.get(currentRoom);
      if (room) {
        const wasPlaying = room.state === "playing";
        const isEmpty = room.removePlayer(currentPlayerId);

        if (!isEmpty) {
          room.broadcast(
            { type: "player_left", playerId: currentPlayerId },
            currentPlayerId,
          );

          if (wasPlaying && room.players.size < 2) {
            room.broadcast({
              type: "game_ended",
              reason: "Недостаточно игроков",
            });
            room.state = "ended";
          }
        }
      }
    }
  });

  function handleMessage(ws, msg) {
    switch (msg.type) {
      case "join":
        handleJoin(ws, msg);
        break;
      case "input":
        handleInput(msg);
        break;
      case "shoot":
        handleShoot(msg);
        break;
      case "hit":
        handleHit(msg);
        break;
      case "collect":
        handleCollect(msg);
        break;
      case "weapon_switch":
        handleWeaponSwitch(msg);
        break;
      case "leave":
        handleLeave();
        break;
      case "ping":
        ws.send(JSON.stringify({ type: "pong", timestamp: Date.now() }));
        break;
    }
  }

  function handleJoin(ws, msg) {
    const { playerName, roomId } = msg;

    let room = rooms.get(roomId);
    if (!room) {
      if (rooms.size > 50) {
        ws.send(
          JSON.stringify({ type: "error", message: "Сервер перегружен" }),
        );
        return;
      }
      room = new Room(roomId);
      rooms.set(roomId, room);
    }

    if (room.players.size >= GAME_CONFIG.maxPlayersPerRoom) {
      ws.send(JSON.stringify({ type: "error", message: "Комната полна" }));
      return;
    }

    const player = room.addPlayer(ws, playerName);
    currentRoom = room.id;
    currentPlayerId = player.id;

    // Отправляем подтверждение с начальным состоянием
    ws.send(
      JSON.stringify({
        type: "joined",
        playerId: player.id,
        team: player.team,
        roomId: room.id,
        state: room.state,
        players: Array.from(room.players.values()).map((p) => ({
          id: p.id,
          name: p.name,
          team: p.team,
          position: p.position,
          health: p.health,
          energy: p.energy,
          isDead: p.isDead,
        })),
        items: Array.from(room.gameObjects.values())
          .filter((obj) => !obj.collected)
          .map((obj) => ({
            id: obj.id,
            type: obj.type,
            position: obj.position,
          })),
      }),
    );

    // Оповещаем остальных
    room.broadcast(
      {
        type: "player_joined",
        player: {
          id: player.id,
          name: player.name,
          team: player.team,
          position: player.position,
        },
      },
      player.id,
    );

    if (room.canStart()) {
      room.startGame();
    }
  }

  function handleInput(msg) {
    if (!currentRoom || !currentPlayerId) return;

    const room = rooms.get(currentRoom);
    if (!room) return;

    const player = room.players.get(currentPlayerId);
    if (!player || player.isDead) return;

    if (msg.position) {
      player.position = {
        x: Math.min(GAME_CONFIG.mapWidth - 50, Math.max(50, msg.position.x)),
        y: Math.min(GAME_CONFIG.mapHeight - 50, Math.max(50, msg.position.y)),
      };
    }
    if (msg.velocity !== undefined) player.velocity = msg.velocity;
    if (msg.angle !== undefined) player.angle = msg.angle;
    if (msg.walking !== undefined) player.walking = msg.walking;

    lastInputTime = Date.now();
  }

  function handleShoot(msg) {
    if (!currentRoom || !currentPlayerId) return;

    const room = rooms.get(currentRoom);
    if (!room) return;

    const player = room.players.get(currentPlayerId);
    if (!player || player.isDead) return;

    const weaponCost = { 0: 2, 1: 4, 2: 10 }[player.weaponSlot] || 2;
    if (player.energy < weaponCost) return;

    player.energy -= weaponCost;

    room.broadcast(
      {
        type: "shoot",
        playerId: currentPlayerId,
        position: player.position,
        angle: player.angle,
        weaponSlot: player.weaponSlot,
      },
      currentPlayerId,
    );
  }

  function handleHit(msg) {
    if (!currentRoom || !currentPlayerId) return;

    const room = rooms.get(currentRoom);
    if (!room) return;

    const { targetId, damage } = msg;
    const result = room.dealDamage(currentPlayerId, targetId, damage);

    if (result) {
      const player = room.players.get(currentPlayerId);
      if (
        player &&
        player.socket &&
        player.socket.readyState === WebSocket.OPEN
      ) {
        player.socket.send(
          JSON.stringify({
            type: "hit_result",
            targetId: targetId,
            damage: result.damage,
            killed: result.killed,
          }),
        );
      }
    }
  }

  function handleCollect(msg) {
    if (!currentRoom || !currentPlayerId) return;

    const room = rooms.get(currentRoom);
    if (!room) return;

    const { itemId } = msg;
    room.collectItem(currentPlayerId, itemId);
  }

  function handleWeaponSwitch(msg) {
    if (!currentRoom || !currentPlayerId) return;

    const room = rooms.get(currentRoom);
    if (!room) return;

    const player = room.players.get(currentPlayerId);
    if (player) {
      player.weaponSlot = msg.slot;
      room.broadcast(
        {
          type: "weapon_switch",
          playerId: currentPlayerId,
          slot: msg.slot,
        },
        currentPlayerId,
      );
    }
  }

  function handleLeave() {
    if (currentRoom && currentPlayerId) {
      const room = rooms.get(currentRoom);
      if (room) {
        const wasPlaying = room.state === "playing";
        const isEmpty = room.removePlayer(currentPlayerId);

        if (!isEmpty) {
          room.broadcast(
            { type: "player_left", playerId: currentPlayerId },
            currentPlayerId,
          );

          if (wasPlaying && room.players.size < 2) {
            room.broadcast({
              type: "game_ended",
              reason: "Недостаточно игроков",
            });
            room.state = "ended";
          }
        }
      }
    }
    currentRoom = null;
    currentPlayerId = null;
  }
});

// ==================== ИГРОВОЙ ЦИКЛ ====================
let lastUpdate = Date.now();
let lastFlush = Date.now();
const TICK_MS = GAME_CONFIG.tickRate;
const FLUSH_MS = 33; // ~30 FPS отправка

function gameLoop() {
  const now = Date.now();
  let deltaTime = Math.min(0.033, (now - lastUpdate) / 1000);
  lastUpdate = now;

  // Обновляем все комнаты
  for (const [roomId, room] of rooms) {
    room.update(deltaTime);

    // Отправляем состояние игры (с флагом STATE для дедупликации)
    if (room.state === "playing" && room.players.size > 0) {
      const gameState = room.getGameState();
      room.broadcast(
        { type: "game_state", state: gameState },
        null,
        MSG_FLAGS.STATE,
      );
    }
  }

  // Периодическая отправка всех накопленных сообщений
  if (now - lastFlush >= FLUSH_MS) {
    for (const [roomId, room] of rooms) {
      room.flushAll();
    }
    lastFlush = now;
  }

  setTimeout(gameLoop, TICK_MS);
}

// ==================== HTTP ЭНДПОИНТЫ ====================
app.get("/rooms", (req, res) => {
  const roomsList = [];
  for (const [id, room] of rooms) {
    roomsList.push({
      id: id,
      players: room.players.size,
      maxPlayers: GAME_CONFIG.maxPlayersPerRoom,
      state: room.state,
    });
  }
  res.json(roomsList);
});

app.get("/stats", (req, res) => {
  res.json({
    rooms: rooms.size,
    totalPlayers: Array.from(rooms.values()).reduce(
      (sum, r) => sum + r.players.size,
      0,
    ),
    uptime: process.uptime(),
  });
});

// Эндпоинт для мониторинга (как в старом сервере)
app.get("/ping", (req, res) => {
  res.json({
    status: "ok",
    games: rooms.size,
    players: Array.from(rooms.values()).reduce(
      (sum, r) => sum + r.players.size,
      0,
    ),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
  });
});

app.post("/create-room", express.json(), (req, res) => {
  const { roomId, maxPlayers } = req.body;

  if (rooms.has(roomId)) {
    res.status(400).json({ error: "Room already exists" });
    return;
  }

  // Опционально: создаём комнату сразу
  // Комната создастся при первом подключении игрока

  res.json({ success: true, roomId: roomId });
});

// ==================== ЗАПУСК ====================
server.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🎮 GRITS GAME SERVER STARTED (Enhanced) 🎮              ║
║                                                              ║
║     Порт: ${PORT}                                              ║
║     Макс. игроков на комнату: ${GAME_CONFIG.maxPlayersPerRoom}            ║
║     Tick rate: ${GAME_CONFIG.tickRate}ms                             ║
║     Дедупликация: ${GAME_CONFIG.enableDedup ? "ВКЛ" : "ВЫКЛ"}                    ║
║                                                              ║
║     WebSocket: ws://localhost:${PORT}                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    `);

  gameLoop();
});
