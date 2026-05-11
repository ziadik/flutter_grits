# Grits Game Server

Сервер для игры Grits Game с поддержкой WebSocket подключения игроков.

## Быстрый старт

```bash
cd server
npm install
npm start
```

Сервер запустится на порту **8080**.

---

## Установка

```bash
cd server
npm install
```

---

## Запуск сервера

### Базовый запуск

```bash
npm start
```

### Запуск с автоматическим освобождением порта

Если порт занят, скрипт освободит его автоматически:

```bash
npm run start:clean
```

### Запуск с кастомным портом

```bash
PORT=3000 npm start
```

### Запуск с уровнем логирования

```bash
LOG_LEVEL=DEBUG npm start   # Все логи
LOG_LEVEL=INFO npm start    # Информационные логи (по умолчанию)
LOG_LEVEL=WARN npm start    # Только предупреждения
LOG_LEVEL=ERROR npm start   # Только ошибки
```

### Ожидаемый вывод при запуске

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🎮 GRITS GAME SERVER STARTED (Enhanced) 🎮              ║
║                                                              ║
║     Порт: 8080                                              ║
║     Макс. игроков на комнату: 4             ║
║     Tick rate: 50ms                                 ║
║     Дедупликация: ВКЛ                      ║
║     Уровень логов: INFO              ║
║                                                              ║
║     WebSocket: ws://localhost:8080                       ║
║     HTTP API:  http://localhost:8080                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Логирование

Сервер поддерживает 4 уровня логирования:

| Уровень | Описание                        | Пример                                  |
| ------- | ------------------------------- | --------------------------------------- |
| `DEBUG` | Детальная отладочная информация | Выстрелы, подбор предметов              |
| `INFO`  | Основные события (по умолчанию) | Подключение игроков, начало игры        |
| `WARN`  | Предупреждения                  | Комната полна, недостаточно энергии     |
| `ERROR` | Ошибки                          | Ошибки парсинга, проблемы с соединением |

### Примеры логов

```
2024-01-15T10:30:00.000Z [INFO] 🏠 Комната test-room создана { roomId: 'test-room' }
2024-01-15T10:30:05.000Z [INFO] 👤 Игрок Player1 (player_1) присоединился, команда 0
2024-01-15T10:30:10.000Z [INFO] 🎮 Игра в комнате test-room началась!
2024-01-15T10:30:15.000Z [INFO] 💀 Player1 убил Player2! { damage: 100 }
2024-01-15T10:30:20.000Z [INFO] 🔥 Игрок Player1 получил Quad Damage!
```

### Статистика сервера

Каждые 5 минут сервер выводит статистику:

```
[INFO] 📊 Статистика сервера {
  totalConnections: 10,
  totalDisconnections: 8,
  totalMessages: 1500,
  errors: 0,
  activeRooms: 2,
  activePlayers: 6
}
```

---

## Тестирование

### Запуск всех тестов

```bash
npm test
```

### Запуск тестов в режиме наблюдения

```bash
npm test -- --watch
```

### Запуск тестов с покрытием

```bash
npm test -- --coverage
```

### Покрываемые компоненты

| Компонент            | Описание                                   | Количество тестов |
| -------------------- | ------------------------------------------ | ----------------- |
| **Room**             | Создание комнат, игроки, команды, предметы | 13 тестов         |
| **Helper Functions** | Упаковка/распаковка сообщений              | 3 теста           |
| **GameConfig**       | Конфигурация игры                          | 4 теста           |
| **Player**           | Начальные значения игрока                  | 3 теста           |

**Всего: 24 теста**

---

## HTTP API Endpoints

### GET /ping

Проверка статуса сервера и базовая статистика.

**Запрос:**

```bash
curl http://localhost:8080/ping
```

**Ответ:**

```json
{
  "status": "ok",
  "games": 2,
  "players": 6,
  "uptime": 3600.5,
  "memory": {
    "rss": 12345678,
    "heapTotal": 1234567,
    "heapUsed": 987654,
    "external": 123456
  },
  "serverStats": {
    "totalConnections": 10,
    "totalDisconnections": 8,
    "totalMessages": 1500,
    "errors": 0
  }
}
```

### GET /rooms

Список всех активных комнат.

**Запрос:**

```bash
curl http://localhost:8080/rooms
```

**Ответ:**

```json
[
  {
    "id": "room1",
    "players": 2,
    "maxPlayers": 4,
    "state": "playing"
  },
  {
    "id": "room2",
    "players": 1,
    "maxPlayers": 4,
    "state": "waiting"
  }
]
```

### GET /stats

Расширенная статистика сервера.

**Запрос:**

```bash
curl http://localhost:8080/stats
```

**Ответ:**

```json
{
  "rooms": 2,
  "totalPlayers": 6,
  "uptime": 3600.5,
  "serverStats": {
    "startTime": 1705312200000,
    "totalConnections": 10,
    "totalDisconnections": 8,
    "totalMessages": 1500,
    "errors": 0
  }
}
```

### POST /create-room

Создание новой комнаты.

**Запрос:**

```bash
curl -X POST http://localhost:8080/create-room \
  -H "Content-Type: application/json" \
  -d '{"roomId": "my-room", "maxPlayers": 4}'
```

**Ответ:**

```json
{
  "success": true,
  "roomId": "my-room"
}
```

**Ошибка (комната существует):**

```json
{
  "error": "Room already exists"
}
```

---

## WebSocket Протокол

### Сообщения клиент -> сервер

| Сообщение       | Описание              | Параметры                                  |
| --------------- | --------------------- | ------------------------------------------ |
| `join`          | Подключение к комнате | `playerName`, `roomId`                     |
| `input`         | Ввод игрока           | `position`, `velocity`, `angle`, `walking` |
| `shoot`         | Выстрел               | `position`, `angle`, `weaponSlot`          |
| `hit`           | Попадание             | `targetId`, `damage`                       |
| `collect`       | Подбор предмета       | `itemId`                                   |
| `weapon_switch` | Смена оружия          | `slot`                                     |
| `respawn`       | Респавн               | `from`                                     |
| `leave`         | Выход из комнаты      | -                                          |
| `ping`          | Проверка соединения   | `timestamp`                                |

### Сообщения сервер -> клиент

| Сообщение          | Описание                  | Параметры                                                 |
| ------------------ | ------------------------- | --------------------------------------------------------- |
| `joined`           | Подтверждение подключения | `playerId`, `team`, `roomId`, `state`, `players`, `items` |
| `player_joined`    | Новый игрок в комнате     | `player`                                                  |
| `player_left`      | Игрок покинул комнату     | `playerId`                                                |
| `game_state`       | Состояние игры            | `state`                                                   |
| `shoot`            | Выстрел игрока            | `playerId`, `position`, `angle`, `weaponSlot`             |
| `hit_result`       | Результат попадания       | `targetId`, `damage`, `killed`                            |
| `player_died`      | Смерть игрока             | `playerId`, `killerId`                                    |
| `player_respawned` | Респавн игрока            | `playerId`, `x`, `y`                                      |
| `item_collected`   | Предмет подобран          | `itemId`, `playerId`                                      |
| `health_update`    | Обновление здоровья       | `playerId`, `health`                                      |
| `weapon_switch`    | Смена оружия              | `playerId`, `slot`                                        |
| `game_start`       | Начало игры               | -                                                         |
| `game_ended`       | Окончание игры            | `reason`                                                  |
| `pong`             | Ответ на ping             | `timestamp`                                               |
| `error`            | Ошибка                    | `message`                                                 |

---

## Пример подключения (JavaScript)

```javascript
const ws = new WebSocket("ws://localhost:8080");

ws.onopen = () => {
  console.log("Connected!");

  // Подключение к комнате
  ws.send(
    JSON.stringify({
      type: "join",
      playerName: "Player1",
      roomId: "room1",
    }),
  );
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log("Received:", message);

  switch (message.type) {
    case "joined":
      console.log("Joined room as", message.playerId);
      break;
    case "game_state":
      console.log("Game state:", message.state);
      break;
    case "player_died":
      console.log("Player died:", message.playerId);
      break;
  }
};

ws.onerror = (error) => {
  console.error("WebSocket error:", error);
};

ws.onclose = () => {
  console.log("Disconnected");
};
```

---

## Конфигурация

Изменить конфигурацию можно в файле `server.js`:

```javascript
const GAME_CONFIG = {
  maxPlayersPerRoom: 4, // Максимум игроков на комнату
  minPlayersToStart: 2, // Минимум игроков для старта
  mapWidth: 6400, // Ширина карты
  mapHeight: 6400, // Высота карты
  respawnTime: 3.0, // Время респавна (сек)
  quadDamageDuration: 10.0, // Длительность Quad Damage (сек)
  tickRate: 50, // Tick rate сервера (мс)
  enableDedup: true, // Дедупликация сообщений
};
```

---

## Troubleshooting

### Порт занят

**Ошибка:** `EADDRINUSE`

**Решение:**

```bash
# Освободить порт
lsof -ti:8080 | xargs kill

# Или использовать другой порт
PORT=3000 npm start
```

### Ошибка подключения с iOS устройства

Используйте IP-адрес вместо `localhost`:

```dart
// Вместо
'ws://localhost:8080'

// Используйте ваш IP
'ws://192.168.1.100:8080'
```

Найдите IP:

```bash
ipconfig getifaddr en0
```

### Нет логов

Убедитесь, что уровень логирования установлен правильно:

```bash
LOG_LEVEL=DEBUG npm start
```

---

## Лицензия

MIT
