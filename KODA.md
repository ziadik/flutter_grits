# KODA.md — Контекст проекта Flutter Grits

> Файл содержит полную документацию проекта для AI-ассистента Koda. Используй эту информацию для понимания архитектуры, стилей кодирования и целей проекта.

---

## 📋 Обзор проекта

**Название:** `flutter_grits`  
**Тип:** 2D-мультиплеерная игра на движке Flame (Flutter)  
**Язык:** Dart / Flutter  
**Статус:** Активная разработка, порт из оригинального JS-проекта

### 🎯 Назначение

Проект представляет собой переписывание классической 2D-игры **Grits** (оригинал на JavaScript/Box2D) на Flutter с использованием игрового движка **Flame**. Игра — командный шутер с видом сверху, где игроки управляют танкоподобными юнитами с турелью, перемещаются по карте, сражаются друг с другом и собирают бонусы.

### 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Application                   │
│  ┌───────────────────────────────────────────────────┐  │
│  │                  GritsGame (FlameGame)            │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────┐ │  │
│  │  │   Camera    │  │  InputManager│  │ HUD Layer│ │  │
│  │  └─────────────┘  └──────────────┘  └──────────┘ │  │
│  │                         │                         │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │              GameWorld (World)              │  │  │
│  │  │  ┌──────────┐  ┌────────────┐  ┌────────┐  │  │  │
│  │  │  │ TiledMap │  │   Player   │  │Spawner │  │  │  │
│  │  │  │(map1.tmx)│  │(PositionComponent)      │  │  │  │
│  │  │  └──────────┘  └────────────┘  └────────┘  │  │  │
│  │  │  ┌────────────┐  ┌──────────────────────┐  │  │  │
│  │  │  │Environment │  │    SpawnSystem       │  │  │  │
│  │  │  │Components  │  │ (таймерный спавн)    │  │  │  │
│  │  │  └────────────┘  └──────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 🛠️ Технологический стек

| Категория          | Технология    | Версия      |
| ------------------ | ------------- | ----------- |
| **Фреймворк**      | Flutter       | SDK ^3.10.3 |
| **Игровой движок** | Flame         | ^1.37.0     |
| **Карты**          | flame_tiled   | ^3.1.1      |
| **Математика**     | vector_math   | ^2.2.0      |
| **Линтинг**        | flutter_lints | ^6.0.0      |

---

## 📁 Структура проекта

```
flutter_grits/
├── .metadata                 # Метаданные Flutter проекта
├── pubspec.yaml              # Зависимости и конфигурация
├── analysis_options.yaml     # Правила линтинга
├── README.md                 # Краткое описание
├── KODA.md                   # Этот файл — контекст для AI
│
├── lib/                      # Исходный код приложения
│   ├── main.dart             # Точка входа, инициализация ResourceManager
│   └── flame_game/
│       ├── game/
│       │   ├── grits_game.dart         # Основной класс игры (FlameGame)
│       │   ├── camera_effects.dart     # Эффекты камеры (закомментировано)
│       │   └── world/
│       │       └── game_world.dart     # Игровой мир (загрузка карты, игрока)
│       │
│       ├── entities/
│       │   └── player.dart             # Игрок с анимацией ходьбы (30 кадров/направление)
│       │                               # + 3 слота оружия
│       │
│       ├── components/
│       │   ├── environment_component.dart  # Спавнеры, спавн-поинты, pickup'ы
│       │   ├── energy_bar_component.dart   # UI: полоска энергии
│       │   ├── health_bar_component.dart   # UI: полоска здоровья
│       │   └── hud/
│       │       ├── fps_counter.dart        # FPS счетчик (правый верхний угол)
│       │       └── minimap.dart            # Мини-карта с камерой (левый нижний угол)
│       │
│       ├── managers/
│       │   ├── input_manager.dart          # WASD/стрелки + мышь (целиться)
│       │   └── resource_manager.dart       # Асинхронная загрузка ассетов
│       │
│       ├── models/
│       │   ├── player_animator.dart        # Загрузка анимаций из TexturePacker JSON
│       │   └── sprite_data.dart            # Модель данных спрайта
│       │
│       ├── weapons/                        # ⭐ НОВАЯ ДИРЕКТОРИЯ!
│       │   ├── weapon_base.dart            # Базовый класс оружия + ProjectileBase
│       │   ├── weapon_registry.dart        # Factory для создания оружия
│       │   └── machine_gun.dart            # ⭐ Реализовано! Первое оружие
│       │
│       ├── projectiles/                    # ⭐ НОВАЯ ДИРЕКТОРИЯ!
│       │   └── bullet.dart                 # ⭐ Реализовано! Базовый снаряд
│       │
│       └── systems/
│           └── spawn_system.dart           # Система спавна предметов
│
├── old_code_js/                # Оригинальный JS код (источник логики)
│   ├── shared/                 # Общие компоненты (сервер + клиент)
│   │   ├── core/               # Constants, GameEngine, Player, TileMap, PhysicsEngine
│   │   ├── weapons/            # MachineGun, RocketLauncher, Shield, Sword, etc.
│   │   ├── weaponinstances/    # Снаряды и эффекты
│   │   └── items/              # EnergyCanister, HealthCanister, QuadDamage
│   └── scripts/                # Клиентская часть (RenderEngine, InputEngine, GUI)
│
├── assets/                     # Игровые ресурсы
│   ├── grits_effects.json      # TexturePacker JSON (2900+ спрайтов)
│   ├── grits_effects.png       # ⚠️ ОТсутствует! Спрайт-лист эффектов
│   ├── grits_master.png        # ⚠️ Отсутствует! Tileset карты 2048x2048
│   ├── images/
│   │   └── grits_master.png    # Дубликат tileset (тоже отсутствует)
│   ├── maps/
│   │   └── small_map1.json     # Маленькая карта для тестирования (64x48)
│   ├── tiles/
│   │   ├── map1.tmx            # Основная карта (Tiled)
│   │   ├── map1.json           # JSON версия карты
│   │   └── small_map1.tmx      # Маленькая карта (Tiled)
│   └── sound/
│       ├── bg_game.ogg         # Фоновая музыка (игра)
│       ├── bg_menu.ogg         # Фоновая музыка (меню)
│       ├── bounce0.ogg         # Звуки: прыжок, взрыв, оружие, меню
│       ├── explode0.ogg        # ... (всего 12 звуков)
│       └── LICENSE.txt         # Лицензии на музыку
│
└── web/                        # Веб-сборка (Flutter Web)
    └── index.html
```

---

## 🔑 Ключевые компоненты

### 🎮 GritsGame (`lib/flame_game/game/grits_game.dart`)

**Назначение:** Основной класс игры, наследуется от `FlameGame`.

**Ответственность:**

- Инициализация `InputManager` и `GameWorld`
- Настройка камеры с `FixedSizeViewport(800x800)`
- Обработка событий клавиатуры (`KeyboardEvents`)
- Обновление `SpawnSystem` каждый кадр

**Ключевой код:**

```dart
class GritsGame extends FlameGame with KeyboardEvents {
  late InputManager inputManager;
  late GameWorld gameWorld;

  @override
  Future<void> onLoad() async {
    inputManager = InputManager();
    gameWorld = GameWorld(resourceManager: resourceManager, inputManager: inputManager);
    world = gameWorld;
    await _setupCamera();
  }
}
```

**Примечание:** В коде есть закомментированный блок с альтернативной реализацией камеры с зумом и HUD.

---

### 🌍 GameWorld (`lib/flame_game/game/world/game_world.dart`)

**Назначение:** Игровой мир — контейнер для всех игровых объектов.

**Ответственность:**

- Загрузка карты Tiled (`map1.tmx` с тайлом 64px)
- Создание игрока в точке спавна
- Загрузка объектов окружения (спавнеры, спавн-поинты)
- Инициализация `SpawnSystem`
- Обновление спавнеров каждый кадр

**Ключевые поля:**

```dart
class GameWorld extends World {
  late Player player;
  late TiledComponent tiledMap;
  late SpawnSystem spawnSystem;
  int mapWidth = 6400;  // 100 тайлов × 64px
  int mapHeight = 6400;
  final List<EnvironmentComponent> spawners = [];
}
```

**Логика спавна:**

- Считывает слой `Environment` из Tiled карты
- Создает `EnvironmentComponent` для каждого объекта
- Регистрирует спавнеры в `SpawnSystem`

---

### 👤 Player (`lib/flame_game/entities/player.dart`)

**Назначение:** Класс игрока — позиционируемый компонент с анимацией.

**Статистика:**

- Здоровье: `health = 100 / maxHealth = 100`
- Энергия: `energy = 100 / maxEnergy = 100` (восстанавливается 20/сек)
- Команда: `team = 0` или `1`
- Размер: `128x128` пикселей

**Анимация:**

- 4 направления: `up`, `left`, `down`, `right`
- 30 кадров на направление (из `walk_<dir>_XXXX.png`)
- Класс `TrimmedSpriteAnimationComponent` обрабатывает обрезанные спрайты
- Анимация останавливается на последнем кадре при остановке

**Движение:**

- Скорость: `200.0` пикселей/секунду
- Управление: WASD или стрелки
- Прицеливание: мышь (угол турели)

**Ключевой метод:**

```dart
void updateMovement(double dt) {
  final moveDir = inputManager!.moveDirection;
  walking = moveDir != Vector2.zero();
  // Обновление анимации и позиции
  position += moveDir * _walkSpeed * dt;
}
```

**Компоненты игрока:**

- `_legsComponent` — анимация ног
- `_legsMaskComponent` — маска ног (цвет команды)
- `_turretComponent` — турель (статичный спрайт)
- `_healthBar`, `_energyBar` — UI полоски
- `_nameLabel` — имя игрока

---

### 🎨 PlayerAnimator (`lib/flame_game/models/player_animator.dart`)

**Назначение:** Загрузка и управление анимациями из TexturePacker JSON.

**Структура данных:**

```dart
class TrimmedSprite {
  final Sprite sprite;
  final Rect spriteSourceSize;  // Позиция обрезки
  final Size sourceSize;        // Оригинальный размер (128x128)
  final bool trimmed;
  final Rect frame;
}
```

**Методы:**

- `loadImages(Image)` — загрузка изображения спрайт-листа
- `loadFromJson(Map)` — парсинг JSON от TexturePacker
- `getLegSprites(String direction)` — получение кадров ходьбы
- `getLegMaskSprites(String direction)` — получение кадров маски
- `getTurretSprite()` — получение спрайта турели

**Примечание:** Метод `renderCentered()` центрирует обрезанные спрайты без растягивания.

---

### 🎯 InputManager (`lib/flame_game/managers/input_manager.dart`)

**Назначение:** Обработка ввода с клавиатуры и мыши.

**Функции:**

- Клавиатура: WASD / стрелки — направление движения
- Мышь: целевая позиция для прицеливания
- Метод `moveDirection` возвращает нормализованный вектор движения

**Настройки:**

```dart
bool keyboardEnabled = true;
bool mouseMovementEnabled = true;
double mouseSensitivity = 1.0;
```

**Примечание:** Поддержка мыши частично реализована (целиться можно, но стрельбы нет).

---

### 📦 ResourceManager (`lib/flame_game/managers/resource_manager.dart`)

**Назначение:** Асинхронная загрузка всех игровых ресурсов.

**Процесс загрузки:**

1. Чтение `grits_effects.json` через `rootBundle`
2. Загрузка `grits_effects.png` в память
3. Парсинг JSON в `PlayerAnimator`
4. Инициализация аниматора

**Примечание:** Загрузка tileset'а (`grits_master.png`) закомментирована.

---

### 🔄 SpawnSystem (`lib/flame_game/systems/spawn_system.dart`)

**Назначение:** Таймерный спавн предметов.

**Логика:**

- Хранит список спавнеров и таймеры для каждого
- Обновляется каждый кадр через `update(dt, spawnItemCallback)`
- Интервал спавна берется из свойства `SpawnInterval` (по умолчанию 5 сек)

**Типы предметов (из JS кода):**

- `QuadDamage` — умножение урона
- `EnergyCanister` — восстановление энергии
- `HealthCanister` — восстановление здоровья

---

### 🏗️ EnvironmentComponent (`lib/flame_game/components/environment_component.dart`)

**Назначение:** Визуальное отображение объектов окружения.

**Типы:**

```dart
enum EnvironmentType { spawner, spawnPoint, pickup }
```

**Отрисовка:**

- Полупрозрачный прямоугольник с цветом по типу
- Белая рамка
- Иконка и подпись (например, "⚡ Quad", "🔋 Energy")

**Цвета:**

- Spawner (Quad): оранжевый
- Spawner (Energy): синий
- Spawner (Health): зеленый
- SpawnPoint Team0: синий
- SpawnPoint Team1: красный

---

## 🎨 Игровая механика (из original JS кода)

### ⚔️ Оружие (частично реализовано в Flutter)

| Слот | JS-реализация                      | Статус                    |
| ---- | ---------------------------------- | ------------------------- |
| 0    | MachineGun / ShotGun / ChainGun    | ✅ MachineGun реализовано |
| 1    | Shield / Landmine                  | ❌ Не реализовано         |
| 2    | Thrusters / Sword / RocketLauncher | ❌ Не реализовано         |

**Реализовано:**

- `WeaponBase` — абстрактный базовый класс
- `ProjectileBase` — базовый снаряд
- `MachineGun` — первое оружие с пулей
- `WeaponRegistry` — Factory для создания оружия
- 3 слота оружия в Player

**Документация:**

- `WEAPONS_REFERENCE.md` — полный справочник оружия
- `WEAPONS_USAGE_EXAMPLES.md` — примеры использования
- `MIGRATION_PLAN.md` — план переноса

### 📊 Баланс (из Constants.js)

- **Game Loop:** 10 FPS (100ms между кадрами)
- **Physics Loop:** 60 FPS (~16.67ms между кадрами)
- **Tile Size:** 64x64 пикселей

### 💔 Здоровье и энергия

- **Здоровье:** 100 HP (смерть при 0)
- **Энергия:** 100 MP (восстанавливается 20/сек)
- **Стрельба:** требует энергию (зависит от оружия)

### 🎯 Команды

- **Team 0:** Синий цвет
- **Team 1:** Оранжевый/красный цвет
- **Spawners:** Разбросаны по карте
- **Spawn Points:** 4 на команду

---

## 🏃 Архитектура оригинального JS проекта

### 📂 shared/ (общий код)

```
shared/
├── core/
│   ├── Constants.js      # Глобальные константы
│   ├── Entity.js         # Базовый класс сущности
│   ├── GameEngine.js     # Главный движок (спавн, коллизии, update)
│   ├── PhysicsEngine.js  # Box2D физика
│   ├── Player.js         # Логика игрока
│   ├── TileMap.js        # Загрузка Tiled карт
│   ├── Timer.js          # Таймер для game loop
│   ├── Util.js           # Утилиты
│   ├── Weapon.js         # Базовый класс оружия
│   └── WeaponInstance.js # Экземпляр снаряда
├── weapons/              # Реализации оружия
│   ├── BounceBallGun.js
│   ├── ChainGun.js
│   ├── Landmine.js
│   ├── MachineGun.js
│   ├── RocketLauncher.js
│   ├── Shield.js
│   ├── ShotGun.js
│   ├── Sword.js
│   └── Thrusters.js
└── items/                # Предметы
    ├── EnergyCanister.js
    ├── HealthCanister.js
    └── QuadDamage.js
```

### 📂 scripts/ (клиентский код)

```
scripts/
├── core/
│   ├── ClientGameEngine.js   # Клиентский GameEngine
│   ├── ClientPlayer.js       # Клиентский Player
│   ├── InputEngine.js        # Обработка ввода
│   ├── RenderEngine.js       # Отрисовка на Canvas
│   ├── SpriteSheet.js        # Управление спрайтами
│   └── soundManager.js       # Управление звуками
├── effects/                  # Визуальные эффекты
├── gui/                      # Интерфейс
│   ├── GuiEngine.js
│   ├── HotSpot.js
│   └── LightBox.js
└── socket.io/                # WebSocket для мультиплеера
```

---

## 🚀 Сборка и запуск

### Предварительные требования

- **Flutter SDK** ≥ 3.10.3
- **Dart SDK** ≥ 3.10.3
- **Игровые ассеты** (отсутствуют в репозитории!)

### Команды

```bash
# Установка зависимостей
flutter pub get

# Запуск в режиме отладки
flutter run

# Запуск в браузере
flutter run -d chrome

# Сборка для веб
flutter build web

# Запуск тестов
flutter test

# Анализ кода
flutter analyze

# Форматирование кода
dart format .
```

### ⚠️ Критические проблемы

| Проблема                            | Влияние                     | Решение                                          |
| ----------------------------------- | --------------------------- | ------------------------------------------------ |
| **Отсутствует `grits_effects.png`** | Анимации игрока не работают | Добавить файл в `assets/`                        |
| **Отсутствует `grits_master.png`**  | Карта не отображается       | Добавить файл в `assets/`                        |
| **Карта `map1.tmx` не найдена**     | Игра не запускается         | Проверить путь или использовать `small_map1.tmx` |

---

## 📝 Правила разработки

### Стиль кодирования

- **Форматирование:** `dart format .` (стандартный Dart формат)
- **Линтинг:** `flutter_lints` (включен через `analysis_options.yaml`)
- **Именование:** `snake_case` для файлов и переменных, `PascalCase` для классов
- **Документация:** Комментарии на русском языке, docstrings для публичных API

### Структура кода

1. **Разделение ответственности:**
   - `game/` — главный класс игры
   - `entities/` — игровые сущности (игрок, враги)
   - `components/` — переиспользуемые UI компоненты
   - `managers/` — менеджеры (ввод, ресурсы)
   - `systems/` — игровые системы (спавн, физика)
   - `models/` — модели данных

2. **Использование Flame:**
   - Наследование от `PositionComponent` для игровых объектов
   - Использование `World` для контейнеров объектов
   - `CameraComponent` для камеры с follow-логикой

3. **Асинхронность:**
   - Загрузка ассетов через `Future` в `onLoad()`
   - Использование `rootBundle` для чтения файлов

### Практики тестирования

- Тесты в директории `test/`
- Использование `flutter_test` пакета
- Команда: `flutter test`

---

## 🎯 Планы развития (Roadmap)

### 🔴 Приоритет 1 (Базовая играбельность)

- [x] Реализовать базовую стрельбу (MachineGun работает!)
- [ ] Добавить отсутствующие ассеты (grits_effects.png, grits_master.png)
- [ ] Исправить путь к карте (map1.tmx → small_map1.tmx)
- [ ] Добавить коллизии (игрок ↔ стены, снаряды ↔ объекты)

### 🟡 Приоритет 2 (Игровая механика)

- [ ] Реализовать все типы оружия из JS кода
- [ ] Добавить физику (Box2D через flame_box2d или кастомная)
- [ ] Система здоровья/энергии с балансом
- [ ] Эффекты попаданий и смерти

### 🟢 Приоритет 3 (Мультиплеер)

- [ ] WebSocket сервер (Dart/Node.js)
- [ ] Синхронизация состояния между клиентами
- [ ] Командный матчмейкинг
- [ ] Перезапуск игры после смерти

### 🔵 Приоритет 4 (Полировка)

- [ ] Главное меню и пауза
- [ ] Звуковые эффекты и фоновая музыка
- [ ] Эффекты частиц (взрывы, следы)
- [ ] UI: счетчик очков, табло результатов
- [ ] Настройки (громкость, управление)

---

## 🔗 Полезные ссылки

### Документация

- [Flame Engine Documentation](https://docs.fluttergame.org/)
- [Flame Tiled Documentation](https://pub.dev/packages/flame_tiled)
- [Tiled Map Editor](https://www.mapeditor.org/)
- [TexturePacker](https://www.codeandweb.com/texturepacker)

### Оригинальный проект

- **JS-код:** `old_code_js/` — источник логики и механик
- **Лицензия:** Apache 2.0 (Google Inc., 2012)

---

## 🐛 Известные проблемы

1. **Анимации не работают** — отсутствует спрайт-лист `grits_effects.png`
2. **Карта не загружается** — `map1.tmx` не найден, нужно использовать `small_map1.tmx`
3. **Нет стрельбы** — система оружия частично реализована (MachineGun работает)
4. **Нет физики** — коллизии работают только на уровне компонентов
5. **Нет мультиплеера** — только одиночная игра
6. **Нет звуков** — звуковые файлы есть, но не загружаются

---

## 💡 Советы для AI-ассистента

1. **При чтении кода:**
   - Сравнивай с оригинальным JS-кодом в `old_code_js/` для понимания логики
   - Обращай внимание на закомментированные блоки — там может быть полезная альтернативная реализация

2. **При добавлении фич:**
   - Сначала проверь, есть ли аналог в `old_code_js/`
   - Используй существующие паттерны (Component-based архитектура Flame)
   - Не забудь добавить ассеты в `pubspec.yaml`

3. **При исправлении багов:**
   - Проверяй пути к ассетам
   - Убеждайся, что `ResourceManager` завершил загрузку перед использованием
   - Проверяй, что `GameWorld` загружен до доступа к `player`

4. **При рефакторинге:**
   - Сохраняй разделение ответственности (game, entities, components, managers)
   - Используй `World` для контейнера игровых объектов
   - Избегай жестких зависимостей между компонентами

---

_Последнее обновление: 2025_  
_Версия документа: 1.0_
