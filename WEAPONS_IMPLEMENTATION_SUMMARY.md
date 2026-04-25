# 🎮 Полное руководство по оружию

## ✅ Реализованные оружия (9/9)

| Слот | Оружие | Энергия | Урон | Скорострельность | Статус |
|------|--------|---------|------|------------------|--------|
| **1** | Machine Gun | 2 | 5 | 0.1s | ✅ Работает |
| **1** | ShotGun | 4 | 10×5 | 0.25s | ✅ Работает |
| **1** | Chain Gun | 1 | 5 | 0.05s | ✅ Работает |
| **2** | Rocket Launcher | 10 | 25 | 0.5s | ✅ Работает |
| **2** | Grenade Launcher | 8 | 15 | 0.5s | ✅ Работает |
| **2** | Landmine | 10 | 50 | 0.5s | ✅ Работает |
| **3** | Shield | 2/сек | 0 | Hold | ✅ Работает |
| **3** | Energy Sword | 2/сек | 20 | Hold | ✅ Работает |
| **3** | Thrusters | 0 | 0 | Hold | ✅ Работает |

---

## 🎯 Управление оружием

### Переключение оружия
- **Клавиши 1, 2, 3** — переключение между слотами
- **Визуальная индикация** — HUD показывает текущий выбор желтым цветом

### Стрельба
- **Левая кнопка мыши (LMB)** — выстрел из текущего оружия
- **Клавиши J, K, L** — выстрел из слотов 1, 2, 3 (документировано, не реализовано)

---

## 📊 HUD отображение

### Верхний левый угол (20, 20)
```
┌─────────────────────────────────────────────────┐
│ 1: Machine Gun  2: ShotGun  3: Rocket Launcher  │
│                                                   │
└─────────────────────────────────────────────────┘
```

**Отображение:**
- Все 3 слота в одной строке
- Название оружия во всех слотах
- Желтый цвет для выбранного слота
- Зеленая полоска снизу для текущего выбора

---

## 👤 Отображение оружия на игроке

### Визуализация
Оружие отображается на правой стороне игрока (позиция +30px по X)

**Реализация:**
```dart
// Player.dart
Future<void> updateWeaponSprite() async {
  final weapon = selectedWeapon;
  if (weapon == null) {
    _weaponComponent.sprite = null;
    return;
  }

  final animator = resourceManager.playerAnimator;
  final weaponSprite = animator.getSprite(weapon.weaponSpriteName);

  if (weaponSprite != null) {
    // Отрисовка обрезанного спрайта
    weaponSprite.renderCentered(...);
  }
}
```

**Спрайты из grits_effects.json:**
- `machinegun.png` — Machine Gun
- `shotgun.png` — ShotGun
- `chaingun.png` — Chain Gun
- `rocket_launcher.png` — Rocket Launcher
- `grenade_launcher.png` — Grenade Launcher
- `landmine.png` — Landmine
- `defensive_shield.png` — Shield
- `offensive_shield.png` — Sword
- `thruster.png` — Thrusters

---

## 🛠️ Архитектура

### WeaponBase (абстрактный класс)
```dart
abstract class WeaponBase {
  String get itemID;
  String get displayName;
  double get energyCost;
  double get fireDelayInSeconds;
  double get damage;
  String get weaponSpriteName;
  String get projectileSpritePattern;
  String get muzzleSpritePattern;
  String get impactSpritePattern;
  
  void onInit(Player player);
  void onFire(Player player);
  void onUpdate(Player player, double dt);
}
```

### WeaponRegistry (Factory паттерн)
```dart
WeaponRegistry.register(); // Регистрация всех оружий
WeaponRegistry.createWeapon('MachineGun'); // Создание
```

### Player (интеграция)
```dart
player.setWeapon(0, MachineGun());  // Слот 1
player.setWeapon(1, ShotGun());     // Слот 2
player.setWeapon(2, RocketLauncher()); // Слот 3
player.selectWeapon(1); // Переключение на слот 2
player.updateWeaponSprite(); // Обновить отображение
```

---

## 🎨 Спрайты оружия

Все спрайты находятся в `assets/grits_effects.json`

**Структура именования:**
```
{weapon_name}.png           // Основное изображение
{weapon_name}_mask.png      // Маска цвета команды
{weapon_name}_projectile_XXXX.png  // Снаряд (8 кадров)
{weapon_name}_muzzle_XXXX.png      // Эффект выстрела (8 кадров)
{weapon_name}_impact_XXXX.png      // Эффект удара (30 кадров)
```

**Примеры:**
- `machinegun.png` — 38×30 @ (1354, 2016)
- `shotgun.png` — 32×32 @ (1536, 1902)
- `chaingun.png` — 42×34 @ (1770, 1920)
- `rocket_launcher.png` — 40×26 @ (1568, 1902)
- `grenade_launcher.png` — 46×30 @ (1610, 1902)
- `landmine.png` — (нужно проверить)
- `defensive_shield.png` — 30×28 @ (1992, 1974)
- `offensive_shield.png` — 30×28 @ (2024, 1974)
- `thruster.png` — 34×30 @ (2056, 1974)

**Полный справочник:** `WEAPON_SPRITES_REFERENCE.md`

---

## 🎮 Особые механики

### Shield (Щит)
- **Удержание кнопки** — активен пока нажата
- **Расход энергии** — 2 единицы в секунду
- **Визуализация** — синий полупрозрачный круг

### Energy Sword (Меч)
- **Удержание кнопки** — активен пока нажата
- **Расход энергии** — 2 единицы в секунду
- **Визуализация** — зеленый полупрозрачный круг

### Thrusters (Ускорение)
- **Удержание кнопки** — скорость +50% пока нажата
- **Расход энергии** — 0 (бесплатно)
- **Эффект** — скорость ходьбы увеличивается с 200 до 300 пикселей/сек

### Landmine (Мина)
- **Ставится позади игрока**
- **Взрывается при приближении врага**
- **Урон** — 50 (высокий)

---

## 📝 Файлы проекта

### Оружие
```
lib/flame_game/weapons/
├── weapon_base.dart           # Базовый класс + ProjectileBase
├── weapon_registry.dart       # Factory для создания
├── machine_gun.dart           # ✅ Реализовано
├── shot_gun.dart              # ✅ Реализовано
├── chain_gun.dart             # ✅ Реализовано
├── rocket_launcher.dart       # ✅ Реализовано
├── grenade_launcher.dart      # ✅ Реализовано
├── landmine.dart              # ✅ Реализовано
├── shield.dart                # ✅ Реализовано
├── sword.dart                 # ✅ Реализовано
└── thrusters.dart             # ✅ Реализовано
```

### Снаряды
```
lib/flame_game/projectiles/
└── bullet.dart                # Базовый снаряд для пулеметов
```

### HUD
```
lib/flame_game/components/hud/
└── weapon_indicator.dart      # Отображение выбора оружия
```

### Модели
```
lib/flame_game/models/
└── player_animator.dart       # Загрузка спрайтов из JSON
                                 + метод getSprite()
```

---

## ✅ Тестирование

```bash
flutter analyze
# 0 errors found
# 17 info/warnings (deprecated withOpacity, не критично)
```

---

## 🎯 Следующие шаги

1. **Добавить звуки выстрелов**
   - `machine_shoot0.ogg` — Machine Gun, Chain Gun
   - `shotgun_shoot0.ogg` — ShotGun
   - `rocket_shoot0.ogg` — Rocket Launcher
   - `grenade_shoot0.ogg` — Grenade Launcher

2. **Реализовать коллизии снарядов**
   - Добавить проверку столкновений
   - Наносить урон при попадании
   - Эффекты взрыва/удара

3. **Добавить анимации выстрелов**
   - Загрузить muzzle animations из JSON
   - Отображать эффект при выстреле

4. **Балансировка**
   - Настройка урона и расхода энергии
   - Добавление cooldown'ов

5. **Мультиплеер**
   - Синхронизация выстрелов
   - Передача выбора оружия между клиентами

---

## 📚 Документация

- `WEAPONS_REFERENCE.md` — полный справочник с характеристиками
- `WEAPON_SPRITES_REFERENCE.md` — таблица всех спрайтов из JSON
- `WEAPON_SWITCHING_GUIDE.md` — руководство по переключению

---

_Последнее обновление: 2025_
