# 🎮 Руководство по выбору оружия

## 🎯 Управление

### Переключение оружия

| Клавиша | Действие |
|---------|----------|
| **1** | Слот 0 (основное оружие) |
| **2** | Слот 1 (вторичное оружие) |
| **3** | Слот 2 (особое оружие) |
| **Numpad 1-3** | Альтернатива цифрам |

### Стрельба (будет добавлена)

| Клавиша | Действие |
|---------|----------|
| **J** | Стрельба из слота 0 |
| **K** | Стрельба из слота 1 |
| **L** | Стрельба из слота 2 |
| **ЛКМ (мышь)** | Стрельба из текущего оружия |

## 📊 Визуальный индикатор

В левом верхнем углу экрана отображается HUD с оружием:

```
┌─────────────────────────────────┐
│ [1] Machine Gun    [2] Empty [3]│
│  ████                           │
└─────────────────────────────────┘
```

**Элементы:**
- **Номер слота** (1, 2, 3)
- **Название оружия** (или "Empty")
- **Желтая рамка** - текущий выбранный слот
- **Серый цвет** - пустой слот

## 🔧 Использование в коде

### Инициализация оружия

```dart
// В GameWorld или GritsGame
import 'package:flutter_grits/flame_game/weapons/weapon_registry.dart';

void setupWeapons() {
  // Регистрация всех оружий (вызывать один раз!)
  WeaponRegistry.register();
  
  // Установка оружия в слоты
  player.setWeapon(0, WeaponRegistry.createWeapon('MachineGun'));
  player.setWeapon(1, WeaponRegistry.createWeapon('Shield'));
  player.setWeapon(2, WeaponRegistry.createWeapon('Thrusters'));
}
```

### Программное переключение

```dart
// Переключение на конкретный слот
player.selectWeapon(0); // Слот 1
player.selectWeapon(1); // Слот 2
player.selectWeapon(2); // Слот 3

// Получение текущего оружия
final currentWeapon = player.selectedWeapon;
final currentSlot = player.selectedWeaponSlot;
```

### Проверка оружия

```dart
// Проверка, есть ли оружие в слоте
if (player.getWeapon(0) != null) {
  debugPrint('В слоте 0 есть оружие: ${player.getWeapon(0)!.displayName}');
}

// Получение информации об оружии
final weapon = player.selectedWeapon;
if (weapon != null) {
  debugPrint('Оружие: ${weapon.displayName}');
  debugPrint('Energy cost: ${weapon.energyCost}');
  debugPrint('Damage: ${weapon.damage}');
}
```

## 🎨 Пример: Полная настройка

```dart
// lib/flame_game/game/world/game_world.dart
import 'package:flutter_grits/flame_game/weapons/weapon_registry.dart';

class GameWorld extends World {
  late Player player;
  
  @override
  Future<void> onLoad() async {
    await _loadMap();
    await _createPlayer();
    
    // Установка оружия
    _setupPlayerWeapons();
  }
  
  void _setupPlayerWeapons() {
    // Регистрация оружий
    WeaponRegistry.register();
    
    // Настройка оружия для игрока
    player.setWeapon(0, WeaponRegistry.createWeapon('MachineGun'));
    
    // Остальные слоты можно добавить позже
    // player.setWeapon(1, WeaponRegistry.createWeapon('Shield'));
    // player.setWeapon(2, WeaponRegistry.createWeapon('Thrusters'));
  }
}
```

## 🎯 Готовые конфигурации

### Конфигурация 1: Агрессивная
```dart
player.setWeapon(0, WeaponRegistry.createWeapon('MachineGun'));
player.setWeapon(1, WeaponRegistry.createWeapon('ShotGun'));
player.setWeapon(2, WeaponRegistry.createWeapon('ChainGun'));
```

### Конфигурация 2: Баланс
```dart
player.setWeapon(0, WeaponRegistry.createWeapon('MachineGun'));
player.setWeapon(1, WeaponRegistry.createWeapon('Shield'));
player.setWeapon(2, WeaponRegistry.createWeapon('Thrusters'));
```

### Конфигурация 3: Тяжелая
```dart
player.setWeapon(0, WeaponRegistry.createWeapon('RocketLauncher'));
player.setWeapon(1, WeaponRegistry.createWeapon('Landmine'));
player.setWeapon(2, WeaponRegistry.createWeapon('Sword'));
```

## 🐛 Отладка

### Вывод текущей конфигурации

```dart
void debugPrintWeapons() {
  debugPrint('=== Weapon Configuration ===');
  debugPrint('Selected slot: ${player.selectedWeaponSlot + 1}');
  
  for (int i = 0; i < 3; i++) {
    final weapon = player.getWeapon(i);
    if (weapon != null) {
      debugPrint('Slot ${i + 1}: ${weapon.displayName} '
          '(Energy: ${weapon.energyCost}, '
          'Damage: ${weapon.damage})');
    } else {
      debugPrint('Slot ${i + 1}: Empty');
    }
  }
}
```

### Проверка переключения

```dart
// Добавить в GritsGame.update()
void update(double dt) {
  super.update(dt);
  
  // Отладка переключения
  final slot = inputManager.getWeaponSlotKeyPress();
  if (slot != null) {
    debugPrint('Weapon switch detected: Slot ${slot + 1}');
  }
}
```

## ⚙️ Настройка клавиш

Для изменения клавиш редактируй `InputManager.getWeaponSlotKeyPress()`:

```dart
int? getWeaponSlotKeyPress() {
  final justPressed = getJustPressedKeys();
  
  // Пример: Q, W, E вместо 1, 2, 3
  if (justPressed.contains(LogicalKeyboardKey.keyQ)) {
    return 0;
  } else if (justPressed.contains(LogicalKeyboardKey.keyW)) {
    return 1;
  } else if (justPressed.contains(LogicalKeyboardKey.keyE)) {
    return 2;
  }
  
  return null;
}
```

## 📝 TODO

- [ ] Добавить колесо мыши для переключения
- [ ] Авто-переключение на ближайшее оружие
- [ ] Анимация смены оружия
- [ ] Звук переключения
- [ ] Визуальный эффект при переключении

---

*Гид создан: 2025*
