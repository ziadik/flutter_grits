# ⚔️ Справочник оружия из JS-кода

> Полный список всех видов оружия с характеристиками из оригинального JavaScript-кода игры Grits.

---

## 📊 Таблица всех видов оружия

| №   | Название             | ItemID | Type | Energy Cost | Fire Delay | Damage | Скорость снаряда | Lifetime     | Особенности                    |
| --- | -------------------- | ------ | ---- | ----------- | ---------- | ------ | ---------------- | ------------ | ------------------------------ |
| 1   | **Machine Gun**      | `1234` | 0    | 2           | 0.1s       | 5      | 700              | 2s           | Стандартное оружие             |
| 2   | **Shotgun**          | `8234` | 0    | 4           | 0.25s      | 10×5   | 700              | 2s           | 5 пуль с разбросом             |
| 3   | **Chain Gun**        | `1134` | 0    | 1           | 0.05s      | 5      | 800              | 1.5s         | Очень высокая скорострельность |
| 4   | **Grenade Launcher** | `1232` | 1    | 8           | 0.5s       | 10     | 800              | -            | Прыгающая граната              |
| 5   | **Rocket Launcher**  | `4805` | 1    | 10          | 0.5s       | 10     | 900              | 3s           | Ракета с взрывом               |
| 6   | **Shield**           | `4188` | 2    | 2           | 0.5s       | -      | -                | Пока держишь | Защитный щит                   |
| 7   | **Landmine**         | `4123` | 2    | 10          | 0.5s       | -      | -                | 10s          | Мина на земле                  |
| 8   | **Energy Sword**     | `4124` | 2    | 2           | 0.5s       | -      | -                | Пока держишь | Меч ближнего боя               |
| 9   | **Thrusters**        | `4133` | 2    | -           | -          | -      | -                | Пока держишь | Ускорение движения (+50%)      |

---

## 📝 Детальное описание каждого оружия

### 1️⃣ Machine Gun (Машинное оружие)

**Файл:** `old_code_js/shared/weapons/MachineGun.js`

```javascript
itemID: "1234"
energyCost: 2
fireDelayInSeconds: 0.1
damage: 5
speed: 700
lifetime: 2s
```

**Описание:** Стандартное оружие игрока. Баланс между скорострельностью и расходом энергии.

**Снаряд:** `SimpleProjectile`

- `animFrameName: "machinegun_projectile_00"`
- `impactFrameName: "machinegun_impact_00"`
- `spawnSound: "./sound/machine_shoot0.ogg"`
- `impactSound: "./sound/bounce0.ogg"`

**Применение в Dart:**

```dart
class MachineGun extends WeaponBase {
  @override double get energyCost => 2;
  @override double get fireDelayInSeconds => 0.1;
}
```

---

### 2️⃣ Shotgun (Дробовик)

**Файл:** `old_code_js/shared/weapons/ShotGun.js`

```javascript
itemID: "8234"
energyCost: 4
fireDelayInSeconds: 0.25
damage: 10 (на дробинку)
```

**Описание:** Мощное оружие ближнего боя. Стреляет 5 дробинок с разбросом.

**Механика:**

```javascript
var numBullets = 5;
var incr = 2.0 / numBullets;
for (var i = 0; i < numBullets; i++) {
  var sprayOffset = incr * (i + 1) - 1; // Разброс ±1 радиан
  // Создаем дробинку
}
```

**Снаряд:** `SimpleProjectile`

- `animFrameName: "shotgun_projectile_00"`
- `impactFrameName: "shotgun_impact_00"`
- `spawnSound: "./sound/shotgun_shoot0.ogg"`
- `impactSound: "./sound/bounce0.ogg"`

**Применение в Dart:**

```dart
class ShotGun extends WeaponBase {
  @override double get energyCost => 4;
  @override double get fireDelayInSeconds => 0.25;

  @override
  void onFire(Player player) {
    const numBullets = 5;
    const spread = 2.0 / numBullets;
    for (int i = 0; i < numBullets; i++) {
      final offset = (spread * (i + 1)) - 1;  // ±1 радиан
      // Создаем дробинку с углом offset
    }
  }
}
```

---

### 3️⃣ Chain Gun (Пулемет)

**Файл:** `old_code_js/shared/weapons/ChainGun.js`

```javascript
itemID: "1134"
energyCost: 1
fireDelayInSeconds: 0.05  // Очень быстро!
damage: 5
speed: 800
lifetime: 1.5s
```

**Описание:** Скорострельное оружие с низким расходом энергии. Идеально для подавления.

**Снаряд:** `SimpleProjectile`

- `animFrameName: "chaingun_projectile_00"`
- `impactFrameName: "chaingun_impact_00"`
- `spawnSound: "./sound/machine_shoot0.ogg"`
- `impactSound: "./sound/bounce0.ogg"`

**Применение в Dart:**

```dart
class ChainGun extends WeaponBase {
  @override double get energyCost => 1;
  @override double get fireDelayInSeconds => 0.05;  // 20 выстрелов/сек!
}
```

---

### 4️⃣ Grenade Launcher (Гранатомет)

**Файл:** `old_code_js/shared/weapons/BounceBallGun.js`

```javascript
itemID: "1232";
energyCost: 8;
fireDelayInSeconds: 0.5;
```

**Описание:** Стреляет прыгающими гранатами. Высокий расход энергии.

**Снаряд:** `BounceBallBullet` (особый тип с отскоком)

**Применение в Dart:**

```dart
class GrenadeLauncher extends WeaponBase {
  @override double get energyCost => 8;
  @override double get fireDelayInSeconds => 0.5;

  @override
  void onFire(Player player) {
    // Создаем BounceBallBullet (прыгающий снаряд)
  }
}
```

---

### 5️⃣ Rocket Launcher (Ракетница)

**Файл:** `old_code_js/shared/weapons/RocketLauncher.js`

```javascript
itemID: "4805"
energyCost: 10
fireDelayInSeconds: 0.5
damage: 10
speed: 900  // Самая быстрая
lifetime: 3s
```

**Описание:** Мощная ракета с взрывом при попадании.

**Снаряд:** `SimpleProjectile`

- `animFrameName: "rocket_launcher_projectile_00"`
- `impactFrameName: "rocket_launcher_impact_00"`
- `spawnSound: "./sound/rocket_shoot0.ogg"`
- `impactSound: "./sound/explode0.ogg"` // Взрыв!

**Применение в Dart:**

```dart
class RocketLauncher extends WeaponBase {
  @override double get energyCost => 10;
  @override double get fireDelayInSeconds => 0.5;

  @override
  void onFire(Player player) {
    // Создаем ракету с взрывом при попадании
  }
}
```

---

### 6️⃣ Shield (Защитный щит)

**Файл:** `old_code_js/shared/weapons/Shield.js`

```javascript
itemID: "4188"
energyCost: 2 (продолжается пока держишь)
```

**Описание:** Создает защитный щит перед игроком. Тратит энергию пока удерживаешь кнопку.

**Механика:**

```javascript
onFire(player) {
  if (this.shieldInstance != null) return;
  this.shieldInstance = spawnEntity("ShieldInstance", player.pos);
}

onUpdate(player) {
  if (player.fire2_off || player.energy <= 0) {
    this.shieldInstance.kill();
    this.shieldInstance = null;
  }
}
```

**Отрисовка:** `defensive_shield.png`

**Применение в Dart:**

```dart
class Shield extends WeaponBase {
  ShieldInstance? _shieldInstance;

  @override double get energyCost => 2;  // в секунду?

  @override
  void onFire(Player player) {
    if (_shieldInstance != null) return;
    _shieldInstance = ShieldInstance(position: player.position, owner: player);
  }

  @override
  void onUpdate(Player player, double dt) {
    if (!player.isFiringShield || player.energy <= 0) {
      _shieldInstance?.destroy();
      _shieldInstance = null;
    }
  }
}
```

---

### 7️⃣ Landmine (Наземная мина)

**Файл:** `old_code_js/shared/weapons/Landmine.js`

```javascript
itemID: "4123";
energyCost: 10;
fireDelayInSeconds: 0.5;
```

**Описание:** Ставит мину позади игрока. Взрывается при приближении врага.

**Механика:**

```javascript
onFire(player) {
  // Ставим мину ЗА спиной (-25px)
  var point1 = player.pos - dir * 25;
  var ent = spawnEntity("LandmineDisk", point1);
}
```

**Снаряд:** `LandmineDisk` (стационарная мина)

**Применение в Dart:**

```dart
class Landmine extends WeaponBase {
  @override double get energyCost => 10;
  @override double get fireDelayInSeconds => 0.5;

  @override
  void onFire(Player player) {
    final spawnPos = player.position - _getDirection(player) * 25;
    final mine = LandmineDisk(position: spawnPos, team: player.team);
    player.addToWorld(mine);
  }
}
```

---

### 8️⃣ Energy Sword (Энергетический меч)

**Файл:** `old_code_js/shared/weapons/Sword.js`

```javascript
itemID: "4124";
energyCost: 2;
```

**Описание:** Ближний бой. Создает энергетический меч перед игроком.

**Механика:** Аналогична Shield (удержание кнопки)

**Отрисовка:** `offensive_shield.png`

**Снаряд:** `SwordInstance`

**Применение в Dart:**

```dart
class Sword extends WeaponBase {
  SwordInstance? _swordInstance;

  @override double get energyCost => 2;

  @override
  void onFire(Player player) {
    if (_swordInstance != null) return;
    _swordInstance = SwordInstance(position: player.position, owner: player);
  }
}
```

---

### 9️⃣ Thrusters (Трюстеры / Ускорение)

**Файл:** `old_code_js/shared/weapons/Thrusters.js`

```javascript
itemID: "4133"
energyCost: -  // Не тратит энергию при активации
```

**Описание:** Временно увеличивает скорость движения игрока на 50%.

**Механика:**

```javascript
onFire(player) {
  this.storedSpeed = player.walkSpeed;
  player.walkSpeed += player.walkSpeed * 0.5;  // +50%
}

onUpdate(player) {
  if (player.fire2_off && this.storedSpeed != -1) {
    player.walkSpeed = this.storedSpeed;  // Возврат
    this.storedSpeed = -1;
  }
}
```

**Применение в Dart:**

```dart
class Thrusters extends WeaponBase {
  double? _storedSpeed;

  @override double get energyCost => 0;  // Не тратит при активации

  @override
  void onFire(Player player) {
    if (_storedSpeed != null) return;
    _storedSpeed = player.walkSpeed;
    player.walkSpeed = player.walkSpeed * 1.5;  // +50%
  }

  @override
  void onUpdate(Player player, double dt) {
    if (!player.isFiringThrusters && _storedSpeed != null) {
      player.walkSpeed = _storedSpeed!;
      _storedSpeed = null;
    }
  }
}
```

---

## 📂 Типы снарядов

| Снаряд               | Файл                                         | Описание           | Особенности                                                    |
| -------------------- | -------------------------------------------- | ------------------ | -------------------------------------------------------------- |
| **SimpleProjectile** | `shared/weaponinstances/SimpleProjectile.js` | Базовый снаряд     | Используется для MachineGun, ShotGun, ChainGun, RocketLauncher |
| **BounceBallBullet** | `shared/weaponinstances/BounceBallBullet.js` | Прыгающая граната  | Отскакивает от стен (Grenade Launcher)                         |
| **LandmineDisk**     | `shared/weaponinstances/LandmineDisk.js`     | Стационарная мина  | Взрывается при касании (Landmine)                              |
| **ShieldInstance**   | `shared/weaponinstances/Shield.js`           | Защитный щит       | Блокирует урон (Shield)                                        |
| **SwordInstance**    | `shared/weaponinstances/Sword.js`            | Энергетический меч | Наносит урон при касании (Sword)                               |

---

## 🎯 Классификация по типам

### Type 0: Прямой огонь (Direct Fire)

- Machine Gun
- ShotGun
- Chain Gun

**Характеристики:**

- Быстрая скорострельность
- Прямая траектория
- Низкий/средний расход энергии

---

### Type 1: Навесной огонь (Indirect Fire)

- Grenade Launcher (BounceBallGun)
- Rocket Launcher

**Характеристики:**

- Высокий расход энергии
- Особая физика снарядов (отскок/взрыв)
- Длинное время жизни снаряда

---

### Type 2: Особое / Дефенсивное (Special/Defensive)

- Shield (защита)
- Landmine (ловушка)
- Sword (ближний бой)
- Thrusters (ускорение)

**Характеристики:**

- Удержание кнопки для эффекта
- Особая механика (не снаряды)
- Временные эффекты

---

## 🎨 Анимации и звуки

### Спрайты оружия (из `grits_effects.json`)

Все спрайты оружия находятся в `assets/grits_effects.json` с паттернами именования:

| Оружие           | Основной спрайт        | Пуля                                   | Muzzle                             | Impact                             | Размер |
| ---------------- | ---------------------- | -------------------------------------- | ---------------------------------- | ---------------------------------- | ------ |
| Machine Gun      | `machinegun.png`       | `machinegun_projectile_XXXX.png`       | `machinegun_muzzle_XXXX.png`       | `machinegun_impact_XXXX.png`       | 38×30  |
| ShotGun          | `shotgun.png`          | `shotgun_projectile_XXXX.png`          | `shotgun_muzzle_XXXX.png`          | `shotgun_impact_XXXX.png`          | 32×32  |
| ChainGun         | `chaingun.png`         | `chaingun_projectile_XXXX.png`         | `chaingun_muzzle_XXXX.png`         | `chaingun_impact_XXXX.png`         | 42×34  |
| Rocket Launcher  | `rocket_launcher.png`  | `rocket_launcher_projectile_XXXX.png`  | `rocket_launcher_muzzle_XXXX.png`  | `rocket_launcher_impact_XXXX.png`  | 40×26  |
| Grenade Launcher | `grenade_launcher.png` | `grenade_launcher_projectile_XXXX.png` | `grenade_launcher_muzzle_XXXX.png` | `grenade_launcher_impact_XXXX.png` | 46×30  |
| Shield           | `defensive_shield.png` | -                                      | -                                  | -                                  | 30×28  |
| Sword            | `offensive_shield.png` | -                                      | -                                  | -                                  | 30×28  |
| Thrusters        | `thruster.png`         | -                                      | -                                  | -                                  | 34×30  |
| Landmine         | `landmine.png`         | -                                      | -                                  | `landmine_explosion_XXXX.png`      | -      |

**Полный справочник спрайтов:** `WEAPON_SPRITES_REFERENCE.md`

### Звуки выстрелов

| Оружие           | Звук выстрела        | Звук удара     |
| ---------------- | -------------------- | -------------- |
| Machine Gun      | `machine_shoot0.ogg` | `bounce0.ogg`  |
| Chain Gun        | `machine_shoot0.ogg` | `bounce0.ogg`  |
| ShotGun          | `shotgun_shoot0.ogg` | `bounce0.ogg`  |
| Grenade Launcher | (нужно проверить)    | `bounce0.ogg`  |
| Rocket Launcher  | `rocket_shoot0.ogg`  | `explode0.ogg` |

---

## 📋 Баланс (рекомендации для переноса)

### Расход энергии

| Оружие           | Energy Cost | DPS (если 100 energy)          |
| ---------------- | ----------- | ------------------------------ |
| Chain Gun        | 1           | 1000 урона/сек (очень высоко!) |
| Machine Gun      | 2           | 500 урона/сек                  |
| ShotGun          | 4           | 400 урона/сек                  |
| Grenade Launcher | 8           | 100 урона/сек                  |
| Rocket Launcher  | 10          | 100 урона/сек                  |
| Shield           | 2/сек       | -                              |
| Sword            | 2           | -                              |

### Рекомендации:

1. **Chain Gun** — самый эффективный по DPS, но малый радиус
2. **ShotGun** — высокий урон на короткой дистанции
3. **Rocket/Grenade** — высокий урон по области, но дорогой
4. **Machine Gun** — универсальное оружие

---

## 🔄 Слоты оружия

В Player.js используется 3 слота:

```javascript
this.weapons = [null, null, null];

// Слот 0: Основное оружие
var weapon0Class = Factory.getClass("ShotGun"); // или MachineGun

// Слот 1: Вторичное / Дефенсивное
var weapon1Class = Factory.getClass("Shield"); // или Landmine

// Слот 2: Особое
var weapon2Class = Factory.getClass("Thrusters");
```

**Типичная конфигурация:**

- **Слот 0:** MachineGun / ShotGun / ChainGun (стрельба)
- **Слот 1:** Shield / Landmine (защита/ловушки)
- **Слот 2:** Thrusters / Sword / RocketLauncher (особое)

---

## 💡 Советы для реализации в Dart

1. **Наследование от WeaponBase:**

   ```dart
   abstract class WeaponBase {
     void onInit(Player player);
     void onUpdate(Player player, double dt);
     void onFire(Player player);
     void onDraw(Canvas canvas, Player player);
   }
   ```

2. **Factory для создания:**

   ```dart
   class WeaponRegistry {
     static WeaponBase create(String name) {
       switch(name) {
         case 'MachineGun': return MachineGun();
         case 'ShotGun': return ShotGun();
         // ...
       }
     }
   }
   ```

3. **Снаряды через ProjectileBase:**

   ```dart
   abstract class ProjectileBase extends PositionComponent {
     void onCollision(Vector2 point, PositionComponent other);
   }
   ```

4. **Уникальная механика:**
   - Shield/Sword: `onUpdate` для удержания эффекта
   - Thrusters: изменение `player.walkSpeed`
   - Landmine: стационарный объект с таймером

---

## 📊 Сравнение с Weapons.json

Файл `Weapons.json` содержит мета-данные для UI:

```json
{
  "itemID": "1234",
  "displayName": "Machine Gun",
  "displayDesc": "This is your standard issue machine gun",
  "priceInCredits": 0,
  "type": 0,
  "dmg": 5,
  "fireRate": 10,
  "icon": "icon_machinegun",
  "energyCost": 2,
  "logicClass": "MachineGun"
}
```

**Используется для:**

- Отображения в меню
- Покупка оружия (если есть экономика)
- Иконки в UI

---

_Справочник создан: 2025_  
_Версия: 1.0_
