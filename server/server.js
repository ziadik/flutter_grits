// server.js - полностью переработанная версия без конфликтов WebSocket
const WebSocket = require("ws");
const http = require("http");
const express = require("express");
const path = require("path");
const fs = require("fs");

// ==================== ЛОГИРОВАНИЕ ====================
const LOG_LEVELS = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
};

const LOG_LEVEL = process.env.LOG_LEVEL ? LOG_LEVELS[process.env.LOG_LEVEL] : LOG_LEVELS.INFO;

function log(level, message, data = null) {
  const timestamp = new Date().toISOString();
  if (LOG_LEVEL <= LOG_LEVELS[level]) {
    if (data) {
      console.log(`${timestamp} [${level}] ${message}`, data);
    } else {
      console.log(`${timestamp} [${level}] ${message}`);
    }
  }
}

const logger = {
  debug: (msg, data) => log("DEBUG", msg, data),
  info: (msg, data) => log("INFO", msg, data),
  warn: (msg, data) => log("WARN", msg, data),
  error: (msg, data) => log("ERROR", msg, data),
};

// ==================== КОНФИГУРАЦИЯ ====================
const PORT = process.env.PORT || 8080;
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

// Статистика сервера
const serverStats = {
  startTime: Date.now(),
  totalConnections: 0,
  totalDisconnections: 0,
  totalMessages: 0,
  errors: 0,
};

// ==================== СОЗДАНИЕ ДИРЕКТОРИЙ ====================
const publicDir = path.join(__dirname, "public");
const cssDir = path.join(publicDir, "css");
const logsDir = path.join(__dirname, "logs");

[publicDir, cssDir, logsDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// ==================== ГЕНЕРАЦИЯ CSS ФАЙЛА ====================
const cssContent = `/* Grits Game - общие стили */
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', system-ui, sans-serif; background: #0a0c15; color: #eef2ff; }
.container { max-width: 1600px; margin: 0 auto; padding: 20px; }
.header { text-align: center; margin-bottom: 30px; }
.header h1 { font-size: 2.2rem; background: linear-gradient(135deg, #a5f0ff, #7c4dff); -webkit-background-clip: text; background-clip: text; color: transparent; }
.card { background: #121826; border-radius: 20px; padding: 20px; border: 1px solid #2a2f3f; }
.card h2 { font-size: 1.4rem; border-left: 4px solid #7c4dff; padding-left: 12px; margin-bottom: 18px; }
input, select, button { background: #1e2436; border: 1px solid #2f3548; color: #fff; padding: 10px 14px; border-radius: 12px; font-size: 14px; outline: none; }
button { background: #2a2f42; cursor: pointer; font-weight: bold; }
button.primary { background: #7c4dff; }
button.danger { background: #c42e2e; }
.status-badge { display: inline-block; padding: 6px 12px; border-radius: 40px; font-size: 0.75rem; font-weight: bold; }
.status-online { background: #1f5e3a; color: #a3f0c0; }
.status-offline { background: #5e2a2a; color: #ffaeae; }
.flex-row { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
.flex-between { display: flex; justify-content: space-between; align-items: center; }
.dashboard { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
@media (max-width: 1000px) { .dashboard { grid-template-columns: 1fr; } }
.log-area { background: #0b0e16; border-radius: 16px; padding: 12px; height: 400px; overflow-y: auto; font-family: monospace; font-size: 12px; }
.log-entry { border-bottom: 1px solid #1e2332; padding: 6px 8px; }
.log-time { color: #5f7f9e; margin-right: 12px; }
.log-info { color: #a2d9ff; }
.log-error { color: #ff8a8a; }
.log-success { color: #8affc1; }
`;

fs.writeFileSync(path.join(cssDir, "style.css"), cssContent);
console.log("✅ CSS файл создан");

// ==================== ГЕНЕРАЦИЯ admin.html ====================
const adminHTML = `<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grits Game - Админ панель</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .rooms-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 20px; margin-top: 20px; }
        .room-card { background: #0b0e17; border-radius: 20px; border: 1px solid #262d3e; overflow: hidden; }
        .room-header { padding: 15px; background: #0a0e16; border-bottom: 1px solid #1f2538; display: flex; justify-content: space-between; align-items: center; }
        .room-state { padding: 4px 12px; border-radius: 40px; font-size: 0.7rem; font-weight: bold; }
        .state-waiting { background: #854d0e; color: #fde047; }
        .state-playing { background: #166534; color: #86efac; }
        .room-actions { display: flex; gap: 8px; margin-top: 12px; flex-wrap: wrap; }
        .events-panel { background: #0f131e; border-radius: 28px; border: 1px solid #262d3e; display: flex; flex-direction: column; height: 500px; }
        .events-header { padding: 20px; border-bottom: 1px solid #262d3e; display: flex; justify-content: space-between; flex-wrap: wrap; gap: 12px; }
        .events-list { flex: 1; overflow-y: auto; padding: 12px; }
        .event-item { background: #0a0e16; margin-bottom: 8px; padding: 10px 12px; border-radius: 12px; border-left: 3px solid; font-size: 12px; cursor: pointer; }
        .event-item:hover { background: #151c2a; }
        .event-critical { border-left-color: #ef4444; }
        .event-high { border-left-color: #f97316; }
        .event-info { border-left-color: #3b82f6; }
        .stats-bar { background: #0a0e16; padding: 12px; border-radius: 16px; margin-top: 12px; display: flex; gap: 16px; flex-wrap: wrap; }
        .stat-badge { background: #1e2438; padding: 4px 12px; border-radius: 20px; font-size: 11px; }
        .admin-header { background: linear-gradient(135deg, #0f111f, #0b0d18); padding: 20px 28px; border-radius: 28px; border: 1px solid #232838; margin-bottom: 24px; }
    </style>
</head>
<body>
<div class="container">
    <div class="admin-header">
        <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
            <div><h1>🎮 Grits Game | Admin Console</h1><p>Мониторинг в реальном времени</p></div>
            <div><span id="wsStatus">⚫ Подключение...</span></div>
        </div>
        <div class="stats-bar">
            <span class="stat-badge">📊 Событий: <span id="totalEvents">0</span></span>
            <span class="stat-badge">💀 Убийств: <span id="killsCount">0</span></span>
            <span class="stat-badge">🏠 Комнат: <span id="roomsCount">0</span></span>
        </div>
    </div>
    <div class="dashboard">
        <div class="card">
            <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
                <h2>🏠 Активные комнаты</h2>
                <div class="flex-row">
                    <input type="text" id="newRoomId" placeholder="ID комнаты">
                    <button id="createRoomBtn" class="primary">➕ Создать</button>
                    <button id="refreshRoomsBtn">🔄 Обновить</button>
                </div>
            </div>
            <div id="roomsGrid" class="rooms-grid"><div style="text-align: center; padding: 40px;">Загрузка...</div></div>
        </div>
        <div class="events-panel">
            <div class="events-header">
                <h2>📡 Поток событий</h2>
                <div class="flex-row">
                    <input type="text" id="roomFilter" placeholder="ID комнаты">
                    <button id="clearEventsBtn">🗑️ Очистить</button>
                    <button id="exportEventsBtn">📥 Экспорт</button>
                </div>
            </div>
            <div id="eventsList" class="events-list"><div style="text-align: center; padding: 40px;">Ожидание событий...</div></div>
        </div>
    </div>
</div>
<script>
    let eventWs = null, events = [], rooms = [];
    function initEventStream() {
        const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        eventWs = new WebSocket(protocol + '//' + location.host + '/events');
        eventWs.onopen = () => { document.getElementById('wsStatus').innerHTML = '🟢 Стрим активен'; };
        eventWs.onmessage = (e) => {
            const data = JSON.parse(e.data);
            if (data.type === 'server_event') addEvent(data.event);
            else if (data.type === 'history_events') data.events.forEach(ev => addEvent(ev, true));
        };
        eventWs.onclose = () => { document.getElementById('wsStatus').innerHTML = '🔴 Переподключение...'; setTimeout(initEventStream, 3000); };
    }
    function addEvent(event, isHistory = false) { events.unshift(event); if (events.length > 500) events.pop(); renderEvents(); updateStats(); }
    function renderEvents() {
        const container = document.getElementById('eventsList');
        const roomFilter = document.getElementById('roomFilter').value.toLowerCase();
        let filtered = roomFilter ? events.filter(e => (e.roomId || '').toLowerCase().includes(roomFilter)) : events;
        if (filtered.length === 0) { container.innerHTML = '<div style="text-align: center; padding: 40px;">Нет событий</div>'; return; }
        container.innerHTML = filtered.slice(0, 200).map(event => {
            const time = new Date(event.timestamp).toLocaleTimeString();
            let severityClass = 'event-info';
            if (event.severity === 'critical') severityClass = 'event-critical';
            else if (event.severity === 'high') severityClass = 'event-high';
            let icon = '📌';
            if (event.type?.includes('kill')) icon = '💀';
            if (event.type?.includes('joined')) icon = '👤';
            if (event.type?.includes('room')) icon = '🏠';
            return \`<div class="event-item \${severityClass}" onclick="alert(JSON.stringify(\${JSON.stringify(event)}, null, 2))">
                <div><span class="event-time">\${time}</span> <span>\${icon} \${event.type}</span></div>
                <div style="font-size: 11px; color:#9ca3af;">\${event.roomId ? '🏠 '+event.roomId : ''} \${event.playerName ? '👤 '+event.playerName : ''}</div>
            </div>\`;
        }).join('');
    }
    function updateStats() { document.getElementById('totalEvents').innerText = events.length; document.getElementById('killsCount').innerText = events.filter(e => e.type === 'player_killed').length; }
    async function loadRooms() {
        try { const res = await fetch('/api/admin/rooms'); const data = await res.json(); if(data.success) { rooms = data.rooms; document.getElementById('roomsCount').innerText = rooms.length; renderRooms(); } } catch(e) {}
    }
    function renderRooms() {
        const container = document.getElementById('roomsGrid');
        if (!rooms.length) { container.innerHTML = '<div style="text-align: center; padding: 40px;">Нет комнат</div>'; return; }
        container.innerHTML = rooms.map(room => \`
            <div class="room-card"><div class="room-header"><div><strong>🏠 \${room.id}</strong><div style="font-size:11px;">👥 \${room.players}/\${room.maxPlayers}</div></div>
            <div class="room-state state-\${room.state}">\${room.state === 'playing' ? '🎮 В игре' : '⏳ Ожидание'}</div></div>
            <div style="padding:15px;"><div class="room-actions">
                <button onclick="filterByRoom('\${room.id}')">📋 События</button>
                <button onclick="forceEnd('\${room.id}')" class="danger">⏹️ Завершить</button>
                <button onclick="deleteRoom('\${room.id}')" class="danger">🗑️ Удалить</button>
            </div></div></div>
        \`).join('');
    }
    function filterByRoom(roomId) { document.getElementById('roomFilter').value = roomId; renderEvents(); }
    async function forceEnd(roomId) { if(confirm('Завершить игру?')) await fetch(\`/api/admin/room/\${roomId}/end\`, { method: 'POST' }); loadRooms(); }
    async function deleteRoom(roomId) { if(confirm('Удалить комнату?')) await fetch(\`/api/admin/room/\${roomId}\`, { method: 'DELETE' }); loadRooms(); }
    async function createRoom() { const roomId = document.getElementById('newRoomId').value.trim(); if(roomId) await fetch('/api/admin/room/create', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ roomId, maxPlayers: 4 }) }); loadRooms(); document.getElementById('newRoomId').value = ''; }
    function exportEvents() { window.open('/api/events/export', '_blank'); }
    document.getElementById('createRoomBtn').onclick = createRoom;
    document.getElementById('refreshRoomsBtn').onclick = loadRooms;
    document.getElementById('clearEventsBtn').onclick = () => { events = []; renderEvents(); updateStats(); };
    document.getElementById('exportEventsBtn').onclick = exportEvents;
    document.getElementById('roomFilter').oninput = renderEvents;
    initEventStream(); loadRooms(); setInterval(loadRooms, 5000);
</script>
</body>
</html>`;

fs.writeFileSync(path.join(publicDir, "admin.html"), adminHTML);
console.log("✅ admin.html создан");

// ==================== ГЕНЕРАЦИЯ test.html ====================
const testHTML = `<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grits Game - Тестовый клиент</title>
    <link rel="stylesheet" href="/css/style.css">
    <style>
        .test-panel { max-width: 800px; margin: 0 auto; }
        .conn-info { background: #1a212f; border-radius: 14px; padding: 15px; margin: 20px 0; }
        .action-buttons { display: flex; gap: 10px; flex-wrap: wrap; margin: 20px 0; }
        .game-log { background: #0b0e16; border-radius: 16px; padding: 12px; height: 400px; overflow-y: auto; font-family: monospace; font-size: 12px; margin-top: 20px; }
    </style>
</head>
<body>
<div class="container test-panel">
    <div class="header"><h1>🎮 Grits Game - Тестовый клиент</h1><p>Подключение к серверу • Тестирование игровых событий</p></div>
    <div class="card">
        <h2>🔌 Подключение</h2>
        <div class="flex-row">
            <input type="text" id="wsUrl" value="ws://localhost:8080" placeholder="ws://localhost:8080" style="flex:2">
            <input type="text" id="playerName" placeholder="Имя" style="flex:1">
            <input type="text" id="roomId" value="test_room" placeholder="Комната" style="flex:1">
        </div>
        <div class="flex-row" style="margin-top:12px">
            <button id="connectBtn" class="primary">🔗 Подключиться</button>
            <button id="disconnectBtn" disabled>❌ Отключить</button>
        </div>
        <div class="conn-info">
            <div class="flex-between"><span>📡 Статус:</span><span id="connStatus" class="status-badge status-offline">Отключен</span></div>
            <div class="flex-between"><span>🆔 Ваш ID:</span><span id="myPlayerId">—</span></div>
            <div class="flex-between"><span>👥 Команда:</span><span id="myTeam">—</span></div>
        </div>
        <h2>🎮 Действия</h2>
        <div class="action-buttons">
            <button id="shootBtn" class="primary" disabled>🔫 Выстрел</button>
            <button id="pingBtn" disabled>🏓 Ping</button>
            <button id="leaveBtn" class="danger" disabled>🚪 Выйти</button>
        </div>
        <h2>📋 Логи</h2>
        <div id="logContainer" class="game-log"><div class="log-entry">📡 Готов к подключению...</div></div>
    </div>
</div>
<script>
    let ws = null, connected = false;
    function addLog(msg, type='info') {
        const d = document.createElement('div'); d.className = 'log-entry';
        const time = new Date().toLocaleTimeString();
        d.innerHTML = \`<span class="log-time">[\${time}]</span> <span class="log-\${type}">\${msg}</span>\`;
        document.getElementById('logContainer').appendChild(d); d.scrollIntoView();
    }
    function sendMessage(type, payload) { if(ws?.readyState === WebSocket.OPEN) { ws.send(JSON.stringify({type,...payload})); addLog(\`📤 \${type}\`, 'info'); } }
    function connect() {
        const url = document.getElementById('wsUrl').value;
        let name = document.getElementById('playerName').value;
        const room = document.getElementById('roomId').value;
        if(!name) { name = 'Tester_'+Math.floor(Math.random()*1000); document.getElementById('playerName').value = name; }
        ws = new WebSocket(url);
        ws.onopen = () => { connected=true; document.getElementById('connStatus').innerHTML='Подключен'; document.getElementById('connStatus').className='status-badge status-online'; addLog('✅ Подключен','success'); sendMessage('join',{playerName:name,roomId:room}); enableBtns(true); };
        ws.onmessage = (e) => { try { const msg=JSON.parse(e.data); addLog(\`📩 \${msg.type}\`,'event'); if(msg.type==='joined'){ document.getElementById('myPlayerId').innerText=msg.playerId; document.getElementById('myTeam').innerText=msg.team===0?'🔵 Команда A':'🔴 Команда B'; } } catch(err){} };
        ws.onclose = () => { connected=false; document.getElementById('connStatus').innerHTML='Отключен'; document.getElementById('connStatus').className='status-badge status-offline'; addLog('🔌 Отключен','warn'); enableBtns(false); resetUI(); };
    }
    function disconnect() { if(ws){ sendMessage('leave',{}); ws.close(); } enableBtns(false); resetUI(); }
    function resetUI() { document.getElementById('myPlayerId').innerText='—'; document.getElementById('myTeam').innerText='—'; }
    function enableBtns(en) { ['shootBtn','pingBtn','leaveBtn'].forEach(id=>document.getElementById(id).disabled=!en); document.getElementById('connectBtn').disabled=en; document.getElementById('disconnectBtn').disabled=!en; }
    document.getElementById('connectBtn').onclick = connect;
    document.getElementById('disconnectBtn').onclick = disconnect;
    document.getElementById('shootBtn').onclick = () => sendMessage('shoot',{position:{x:500,y:500},angle:0,weaponSlot:0});
    document.getElementById('pingBtn').onclick = () => sendMessage('ping',{timestamp:Date.now()});
    document.getElementById('leaveBtn').onclick = () => { sendMessage('leave',{}); setTimeout(()=>{ resetUI(); enableBtns(false); },500); };
    enableBtns(false);
    document.getElementById('playerName').value = 'Tester_'+Math.floor(Math.random()*1000);
</script>
</body>
</html>`;

fs.writeFileSync(path.join(publicDir, "test.html"), testHTML);
console.log("✅ test.html создан");

// ==================== СИСТЕМА СОБЫТИЙ ====================
const EventTypes = {
  PLAYER_JOINED_ROOM: 'player_joined_room',
  PLAYER_LEFT_ROOM: 'player_left_room',
  PLAYER_KILLED: 'player_killed',
  ROOM_CREATED: 'room_created',
  ROOM_DELETED: 'room_deleted',
  ROOM_GAME_STARTED: 'room_game_started',
  ROOM_GAME_ENDED: 'room_game_ended',
  SERVER_START: 'server_start',
};

class EventStore {
  constructor() {
    this.events = [];
    this.adminSubscribers = new Set();
    this.maxEvents = 1000;
  }
  addEvent(event) {
    const eventObj = { id: `${Date.now()}_${Math.random().toString(36).substr(2,6)}`, timestamp: new Date().toISOString(), timestampMs: Date.now(), severity: 'info', ...event };
    this.events.unshift(eventObj);
    if (this.events.length > this.maxEvents) this.events.pop();
    this.broadcastToAdmins(eventObj);
    return eventObj;
  }
  broadcastToAdmins(event) {
    const message = JSON.stringify({ type: 'server_event', event });
    for (const subscriber of this.adminSubscribers) {
      if (subscriber.readyState === WebSocket.OPEN) subscriber.send(message);
    }
  }
  subscribeAdmin(ws) {
    this.adminSubscribers.add(ws);
    ws.send(JSON.stringify({ type: 'history_events', events: this.events.slice(0, 50) }));
  }
  unsubscribeAdmin(ws) { this.adminSubscribers.delete(ws); }
  getEvents(limit) { return this.events.slice(0, limit); }
  clearEvents() { this.events = []; }
}

const eventStore = new EventStore();

// ==================== КЛАСС КОМНАТЫ ====================
class Room {
  constructor(roomId, maxPlayers = 4) {
    this.id = roomId;
    this.maxPlayers = maxPlayers;
    this.players = new Map();
    this.state = "waiting";
    this.createdAt = Date.now();
    eventStore.addEvent({ type: EventTypes.ROOM_CREATED, roomId: this.id });
  }
  addPlayer(socket, playerName, team = null) {
    if (this.players.size >= this.maxPlayers) return null;
    const playerId = `player_${Date.now()}_${Math.random().toString(36).substr(2,4)}`;
    const player = { id: playerId, name: playerName, team: team || 0, socket: socket, health: 100, kills: 0 };
    this.players.set(playerId, player);
    eventStore.addEvent({ type: EventTypes.PLAYER_JOINED_ROOM, roomId: this.id, playerId, playerName: playerName });
    return player;
  }
  removePlayer(playerId) {
    const player = this.players.get(playerId);
    if (player) {
      this.players.delete(playerId);
      eventStore.addEvent({ type: EventTypes.PLAYER_LEFT_ROOM, roomId: this.id, playerId });
      if (this.players.size === 0) {
        rooms.delete(this.id);
        eventStore.addEvent({ type: EventTypes.ROOM_DELETED, roomId: this.id });
      }
    }
  }
  startGame() {
    if (this.state !== "waiting") return;
    this.state = "playing";
    eventStore.addEvent({ type: EventTypes.ROOM_GAME_STARTED, roomId: this.id, playerCount: this.players.size });
    this.broadcast({ type: "game_start" });
  }
  forceEndGame(reason) {
    if (this.state === "playing") {
      this.state = "ended";
      eventStore.addEvent({ type: EventTypes.ROOM_GAME_ENDED, roomId: this.id, reason });
      this.broadcast({ type: "game_ended", reason });
    }
  }
  broadcast(message, excludeId = null) {
    const msg = JSON.stringify(message);
    for (const [id, player] of this.players) {
      if (id !== excludeId && player.socket?.readyState === WebSocket.OPEN) {
        player.socket.send(msg);
      }
    }
  }
  getSummary() {
    return { id: this.id, players: this.players.size, maxPlayers: this.maxPlayers, state: this.state };
  }
}

// ==================== СОЗДАНИЕ HTTP СЕРВЕРА ====================
const app = express();
const server = http.createServer(app);

// Настройка Express
app.use(express.json());
app.use(express.static(publicDir));

// CORS заголовки для кросс-доменных запросов
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Хранилище комнат
const rooms = new Map();

// ==================== СОЗДАНИЕ WebSocket СЕРВЕРА ====================
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws, req) => {
  const url = req.url || '/';
  
  // Логирование подключения
  logger.info(`🔌 New WebSocket connection to: ${url}`);
  
  // Админский WebSocket для событий
  if (url === '/events') {
    logger.info("👑 Администратор подключился к событиям");
    eventStore.subscribeAdmin(ws);
    ws.on('close', () => {
      logger.info("👑 Администратор отключился от событий");
      eventStore.unsubscribeAdmin(ws);
    });
    return;
  }
  
  // Игровой WebSocket
  logger.debug(`Игрок подключился к ${url}`);
  serverStats.totalConnections++;
  let currentRoom = null;
  let currentPlayerId = null;

  ws.on("message", (data) => {
    serverStats.totalMessages++;
    logger.debug(`📨 Received: ${data.toString().substring(0, 100)}`);
    try {
      const message = JSON.parse(data.toString());
      handleGameMessage(ws, message);
    } catch (e) {
      serverStats.errors++;
      logger.error(`Ошибка парсинга: ${e.message}`);
    }
  });

  ws.on("close", () => {
    serverStats.totalDisconnections++;
    logger.info(`🔌 WebSocket closed for player ${currentPlayerId || 'unknown'}`);
    if (currentRoom && currentPlayerId) {
      const room = rooms.get(currentRoom);
      if (room) {
        room.removePlayer(currentPlayerId);
        room.broadcast({ type: "player_left", playerId: currentPlayerId }, currentPlayerId);
      }
    }
  });

  ws.on("error", (error) => {
    logger.error(`❌ WebSocket error: ${error.message}`);
  });

  function handleGameMessage(ws, msg) {
    switch (msg.type) {
      case "join":
        let room = rooms.get(msg.roomId);
        if (!room) {
          room = new Room(msg.roomId);
          rooms.set(msg.roomId, room);
        }
        const player = room.addPlayer(ws, msg.playerName);
        if (player) {
          currentRoom = room.id;
          currentPlayerId = player.id;
          ws.send(JSON.stringify({ 
            type: "joined", 
            playerId: player.id, 
            team: player.team, 
            roomId: room.id, 
            state: room.state 
          }));
          room.broadcast({ 
            type: "player_joined", 
            player: { id: player.id, name: player.name, team: player.team } 
          }, player.id);
          if (room.players.size >= GAME_CONFIG.minPlayersToStart && room.state === "waiting") {
            room.startGame();
          }
        }
        break;
      case "client_event":
        // Обработка событий от клиента для логирования
        if (msg.event) {
          eventStore.addEvent({
            type: msg.event.type || 'client_message',
            roomId: msg.event.roomId,
            playerId: msg.event.playerId,
            playerName: player?.name,
            message: msg.event.message,
            data: msg.event.data,
            severity: msg.event.type?.includes('error') ? 'critical' : 'info'
          });
          logger.info(`📡 Client event: ${msg.event.type} - ${msg.event.message || ''}`);
        }
        break;
      case "shoot":
        if (currentRoom && currentPlayerId) {
          const room = rooms.get(currentRoom);
          if (room) {
            room.broadcast({ 
              type: "shoot", 
              playerId: currentPlayerId, 
              position: msg.position, 
              angle: msg.angle,
              weaponSlot: msg.weaponSlot || 0
            }, currentPlayerId);
          }
        }
        break;
      case "hit":
        if (currentRoom && currentPlayerId) {
          const room = rooms.get(currentRoom);
          if (room && msg.targetId) {
            eventStore.addEvent({ 
              type: EventTypes.PLAYER_KILLED, 
              roomId: currentRoom, 
              killerId: currentPlayerId, 
              victimId: msg.targetId,
              damage: msg.damage
            });
            ws.send(JSON.stringify({ 
              type: "hit_result", 
              targetId: msg.targetId, 
              damage: msg.damage, 
              killed: true 
            }));
          }
        }
        break;
      case "ping":
        ws.send(JSON.stringify({ type: "pong", timestamp: Date.now() }));
        break;
      case "leave":
        if (currentRoom && currentPlayerId) {
          const room = rooms.get(currentRoom);
          if (room) {
            room.removePlayer(currentPlayerId);
            room.broadcast({ type: "player_left", playerId: currentPlayerId }, currentPlayerId);
          }
          currentRoom = null;
          currentPlayerId = null;
        }
        break;
    }
  }
});

// ==================== HTTP API ЭНДПОЙНТЫ ====================
app.get("/api/admin/rooms", (req, res) => {
  const roomsList = [];
  for (const [id, room] of rooms) roomsList.push(room.getSummary());
  res.json({ success: true, rooms: roomsList, total: roomsList.length });
});

app.post("/api/admin/room/create", (req, res) => {
  const { roomId, maxPlayers } = req.body;
  if (!roomId) return res.status(400).json({ success: false, error: "roomId required" });
  if (rooms.has(roomId)) return res.status(400).json({ success: false, error: "Room already exists" });
  const room = new Room(roomId, maxPlayers || GAME_CONFIG.maxPlayersPerRoom);
  rooms.set(roomId, room);
  res.json({ success: true, room: room.getSummary() });
});

app.delete("/api/admin/room/:roomId", (req, res) => {
  const room = rooms.get(req.params.roomId);
  if (!room) return res.status(404).json({ success: false, error: "Room not found" });
  room.broadcast({ type: "game_ended", reason: "Комната удалена администратором" });
  for (const [id, player] of room.players) {
    if (player.socket && player.socket.readyState === WebSocket.OPEN) {
      player.socket.close();
    }
  }
  rooms.delete(req.params.roomId);
  res.json({ success: true });
});

app.post("/api/admin/room/:roomId/end", (req, res) => {
  const room = rooms.get(req.params.roomId);
  if (!room) return res.status(404).json({ success: false, error: "Room not found" });
  room.forceEndGame(req.body.reason || "Admin force ended");
  res.json({ success: true });
});

app.get("/api/events", (req, res) => {
  const limit = parseInt(req.query.limit) || 100;
  res.json({ success: true, events: eventStore.getEvents(limit) });
});

app.get("/api/events/stats", (req, res) => {
  const stats = { total: eventStore.events.length, byType: {} };
  for (const e of eventStore.events) {
    stats.byType[e.type] = (stats.byType[e.type] || 0) + 1;
  }
  res.json({ success: true, stats });
});

app.delete("/api/events/clear", (req, res) => {
  eventStore.clearEvents();
  res.json({ success: true });
});

app.get("/api/events/export", (req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.setHeader("Content-Disposition", `attachment; filename=events_${Date.now()}.json`);
  res.json(eventStore.getEvents(1000));
});

app.get("/ping", (req, res) => {
  const totalPlayers = Array.from(rooms.values()).reduce((sum, r) => sum + r.players.size, 0);
  res.json({ 
    status: "ok", 
    games: rooms.size, 
    players: totalPlayers, 
    uptime: process.uptime(),
    serverStats: {
      totalConnections: serverStats.totalConnections,
      totalDisconnections: serverStats.totalDisconnections,
      totalMessages: serverStats.totalMessages,
      errors: serverStats.errors
    }
  });
});

app.get("/rooms", (req, res) => {
  const list = [];
  for (const [id, room] of rooms) list.push(room.getSummary());
  res.json(list);
});

app.get("/stats", (req, res) => {
  const totalPlayers = Array.from(rooms.values()).reduce((sum, r) => sum + r.players.size, 0);
  res.json({ 
    rooms: rooms.size, 
    totalPlayers: totalPlayers, 
    uptime: process.uptime(),
    serverStats: {
      startTime: serverStats.startTime,
      totalConnections: serverStats.totalConnections,
      totalDisconnections: serverStats.totalDisconnections,
      totalMessages: serverStats.totalMessages,
      errors: serverStats.errors
    }
  });
});

// ==================== ЗАПУСК СЕРВЕРА ====================
server.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🎮 GRITS GAME SERVER STARTED (Fixed) 🎮                 ║
║                                                              ║
║     Порт: ${PORT}                                              ║
║     Макс. игроков на комнату: ${GAME_CONFIG.maxPlayersPerRoom}            ║
║                                                              ║
║     📡 WebSocket: ws://localhost:${PORT}                      ║
║     👑 Админ-панель: http://localhost:${PORT}/admin.html      ║
║     🎮 Тестовый клиент: http://localhost:${PORT}/test.html    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
  `);
  
  eventStore.addEvent({ 
    type: EventTypes.SERVER_START, 
    port: PORT,
    version: "2.0.0"
  });
});

server.on('error', (err) => {
  serverStats.errors++;
  if (err.code === 'EADDRINUSE') {
    console.error(`\n❌ ОШИБКА: Порт ${PORT} уже занят!`);
    console.error(`\nРешение: lsof -ti:${PORT} | xargs kill -9\n`);
  } else {
    logger.error(`Ошибка сервера: ${err.message}`);
  }
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Сервер остановлен');
  process.exit(0);
});