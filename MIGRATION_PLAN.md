# 🚀 План миграции JS → Dart/Flame (Grits Game)

> Документ содержит пошаговый план переноса игровых механик из оригинального JS-кода в Flutter/Flame проект.

---

## 📋 Сводка проекта

| Аспект | JS (Оригинал) | Dart/Flame (Цель) |
|--------|---------------|-------------------|
| **Движок** | Canvas API + Box2D | Flame Engine |
| **Физика** | Box2D (через PhysicsEngine) | flame_box2d или кастомная AABB |
| **Сеть** | Socket.io (WebSocket) | web_socket_channel / Flutter Multiplayer |
| **FPS Game** | 10 FPS | `update(dt)` Flame (60+ FPS) |
| **FPS Physics** | 60 FPS | `update(dt)` Flame (синхронизировано) |
| **Карты** | Tiled JSON + Canvas | flame_tiled (TiledComponent) |
| **Анимации** | TexturePacker + SpriteSheet | TexturePacker + PlayerAnimator |

---

## 🗺️ Общая стратегия миграции

### Фазы разработки

```
┌─────────────────────────────────────────────────────────────────┐
│  ФАЗА 1: Базовая играбельность (4-6 недель)                     │
│  ✅ Анимации игрока + движение                                   │
│  ⬜ Оружие #1 (MachineGun)                                       │
│  ⬜ Коллизии (AABB)                                              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ФАЗА 2: Игровая механика (4-6 недель)                          │
│  ⬜ Все виды оружия (8 типов)                                    │
│  ⬜ Предметы (Energy, Health, QuadDamage)                        │
│  ⬜ Физика (Box2D через flame_box2d)                             │
│  ⬜ Эффекты (взрывы, частицы)                                    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ФАЗА 3: Мультиплеер (6-8 недель)                               │
│  ⬜ WebSocket сервер (Dart/Node.js)                              │
│  ⬜ Синхронизация состояния                                      │
│  ⬜ Командный матчмейкинг                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  ФАЗА 4: Полировка (2-4 недели)                                 │
│  ⬜ Звуки и музыка                                               │
│  ⬜ Главное меню и пауза                                         │
│  ⬜ UI (счетчик очков, табло)                                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔨 Детальный план по компонентам

### 1️⃣ СИСТЕМА ОРУЖИЯ (Weapon System)

#### Архитектура JS (из `shared/core/Weapon.js`)

```javascript
WeaponClass = Class.extend({
  itemID: "0",
  firing: false,
  energyCost: 1,
  fireDelayInSeconds: 0.01,
  
  onInit(owningPlayer) {},       // Инициализация
  onUpdate(owningPlayer) {},     // Обновление каждый кадр
  onFire(owningPlayer) {},       // Выстрел
  onDraw(owningPlayer) {}        // Отрисовка
});
```

#### Целевая архитектура Dart

**Расположение:** `lib/flame_game/weapons/`

```
lib/flame_game/weapons/
├── weapon_base.dart            # Абстрактный базовый класс
├── machine_gun.dart            # Оружие #1: MachineGun
├── shot_gun.dart               # Оружие #2: ShotGun
├── chain_gun.dart              # Оружие #3: ChainGun
├── rocket_launcher.dart        # Оружие #4: RocketLauncher
├── grenade_launcher.dart       # Оружие #5: BounceBallGun
├── shield.dart                 # Оружие #6: Shield (дефенсив)
├── landmine.dart               # Оружие #7: Landmine
├── sword.dart                  # Оружие #8: Sword
├── thrusters.dart              # Оружие #9: Thrusters
└── weapon_registry.dart        # Factory для создания оружия
```

#### 📝 Реализация: WeaponBase

```dart
// lib/flame_game/weapons/weapon_base.dart
abstract class WeaponBase {
  String get itemID;
  String get displayName;
  double get energyCost;
  double get fireDelayInSeconds;
  
  bool firing = false;
  double nextFireTime = 0;
  
  void onInit(Player player);
  void onUpdate(Player player, double dt);
  void onFire(Player player);
  void onDraw(Canvas canvas, Player player);
  
  bool canFire(Player player) {
    return player.energy >= energyCost &&
           DateTime.now().millisecondsSinceEpoch / 1000 >= nextFireTime;
  }
  
  void consumeEnergy(Player player) {
    player.useEnergy(energyCost);
  }
}
```

#### 📝 Реализация: MachineGun (пример)

```dart
// lib/flame_game/weapons/machine_gun.dart
class MachineGun extends WeaponBase {
  @override String get itemID => "1234";
  @override String get displayName => "Machine Gun";
  @override double get energyCost => 2;
  @override double get fireDelayInSeconds => 0.1;
  
  @override
  void onFire(Player player) {
    if (!canFire(player)) return;
    
    consumeEnergy(player);
    firing = true;
    nextFireTime = DateTime.now().millisecondsSinceEpoch / 1000 + fireDelayInSeconds;
    
    // Создаем снаряд
    final bullet = Bullet(
      position: player.position + _getBulletSpawnOffset(player),
      direction: _getFireDirection(player),
      owner: player,
      damage: 5,
      speed: 700,
      lifetime: 2.0,
      projectileType: ProjectileType.machineGun,
    );
    
    // Добавляем снаряд в мир
    player.addToWorld(bullet);
    
    // Воспроизводим звук
    // SoundManager.play('machine_shoot0.ogg');
  }
  
  Vector2 _getFireDirection(Player player) {
    return Vector2(
      cos(player.faceAngleRadians),
      sin(player.faceAngleRadians),
    );
  }
  
  Vector2 _getBulletSpawnOffset(Player player) {
    final dir = _getFireDirection(player);
    return player.position + dir * 20; // Смещение на 20px вперед
  }
}
```

---

### 2️⃣ СИСТЕМА СНАРЯДОВ (Projectile System)

#### Архитектура JS (из `shared/weaponinstances/SimpleProjectile.js`)

```javascript
SimpleProjectileClass = WeaponInstanceClass.extend({
  lifetime: 0,
  physBody: null,
  _speed: 800,
  _dmgAmt: 10,
  
  init(x, y, settings) {
    // Создаем physics body
    this.physBody = gPhysicsEngine.addBody(entityDef);
    this.physBody.SetLinearVelocity(dir * speed);
  },
  
  update() {
    this.lifetime -= 0.05;
    if (this.lifetime <= 0) this.kill();
  },
  
  onTouch(otherBody, point, impulse) {
    // Создаем эффект удара
    // Наносим урон игроку
    this.markForDeath = true;
  }
});
```

#### Целевая архитектура Dart

**Расположение:** `lib/flame_game/projectiles/`

```
lib/flame_game/projectiles/
├── projectile_base.dart          # Абстрактный базовый класс
├── bullet.dart                   # Базовый снаряд (MachineGun)
├── shotgun_pellet.dart           # Дробь (ShotGun)
├── rocket.dart                   # Ракета (RocketLauncher)
├── grenade.dart                  # Граната (BounceBallGun)
├── effect/
│   ├── impact_effect.dart        # Эффект удара
│   └── explosion_effect.dart     # Эффект взрыва
└── projectile_registry.dart      # Factory
```

#### 📝 Реализация: ProjectileBase

```dart
// lib/flame_game/projectiles/projectile_base.dart
abstract class ProjectileBase extends PositionComponent {
  final Player owner;
  final Vector2 direction;
  final double damage;
  final double speed;
  double lifetime;
  final double maxLifetime;
  
  ProjectileBase({
    required this.position,
    required this.owner,
    required this.direction,
    required this.damage,
    required this.speed,
    required this.lifetime,
  }) : maxLifetime = lifetime {
    // Размер снаряда
    size = Vector2(8, 8);
    anchor = Anchor.center;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Движение
    position += direction.normalized() * speed * dt;
    
    // Уменьшение времени жизни
    lifetime -= dt;
    if (lifetime <= 0) {
      destroy();
    }
  }
  
  void onCollision(Vector2 collisionPoint, PositionComponent other) {
    // Базовая реализация
  }
  
  void destroy() {
    removeFromParent();
  }
}
```

---

### 3️⃣ СИСТЕМА ПРЕДМЕТОВ (Item System)

#### Архитектура JS

| Предмет | Файл | Эффект |
|---------|------|--------|
| **EnergyCanister** | `shared/items/EnergyCanister.js` | +10 энергии |
| **HealthCanister** | `shared/items/HealthCanister.js` | +25 здоровья |
| **QuadDamage** | `shared/items/QuadDamage.js` | 4x урон (15 сек) |

#### Целевая архитектура Dart

**Расположение:** `lib/flame_game/items/`

```
lib/flame_game/items/
├── item_base.dart                # Абстрактный базовый класс
├── energy_canister.dart          # +10 энергии
├── health_canister.dart          # +25 здоровья
├── quad_damage.dart              # 4x урон (15 сек)
└── item_spawner.dart             # Спавн предметов
```

#### 📝 Реализация: ItemBase

```dart
// lib/flame_game/items/item_base.dart
abstract class ItemBase extends PositionComponent {
  final String itemName;
  final String spriteName;
  
  ItemBase({
    required this.position,
    required this.itemName,
    required this.spriteName,
  }) {
    size = Vector2(46, 46);
    anchor = Anchor.center;
  }
  
  void onPickup(Player player);
  
  @override
  void render(Canvas canvas) {
    // Отрисовка предмета с анимацией
  }
}

// lib/flame_game/items/energy_canister.dart
class EnergyCanister extends ItemBase {
  EnergyCanister({required super.position})
    : super(
        itemName: 'EnergyCanister',
        spriteName: 'energy_canister_blue',
      );
  
  @override
  void onPickup(Player player) {
    player.energy = (player.energy + 10).clamp(0, player.maxEnergy);
    // SoundManager.play('energy_pickup.ogg');
  }
}
```

---

### 4️⃣ СИСТЕМА СПАВНА (Spawner System)

#### Архитектура JS (из `shared/environment/Spawner.js`)

```javascript
SpawnerClass = EntityClass.extend({
  timeUntilSpawn: 0,
  lastSpawned: null,
  spawnItem: null,
  nextSpawnTime: 0,
  
  update() {
    if (this.lastSpawned == null) {
      if (this.nextSpawnTime > gGameEngine.getTime()) return;
      
      // Создаем предмет на спавнере
      var ent = gGameEngine.spawnEntity(this.spawnItem, this.pos.x, this.pos.y);
      this.lastSpawned = ent;
    } else {
      if (this.lastSpawned._killed == true) {
        this.nextSpawnTime = gGameEngine.getTime() + 20;
        this.lastSpawned = null;
      }
    }
  }
});
```

#### Текущее состояние Dart

✅ **Частично реализовано:** `lib/flame_game/systems/spawn_system.dart`

#### Улучшенная реализация

```dart
// lib/flame_game/systems/spawn_system.dart
class SpawnSystem {
  final List<Spawner> spawners = [];
  final Map<Spawner, double> spawnTimers = {};
  
  void registerSpawner(Spawner spawner) {
    spawners.add(spawner);
    spawnTimers[spawner] = 0.0;
  }
  
  void update(double dt, Function(Vector2, ItemType) spawnCallback) {
    for (final spawner in spawners) {
      final timer = spawnTimers[spawner]!;
      final newTimer = timer + dt;
      
      final spawnInterval = spawner.properties['SpawnInterval'] ?? 5.0;
      
      if (newTimer >= spawnInterval) {
        final itemType = _stringToItemType(
          spawner.properties['SpawnItem'] ?? 'Unknown'
        );
        spawnCallback(spawner.position, itemType);
        spawnTimers[spawner] = 0.0;
      } else {
        spawnTimers[spawner] = newTimer;
      }
    }
  }
  
  ItemType _stringToItemType(String name) {
    switch (name) {
      case 'QuadDamage': return ItemType.quadDamage;
      case 'EnergyCanister': return ItemType.energy;
      case 'HealthCanister': return ItemType.health;
      default: return ItemType.unknown;
    }
  }
}
```

---

### 5️⃣ ФИЗИКА (Physics System)

#### Архитектура JS (из `shared/core/PhysicsEngine.js`)

```javascript
// Box2D физика
gPhysicsEngine.create(60, false);  // 60 FPS, sleep disabled

// Создание тела
var entityDef = {
  id: "Player",
  x: posX,
  y: posY,
  halfHeight: 26 / 2,
  halfWidth: 26 / 2,
  categories: ['player', 'team0'],
  collidesWith: ['all'],
  userData: {"id": "player", "ent": this}
};
this.physBody = gPhysicsEngine.addBody(entityDef);
```

#### Варианты реализации в Dart

**Вариант A: flame_box2d (рекомендуется)**

```yaml
# pubspec.yaml
dependencies:
  flame_box2d: ^2.0.0
```

```dart
// lib/flame_game/physics/physics_world.dart
import 'package:flame_box2d/flame_box2d.dart';

class GritsPhysicsWorld extends PhysicsWorld {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Настройка гравитации (отсутствует для топ-даун)
    gravity = Vector2.zero();
  }
  
  void addPlayer(Player player) {
    final bodyDef = BodyDef(
      position: player.position,
      type: BodyType.dynamic,
      userData: {'ent': player},
    );
    
    final body = world.createBody(bodyDef);
    
    final shape = CircleShape(radius: 26 / 2);
    final fixtureDef = FixtureDef(shape);
    body.createFixture(fixtureDef);
    
    player.setPhysicsBody(body);
  }
}
```

**Вариант B: Кастомная AABB физика (проще для топ-даун)**

```dart
// lib/flame_game/physics/aabb_physics.dart
class AABBCollision {
  static bool check(PositionComponent a, PositionComponent b) {
    return a.overlaps(b);
  }
  
  static Vector2 resolveCollision(
    PositionComponent a, 
    PositionComponent b, 
    Vector2 velocity
  ) {
    // Простая реакция на коллизию
    return Vector2.zero();
  }
}
```

---

### 6️⃣ СЕТЬ (Network System)

#### Архитектура JS (Socket.io)

```javascript
// Клиент
socket.emit('input', {
  x: inputX,
  y: inputY,
  fire0: fire0,
  faceAngle0to7: faceAngle
});

socket.on('status', (msg) => {
  player.energy = msg.energy;
  player.health = msg.health;
});
```

#### Целевая архитектура Dart

**Расположение:** `lib/networking/`

```
lib/networking/
├── network_client.dart           # Клиент (WebSocket)
├── network_server.dart           # Сервер (Dart)
├── messages/
│   ├── client_input.dart         # Ввод клиента
│   ├── server_state.dart         # Состояние сервера
│   └── match_events.dart         # События матча
└── network_manager.dart          # Единый менеджер
```

#### 📝 Пример: NetworkClient

```dart
// lib/networking/network_client.dart
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkClient {
  WebSocketChannel? _channel;
  final String serverUrl;
  
  NetworkClient(this.serverUrl);
  
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    await _channel!.stream.first;
  }
  
  void sendInput(PlayerInput input) {
    _channel!.sink.add(jsonEncode({
      'type': 'input',
      'x': input.x,
      'y': input.y,
      'fire0': input.fire0,
      'faceAngle': input.faceAngle,
    }));
  }
  
  Stream<ServerState> get stateStream => 
    _channel!.stream.map((data) => ServerState.fromJson(jsonDecode(data)));
}
```

---

## 📊 Приоритеты и зависимости

### Блок-схема зависимостей

```
┌─────────────────────────────────────────────────────────────┐
│                    БАЗОВЫЕ КОМПОНЕНТЫ                       │
├─────────────────────────────────────────────────────────────┤
│  ✅ ResourceManager (загрузка ассетов)                      │
│  ✅ PlayerAnimator (анимации)                               │
│  ✅ InputManager (ввод)                                     │
│  ✅ GameWorld (мир, карта)                                  │
│  ✅ Player (движение, анимация)                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    ПЕРВАЯ ОРУЖЕЙНАЯ ЦЕЛЬ                    │
├─────────────────────────────────────────────────────────────┤
│  ⬜ WeaponBase (абстракция)                                 │
│  ⬜ MachineGun (первое оружие)                              │
│  ⬜ Bullet (простой снаряд)                                 │
│  ⬜ AABB коллизии (базовые)                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    ПОЛНОЕ ОРУЖИЕ                            │
├─────────────────────────────────────────────────────────────┤
│  ⬜ ShotGun (дробь)                                         │
│  ⬜ ChainGun (скорострел)                                   │
│  ⬜ RocketLauncher (ракет)                                  │
│  ⬜ GrenadeLauncher (граната)                               │
│  ⬜ ImpactEffect (эффекты)                                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    ПРЕДМЕТЫ И СПАВНЕРЫ                      │
├─────────────────────────────────────────────────────────────┤
│  ⬜ EnergyCanister                                          │
│  ⬜ HealthCanister                                          │
│  ⬜ QuadDamage                                              │
│  ⬜ ItemSpawner (улучшенный)                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    ФИЗИКА (опционально)                     │
├─────────────────────────────────────────────────────────────┤
│  ⬜ flame_box2d интеграция                                  │
│  ⬜ или кастомная AABB физика                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    МУЛЬТИПЛЕЕР                              │
├─────────────────────────────────────────────────────────────┤
│  ⬜ WebSocket сервер                                        │
│  ⬜ Синхронизация состояний                                 │
│  ⬜ Команды и матчмейкинг                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Технические детали

### Константы из Constants.js

```dart
// lib/flame_game/core/constants.dart
class GritsConstants {
  // Игровой цикл
  static const double gameUpdatesPerSec = 10;
  static const double gameLoopHz = 1.0 / 10.0;
  
  // Физика
  static const double physicsUpdatesPerSec = 60;
  static const double physicsLoopHz = 1.0 / 60.0;
  
  // Карта
  static const double tileSize = 64;
  static const int mapWidthTiles = 100;
  static const int mapHeightTiles = 100;
  static const int mapWidthPx = mapWidthTiles * tileSize; // 6400
  static const int mapHeightPx = mapHeightTiles * tileSize; // 6400
  
  // Игрок
  static const double playerHealth = 100;
  static const double playerEnergy = 100;
  static const double energyRegenRate = 20; // в секунду
  static const double playerSpeed = 260; // 26 * 5 из JS
  
  // Звуки
  static const List<String> soundFiles = [
    'bounce0.ogg',
    'explode0.ogg',
    'energy_pickup.ogg',
    'machine_shoot0.ogg',
    'rocket_shoot0.ogg',
    'shotgun_shoot0.ogg',
    'quad_pickup.ogg',
  ];
}
```

### Factory Pattern для оружия

```dart
// lib/flame_game/weapons/weapon_registry.dart
class WeaponRegistry {
  static final Map<String, WeaponBase Function()> _weapons = {};
  
  static void register() {
    _weapons['MachineGun'] = () => MachineGun();
    _weapons['ShotGun'] = () => ShotGun();
    _weapons['ChainGun'] = () => ChainGun();
    _weapons['RocketLauncher'] = () => RocketLauncher();
    _weapons['BounceBallGun'] = () => GrenadeLauncher();
    _weapons['Shield'] = () => Shield();
    _weapons['Landmine'] = () => Landmine();
    _weapons['Sword'] = () => Sword();
  }
  
  static WeaponBase createWeapon(String name) {
    final factory = _weapons[name];
    if (factory == null) {
      throw Exception('Unknown weapon: $name');
    }
    return factory();
  }
}
```

---

## 📁 Структура папок для новых файлов

```
lib/flame_game/
├── weapons/                      # НОВАЯ ДИРЕКТОРИЯ
│   ├── weapon_base.dart
│   ├── machine_gun.dart
│   ├── shot_gun.dart
│   ├── chain_gun.dart
│   ├── rocket_launcher.dart
│   ├── grenade_launcher.dart
│   ├── shield.dart
│   ├── landmine.dart
│   ├── sword.dart
│   ├── thrusters.dart
│   └── weapon_registry.dart
│
├── projectiles/                  # НОВАЯ ДИРЕКТОРИЯ
│   ├── projectile_base.dart
│   ├── bullet.dart
│   ├── shotgun_pellet.dart
│   ├── rocket.dart
│   ├── grenade.dart
│   └── effect/
│       ├── impact_effect.dart
│       └── explosion_effect.dart
│
├── items/                        # НОВАЯ ДИРЕКТОРИЯ
│   ├── item_base.dart
│   ├── energy_canister.dart
│   ├── health_canister.dart
│   ├── quad_damage.dart
│   └── item_spawner.dart
│
├── physics/                      # НОВАЯ ДИРЕКТОРИЯ (опционально)
│   ├── physics_world.dart
│   ├── aabb_physics.dart
│   └── collision_handler.dart
│
└── core/                         # НОВАЯ ДИРЕКТОРИЯ
    ├── constants.dart
    └── sound_manager.dart
```

---

## 📝 Список задач (Checklist)

### Фаза 1: Базовая играбельность

- [ ] Создать `WeaponBase.dart` (абстрактный класс)
- [ ] Реализовать `MachineGun.dart` (первое оружие)
- [ ] Создать `ProjectileBase.dart` (базовый снаряд)
- [ ] Реализовать `Bullet.dart` (простой снаряд)
- [ ] Добавить базовую систему коллизий (AABB)
- [ ] Интегрировать оружие в Player (3 слота)
- [ ] Добавить эффекты выстрела (мuzzle flash)

### Фаза 2: Полная механика

- [ ] Реализовать `ShotGun.dart` (5 пуль с разбросом)
- [ ] Реализовать `ChainGun.dart` (высокий fireRate)
- [ ] Реализовать `RocketLauncher.dart` (взрыв при попадании)
- [ ] Реализовать `GrenadeLauncher.dart` (прыгающая граната)
- [ ] Добавить `ImpactEffect.dart` (визуал удара)
- [ ] Реализовать `Shield.dart` (блок урона)
- [ ] Реализовать `Landmine.dart` (мина на земле)
- [ ] Реализовать `Sword.dart` (ближний бой)

### Фаза 3: Предметы

- [ ] Реализовать `EnergyCanister.dart` (+10 энергии)
- [ ] Реализовать `HealthCanister.dart` (+25 здоровья)
- [ ] Реализовать `QuadDamage.dart` (4x урон 15 сек)
- [ ] Обновить `SpawnSystem.dart` для предметов
- [ ] Добавить анимации предметов

### Фаза 4: Физика

- [ ] Решить: flame_box2d или кастомная AABB
- [ ] Интеграция Box2D (если выбрано)
- [ ] Коллизии снарядов со стенами
- [ ] Коллизии снарядов с игроками
- [ ] Физика предметов

### Фаза 5: Мультиплеер

- [ ] Настроить WebSocket сервер (Dart/Node.js)
- [ ] Реализовать `NetworkClient.dart`
- [ ] Синхронизация позиции игрока
- [ ] Синхронизация выстрелов
- [ ] Командный матчмейкинг

---

## 🔗 Ссылки на оригинальный JS-код

| Компонент | JS файл | Статус |
|-----------|---------|--------|
| **WeaponBase** | `shared/core/Weapon.js` | 📄 Проанализировано |
| **MachineGun** | `shared/weapons/MachineGun.js` | 📄 Проанализировано |
| **ShotGun** | `shared/weapons/ShotGun.js` | 📄 Проанализировано |
| **SimpleProjectile** | `shared/weaponinstances/SimpleProjectile.js` | 📄 Проанализировано |
| **EnergyCanister** | `shared/items/EnergyCanister.js` | 📄 Проанализировано |
| **Spawner** | `shared/environment/Spawner.js` | 📄 Проанализировано |
| **SpawnPoint** | `shared/environment/SpawnPoint.js` | 📄 Проанализировано |
| **Weapons Config** | `shared/weapons/Weapons.json` | 📄 Проанализировано |
| **Factory** | `shared/core/Factory.js` | 📄 Проанализировано |
| **PhysicsEngine** | `shared/core/PhysicsEngine.js` | 📄 Проанализировано |
| **RenderEngine** | `scripts/core/RenderEngine.js` | 📄 Проанализировано |

---

## 💡 Рекомендации для AI-ассистента

1. **При создании оружия:**
   - Используй паттерн наследования от `WeaponBase`
   - Ссылайся на JS-реализацию для баланса (energyCost, fireDelay, damage)
   - Не забудь добавить звук выстрела

2. **При создании снарядов:**
   - Используй паттерн наследования от `ProjectileBase`
   - Реализуй `onCollision()` для обработки ударов
   - Добавляй визуальные эффекты (ImpactEffect)

3. **При добавлении предметов:**
   - Следуй архитектуре `ItemBase`
   - Регистрируй спавнеры в `SpawnSystem`
   - Добавляй анимацию (TexturePacker JSON)

4. **При работе с физикой:**
   - Для топ-даун игры AABB проще и достаточен
   - Box2D нужен только для сложных взаимодействий (гранаты, взрывы)

---

*План создан: 2025*  
*Версия: 1.0*
