# 🎨 Справочник спрайтов оружия из grits_effects.json

> Полный список всех спрайтов оружия с координатами и размерами из `assets/grits_effects.json`

---

## 📊 Таблица всех спрайтов оружия

### 1️⃣ Machine Gun (Машинное оружие)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `machinegun.png` | 38×30 | (1354, 2016) | Основное изображение оружия |
| `machinegun_mask.png` | 30×30 | (1488, 1170) | Маска для цвета команды |
| `machinegun_muzzle_0000-0007.png` | 56-76×46-52 | Разные | Анимация выстрела (8 кадров) |
| `machinegun_impact.png` | 26×28 | (1138, 1436) | Базовый эффект удара |
| `machinegun_impact_0000-0029.png` | 28-84×28-84 | Разные | Анимация удара (30 кадров) |
| `machinegun_projectile_0000-0007.png` | 44-48×34-46 | Разные | Спрайты пули (8 кадров анимации) |

**Пример использования:**
```dart
// Основная картинка оружия
final gunSprite = animator.getSprite('machinegun.png');

// Пуля (первый кадр)
final bulletSprite = animator.getSprite('machinegun_projectile_0000.png');

// Эффект выстрела
final muzzleSprites = animator.getSpritesByPattern('machinegun_muzzle_.*');
```

---

### 2️⃣ Shot Gun (Дробовик)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `shotgun.png` | 32×32 | (1536, 1902) | Основное изображение оружия |
| `shotgun_mask.png` | 18×18 | (574, 1530) | Маска для цвета команды |
| `shotgun_muzzle_0000-0007.png` | 78-104×68-96 | Разные | Анимация выстрела (8 кадров) |
| `shotgun_impact.png` | 58×60 | (1832, 970) | Базовый эффект удара |
| `shotgun_impact_0000-0023.png` | 42-90×34-88 | Разные | Анимация удара (24 кадра) |
| `shotgun_projectile_0000-0007.png` | 56×30 | Разные | Спрайты дробинок (8 кадров) |

**Примечание:** Shotgun стреляет 5 дробинок с разбросом.

---

### 3️⃣ Chain Gun (Пулемет)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `chaingun.png` | 42×34 | (1766, 202) | Основное изображение оружия |
| `chaingun_mask.png` | 28×32 | (1048, 328) | Маска для цвета команды |
| `chaingun_muzzle_0000-0007.png` | 46-72×30-52 | Разные | Анимация выстрела (8 кадров) |
| `chaingun_impact.png` | 38×34 | (1162, 322) | Базовый эффект удара |
| `chaingun_impact_0000-0029.png` | 22-60×28-52 | Разные | Анимация удара (30 кадров) |
| `chaingun_projectile_0000-0007.png` | 40×20-22 | Разные | Спрайты пули (8 кадров анимации) |

**Примечание:** ChainGun имеет самую высокую скорострельность (0.05s между выстрелами).

---

### 4️⃣ Rocket Launcher (Ракетница)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `rocket_launcher.png` | 40×26 | (834, 86) | Основное изображение оружия |
| `rocket_launcher_mask.png` | 40×28 | (876, 84) | Маска для цвета команды |
| `rocket_launcher_muzzle_0000-0007.png` | 54-80×54-68 | Разные | Анимация выстрела (8 кадров) |
| `rocket_launcher_impact.png` | 106×106 | (262, 1354) | Базовый эффект взрыва |
| `rocket_launcher_impact_0000-0029.png` | 84-118×72-138 | Разные | Анимация взрыва (30 кадров) |
| `rocket_launcher_projectile_0000-0007.png` | 102-116×72-76 | Разные | Спрайты ракеты (8 кадров анимации) |

**Примечание:** Ракета имеет самый большой размер снаряда и высокий урон.

---

### 5️⃣ Grenade Launcher (Гранатомет)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `grenade_launcher.png` | 46×30 | (1118, 1470) | Основное изображение оружия |
| `grenade_launcher_mask.png` | - | - | Маска (нужно проверить) |
| `grenade_launcher_muzzle_0000-0007.png` | - | Разные | Анимация выстрела (8 кадров) |
| `grenade_launcher_impact.png` | 128×128 | (146, 2) | Базовый эффект взрыва |
| `grenade_launcher_impact_0000-0029.png` | 66-142×60-140 | Разные | Анимация взрыва (30 кадров) |
| `grenade_launcher_projectile_0000-0007.png` | - | Разные | Спрайты гранаты |

**Примечание:** Граната прыгает от стен (BounceBallBullet).

---

### 6️⃣ Shield (Защитный щит)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `defensive_shield.png` | 30×28 | (762, 1394) | Изображение защитного щита |
| `defensive_shield_mask.png` | 14×26 | (1430, 1104) | Маска щита |

**Примечание:** Щит создается перед игроком и блокирует урон.

---

### 7️⃣ Sword (Энергетический меч)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `offensive_shield.png` | 30×28 | (858, 1394) | Изображение энергетического меча |
| `offensive_shield_mask.png` | 30×28 | (826, 1394) | Маска меча |

**Примечание:** Меч используется для ближнего боя.

---

### 8️⃣ Thrusters (Трюстеры / Ускорение)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `thruster.png` | 34×30 | (1464, 1904) | Изображение трюстеров |
| `thruster_mask.png` | 30×26 | (1398, 1104) | Маска трюстеров |

**Примечание:** Увеличивает скорость движения игрока на 50%.

---

### 9️⃣ Landmine (Наземная мина)

| Спрайт | Размер | Координаты | Описание |
|--------|--------|------------|----------|
| `landmine.png` | - | - | Основное изображение мины |
| `landmine_idle_0010-00XX.png` | - | Разные | Анимация ожидания |
| `landmine_explosion_small_0010-0029.png` | - | Разные | Анимация небольшого взрыва |
| `landmine_explosion_large_0010-0029.png` | - | Разные | Анимация большого взрыва |

**Примечание:** Мина ставится на землю и взрывается при приближении врага.

---

## 🎯 Паттерны именования спрайтов

### Структура имени:
```
{weapon}_{type}_{frame}.png
```

**Компоненты:**
- `weapon` - название оружия: `machinegun`, `shotgun`, `chaingun`, `rocket_launcher`, `grenade_launcher`, `defensive_shield`, `offensive_shield`, `thruster`, `landmine`
- `type` - тип спрайта:
  - (пусто) - основное изображение оружия
  - `_mask` - маска для цвета команды
  - `_muzzle_XXXX` - анимация выстрела (дульная вспышка)
  - `_impact` - базовый эффект удара/взрыва
  - `_impact_XXXX` - анимация удара/взрыва
  - `_projectile_XXXX` - анимация снаряда
  - `_idle_XXXX` - анимация ожидания (для мин)
  - `_explosion_small_XXXX` - малый взрыв
  - `_explosion_large_XXXX` - большой взрыв
- `frame` - номер кадра анимации (0000-0029)

---

## 🔧 Примеры использования в коде

### Загрузка основного спрайта оружия

```dart
// В weapon_base.dart или weapon implementation
class MachineGun extends WeaponBase {
  @override
  void onDraw(Canvas canvas, Player player) {
    final animator = player.resourceManager.playerAnimator;
    final gunSprite = animator.getSprite('machinegun.png');
    
    if (gunSprite != null) {
      gunSprite.render(canvas, position);
    }
  }
}
```

### Загрузка анимации выстрела

```dart
// Получить все кадры muzzle
final muzzleSprites = animator.getSpritesByPattern(r'machinegun_muzzle_.*');

// Или получить конкретный кадр
final muzzleFrame = animator.getSprite('machinegun_muzzle_0003.png');
```

### Загрузка анимации снаряда

```dart
// Получить кадры анимации пули
final projectileSprites = [
  animator.getSprite('machinegun_projectile_0000.png'),
  animator.getSprite('machinegun_projectile_0001.png'),
  animator.getSprite('machinegun_projectile_0002.png'),
  animator.getSprite('machinegun_projectile_0003.png'),
  animator.getSprite('machinegun_projectile_0004.png'),
  animator.getSprite('machinegun_projectile_0005.png'),
  animator.getSprite('machinegun_projectile_0006.png'),
  animator.getSprite('machinegun_projectile_0007.png'),
];
```

### Загрузка анимации удара

```dart
// Получить все кадры эффекта удара
final impactSprites = animator.getSpritesByPattern(r'machinegun_impact_.*');

// Создать анимацию
final impactAnimation = SpriteAnimation.spriteList(
  impactSprites,
  stepTime: 0.1,
  loop: false,
);
```

---

## 📝 Методы PlayerAnimator для загрузки спрайтов

### Базовые методы

```dart
// Получить один спрайт по имени
TrimmedSprite? getSprite(String name);

// Получить несколько спрайтов по паттерну
List<TrimmedSprite> getSpritesByPattern(String pattern);

// Получить кадры анимации по префиксу
List<TrimmedSprite> getSpritesByPrefix(String prefix);
```

### Примеры

```dart
// Получить основной спрайт оружия
final gunSprite = animator.getSprite('machinegun.png');

// Получить все кадры muzzle
final muzzleSprites = animator.getSpritesByPattern(r'machinegun_muzzle_.*');

// Получить все кадры projectile
final projectileSprites = animator.getSpritesByPrefix('machinegun_projectile_');

// Получить все кадры impact
final impactSprites = animator.getSpritesByPrefix('machinegun_impact_');
```

---

## 🎨 Размеры и координаты для отрисовки

### Пример: отрисовка оружия на игроке

```dart
void renderWeapon(Canvas canvas, Player player) {
  final animator = player.resourceManager.playerAnimator;
  final gunSprite = animator.getSprite('machinegun.png');
  
  if (gunSprite == null) return;
  
  // Координаты из таблицы
  // machinegun.png: 38×30 @ (1354, 2016)
  
  // Отрисовка с учетом позиции игрока
  final weaponPosition = player.position + getWeaponOffset(player);
  gunSprite.renderCentered(
    canvas,
    weaponPosition,
    Size(40, 40), // Размер для отображения
    null,
  );
}
```

### Пример: отрисовка снаряда

```dart
class Bullet extends ProjectileBase {
  final Sprite? _bulletSprite;
  
  Bullet({
    required super.position,
    required super.owner,
    required super.direction,
    required super.damage,
    required super.speed,
    required super.lifetime,
  }) : _bulletSprite = owner.resourceManager.playerAnimator
           .getSprite('machinegun_projectile_0000.png') {
    size = Vector2(48, 46); // Размер из таблицы
    anchor = Anchor.center;
  }
  
  @override
  void render(Canvas canvas) {
    if (_bulletSprite != null) {
      _bulletSprite!.renderCentered(
        canvas,
        Vector2.zero(),
        Size(size.x, size.y),
        null,
      );
    }
  }
}
```

---

## 📋 Полный список всех спрайтов (из JSON)

### Machine Gun (44 спрайта)
```
machinegun.png (38×30)
machinegun_mask.png (30×30)
machinegun_muzzle_0000-0007.png (8 кадров)
machinegun_impact.png (26×28)
machinegun_impact_0000-0029.png (30 кадров)
machinegun_projectile_0000-0007.png (8 кадров)
```

### Shot Gun (40 спрайтов)
```
shotgun.png (32×32)
shotgun_mask.png (18×18)
shotgun_muzzle_0000-0007.png (8 кадров)
shotgun_impact.png (58×60)
shotgun_impact_0000-0023.png (24 кадра)
shotgun_projectile_0000-0007.png (8 кадров)
```

### Chain Gun (46 спрайтов)
```
chaingun.png (42×34)
chaingun_mask.png (28×32)
chaingun_muzzle_0000-0007.png (8 кадров)
chaingun_impact.png (38×34)
chaingun_impact_0000-0029.png (30 кадров)
chaingun_projectile_0000-0007.png (8 кадров)
```

### Rocket Launcher (44 спрайта)
```
rocket_launcher.png (40×26)
rocket_launcher_mask.png (40×28)
rocket_launcher_muzzle_0000-0007.png (8 кадров)
rocket_launcher_impact.png (106×106)
rocket_launcher_impact_0000-0029.png (30 кадров)
rocket_launcher_projectile_0000-0007.png (8 кадров)
```

### Grenade Launcher (42+ спрайта)
```
grenade_launcher.png (46×30)
grenade_launcher_mask.png (требуется проверка)
grenade_launcher_muzzle_0000-0007.png (8 кадров)
grenade_launcher_impact.png (128×128)
grenade_launcher_impact_0000-0029.png (30 кадров)
grenade_launcher_projectile_0000-0007.png (8 кадров)
```

### Shield (2 спрайта)
```
defensive_shield.png (30×28)
defensive_shield_mask.png (14×26)
```

### Sword (2 спрайта)
```
offensive_shield.png (30×28)
offensive_shield_mask.png (30×28)
```

### Thrusters (2 спрайта)
```
thruster.png (34×30)
thruster_mask.png (30×26)
```

### Landmine (60+ спрайтов)
```
landmine.png (требуется проверка)
landmine_idle_0010-00XX.png (анимация ожидания)
landmine_explosion_small_0010-0029.png (20 кадров)
landmine_explosion_large_0010-0029.png (20 кадров)
```

---

*Справочник создан: 2025*  
*Версия: 1.0*
