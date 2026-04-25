# 📖 Примеры использования системы оружия

## 🎮 Базовый пример

### Инициализация оружия

```dart
// lib/flame_game/game/world/game_world.dart
import 'package:flutter_grits/flame_game/weapons/weapon_registry.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

class GameWorld extends World {
  late Player player;
  
  @override
  Future<void> onLoad() async {
    // Регистрация всех оружий (вызывать один раз!)
    WeaponRegistry.register();
    
    // Создание игрока
    player = Player(position: startPosition, resourceManager: resourceManager);
    await add(player);
    
    // Установка оружия в слоты
    _setupPlayerWeapons();
  }
  
  void _setupPlayerWeapons() {
    // Слот 0: Основное оружие (MachineGun)
    player.setWeapon(0, WeaponRegistry.createWeapon('MachineGun'));
    
    // Слот 1: Вторичное оружие (будет добавлено позже)
    // player.setWeapon(1, WeaponRegistry.createWeapon('Shield'));
    
    // Слот 2: Особое оружие (будет добавлено позже)
    // player.setWeapon(2, WeaponRegistry.createWeapon('Thrusters'));
  }
}
```

### Обработка ввода для стрельбы

```dart
// lib/flame_game/managers/input_manager.dart
import 'package:flutter/services.dart';

class InputManager {
  // ... существующий код ...
  
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // Начало стрельбы из оружий
      if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        // Стрельба из слота 0 (основное оружие)
        GritsGame.instance?.player.startFiring(0);
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        // Стрельба из слота 1 (вторичное оружие)
        GritsGame.instance?.player.startFiring(1);
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        // Стрельба из слота 2 (особое оружие)
        GritsGame.instance?.player.startFiring(2);
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      
      // Окончание стрельбы
      if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        GritsGame.instance?.player.stopFiring(0);
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        GritsGame.instance?.player.stopFiring(1);
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        GritsGame.instance?.player.stopFiring(2);
      }
    }
  }
}
```

## 🔨 Создание нового оружия

### Пример: ShotGun (Дробовик)

```dart
// lib/flame_game/weapons/shot_gun.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

class ShotGun extends WeaponBase {
  @override
  String get itemID => "8234";

  @override
  String get displayName => "ShotGun";

  @override
  double get energyCost => 4;

  @override
  double get fireDelayInSeconds => 0.25;

  @override
  double get damage => 10;

  @override
  void onFire(Player player) {
    const numBullets = 5;
    const spread = 2.0 / numBullets;  // Разброс ±1 радиан
    
    for (int i = 0; i < numBullets; i++) {
      // Вычисляем угол с разбросом
      final offset = (spread * (i + 1)) - 1;  // От -1 до +1 радиан
      
      final baseDirection = getFireDirection(player);
      final direction = _rotateVector(baseDirection, offset);
      
      final spawnPos = getBulletSpawnOffset(player, 20);
      
      final bullet = Bullet(
        position: spawnPos,
        owner: player,
        direction: direction,
        damage: damage,
        speed: 700,
        lifetime: 2.0,
      );
      
      addProjectileToWorld(bullet);
    }
    
    // TODO: Звук выстрела
    // SoundManager.play('shotgun_shoot0.ogg');
  }
  
  // Вспомогательный метод для вращения вектора
  Vector2 _rotateVector(Vector2 v, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Vector2(
      v.x * cosA - v.y * sinA,
      v.x * sinA + v.y * cosA,
    );
  }
}
```

### Регистрация нового оружия

```dart
// lib/flame_game/weapons/weapon_registry.dart
static void register() {
  _weapons['MachineGun'] = () => MachineGun();
  _weapons['ShotGun'] = () => ShotGun();  // <-- Добавлено
  
  // ... остальные оружия
}
```

## 🎯 Использование снарядов

### Базовый снаряд (Bullet)

```dart
// В любом месте, где нужно создать пулю
final bullet = Bullet(
  position: Vector2(100, 200),
  owner: player,
  direction: Vector2(1, 0),  // Вправо
  damage: 5,
  speed: 700,
  lifetime: 2.0,
);

// Добавить в игровой мир
player.addToWorld(bullet);
```

### Создание кастомного снаряда

```dart
// lib/flame_game/projectiles/rocket.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

class Rocket extends ProjectileBase {
  Rocket({
    required super.position,
    required super.owner,
    required super.direction,
  }) : super(
    damage: 25,  // Высокий урон
    speed: 900,  // Быстрая
    lifetime: 3.0,
    spriteName: 'rocket_launcher_projectile_00',
  );

  @override
  void onCollision(Vector2 collisionPoint, PositionComponent other) {
    if (!isTarget(other)) return;
    
    // Нанести урон
    if (other is Player) {
      other.takeDamage(damage);
    }
    
    // TODO: Создать эффект взрыва
    // final explosion = ExplosionEffect(position: collisionPoint);
    // addToWorld(explosion);
    
    // TODO: Звук взрыва
    // SoundManager.play('explode0.ogg');
    
    destroy();
  }
}
```

## 🎨 Расширение WeaponBase

### Пример: Shield (Защитный щит)

```dart
// lib/flame_game/weapons/shield.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

class Shield extends WeaponBase {
  ShieldInstance? _shieldInstance;

  @override
  String get itemID => "4188";

  @override
  String get displayName => "Shield";

  @override
  double get energyCost => 2;  // В секунду при удержании

  @override
  double get fireDelayInSeconds => 0.5;

  @override
  void onFire(Player player) {
    if (_shieldInstance != null) return;
    
    // Создать щит перед игроком
    _shieldInstance = ShieldInstance(
      position: player.position,
      owner: player,
    );
    
    addProjectileToWorld(_shieldInstance!);
  }

  @override
  void onUpdate(Player player, double dt) {
    // Проверка, отпущена ли кнопка или кончилась энергия
    if (!player.isFiringWeapon1 || player.energy <= 0) {
      _shieldInstance?.destroy();
      _shieldInstance = null;
    } else {
      // Тратить энергию пока держишь щит
      player.useEnergy(energyCost * dt);
    }
  }
}

/// Экземпляр щита
class ShieldInstance extends PositionComponent {
  final Player owner;
  
  ShieldInstance({
    required this.position,
    required this.owner,
  }) {
    size = Vector2(60, 60);
    anchor = Anchor.center;
  }
  
  void destroy() {
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    // Отрисовка щита
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.blue.withOpacity(0.5),
    );
  }
}
```

## 📊 Баланс оружий

| Оружие | Energy Cost | Fire Delay | Damage | DPS* | Описание |
|--------|-------------|------------|--------|------|----------|
| MachineGun | 2 | 0.1s | 5 | 50 | Стандартное |
| ShotGun | 4 | 0.25s | 10×5 | 200 | Мощное на короткой дистанции |
| ChainGun | 1 | 0.05s | 5 | 100 | Скорострельное |
| RocketLauncher | 10 | 0.5s | 25 | 50 | Взрывной урон |
| GrenadeLauncher | 8 | 0.5s | 15 | 30 | Прыгающая граната |

*DPS = Damage per Second при постоянном нажатии

## 🎮 Горячие клавиши (рекомендуемые)

| Клавиша | Действие |
|---------|----------|
| **J** | Стрельба из слота 0 (основное) |
| **K** | Стрельба из слота 1 (вторичное) |
| **L** | Стрельба из слота 2 (особое) |
| **1-3** | Смена оружия |

## 🔧 Отладка

### Вывод информации об оружии

```dart
// В Player.dart
void debugPrintWeapons() {
  for (int i = 0; i < _weapons.length; i++) {
    final weapon = _weapons[i];
    if (weapon != null) {
      debugPrint('Slot $i: ${weapon.displayName} '
          '(Energy: ${weapon.energyCost}, '
          'Delay: ${weapon.fireDelayInSeconds}s)');
    } else {
      debugPrint('Slot $i: Empty');
    }
  }
}
```

## 📝 TODO для полной реализации

- [ ] Добавить `SoundManager` для воспроизведения звуков
- [ ] Создать `ImpactEffect` для визуальных эффектов ударов
- [ ] Добавить анимации оружия на игрока (`onDraw`)
- [ ] Реализовать все 9 видов оружия
- [ ] Добавить UI для отображения текущего оружия
- [ ] Сбалансировать урон и расход энергии

---

*Примеры созданы: 2025*
