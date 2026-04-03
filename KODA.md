# KODA — Документация проекта flutter_grits

## Обзор проекта

**flutter_grits** — это Flutter-приложение для просмотра и интерактивного взаимодействия с 2D тайловыми картами в стиле изометрических и ортогональных игр. Проект предоставляет инструментарий для визуализации карт из Tiled Map Editor, отрисовки анимированных спрайтов, управления игровым персонажем и слежения камеры за игроком.

### Назначение

Приложение предназначено для:
- Отображения тайловых карт с поддержкой зума и панорамирования
- Визуализации слоёв карты (основной слой, объекты environment)
- Отрисовки анимированных объектов environment (спавнеры, powerup'ы)
- Управления игровым персонажем с клавиатуры (WASD или стрелки)
- Слежения камеры за игроком при движении по карте
- Демонстрации работы со спрайт-листами в формате TexturePacker

### Основные технологии

- **Flutter** — фреймворк для кроссплатформенной разработки
- **Dart** — язык программирования (версия ^3.10.3)
- **CustomPainter** — высокопроизводительная отрисовка графики
- **InteractiveViewer** — виджет для зума и панорамирования карты
- **RawKeyboardListener** — обработка ввода с клавиатуры
- **Tiled Map Editor** — формат JSON для тайловых карт
- **TexturePacker** — формат JSON для спрайт-листов

---

## Архитектура

Проект организован в одном основном файле с разделением ответственности:

```
lib/
├── main.dart                    # Точка входа (импортирует player.dart)
└── player.dart                  # Основной код: приложение, игрок, просмотрщик
```

**Основные компоненты:**

1. **MyApp** (player.dart) — корневой виджет приложения с MaterialApp

2. **MapLoaderScreen** (player.dart) — экран загрузки с асинхронной загрузкой ресурсов (карты и JSON эффектов)

3. **EffectsMapScreen** (player.dart) — основной игровой экран с:
   - Управлением персонажем (WASD/стрелки)
   - Слежением камеры за игроком
   - Панелью инструментов (вкл/выкл эффектов, игрока, подписей, слежения)

4. **TileMapViewerWithEffects** (player.dart) — виджет для отображения тайловой карты с объектами environment

5. **PlayerAnimator** (player.dart) — загрузка и управление анимацией персонажа из TexturePacker JSON (30 кадров на направление: up, down, left, right)

6. **PlayerPainter** (player.dart) — CustomPainter для отрисовки игрока со спрайтами ног, туловища и turret

7. **SpriteSheet** (player.dart) — утилита для работы со спрайтами из TexturePacker JSON

8. **EnvironmentPainter** (player.dart) — отрисовка объектов карты (Spawner'ы для QuadDamage, Energy, Health)

9. **TileLayerPainter** (player.dart) — отрисовка слоёв тайлов карты

10. **CameraController** (player.dart) — класс для управления камерой с плавной навигацией (пока не используется напрямую, логика слежения в EffectsMapScreen)

---

## Сборка и запуск

### Требования

- Flutter SDK версии 3.10.3 или выше
- Dart SDK версии 3.10.3 или выше

### Установка зависимостей

```bash
flutter pub get
```

### Запуск приложения

```bash
# Запуск на подключённом устройстве или эмуляторе
flutter run

# Запуск на конкретном устройстве (после просмотра списка устройств)
flutter devices
flutter run -d <device_id>

# Запуск в режиме Chrome (для web)
flutter run -d chrome
```

### Сборка релизной версии

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Тестирование

```bash
# Запуск всех тестов
flutter test

# Запуск тестов с покрытием
flutter test --coverage

# Запуск конкретного тестового файла
flutter test test/player_test.dart
```

### Линтинг и анализ

```bash
# Проверка стиля кода
flutter analyze

# Автоматическое исправление проблем
dart fix --apply

# Форматирование кода
dart format .
```

---

## Правила разработки

### Стиль кодирования

Проект следует официальным рекомендациям Flutter и Dart:

- Используйте `flutter_lints` для статического анализа (уже включён в dev_dependencies)
- Следуйте руководству [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Используйте `const` конструкторы где возможно для оптимизации производительности
- Именуйте файлы в `snake_case`, классы в `PascalCase`, переменные в `camelCase`

### Структура кода

```dart
// Импорты в алфавитном порядке (flutter -> dart -> пакетные -> локальные)
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
```

### Работа с CustomPainter

При создании новых painter'ов:

1. Наследуйтесь от `CustomPainter`
2. Реализуйте методы `paint()` и `shouldRepaint()`
3. Используйте `FilterQuality.none` и `isAntiAlias: false` для pixel-art графики
4. Кэшируйте тяжёлые вычисления в конструкторе или initState

```dart
class MyPainter extends CustomPainter {
  final ImageInfo imageInfo;
  
  MyPainter({required this.imageInfo});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    
    // Отрисовка...
  }
  
  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.imageInfo != imageInfo;
  }
}
```

### Работа с анимациями

- Используйте `AnimationController` с `TickerProviderStateMixin`
- Высвобождайте ресурсы в `dispose()`
- Для анимации спрайтов используйте `AnimatedBuilder` для оптимизации

```dart
class _MyWidgetState extends State<MyWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Работа с ассетами

- Все ассеты должны быть объявлены в `pubspec.yaml` в секции `flutter/assets`
- Изображения загружаются асинхронно через `ImageStream`
- JSON файлы парсятся с помощью `dart:convert`

```dart
// Загрузка изображения
final imageStream = imageProvider.resolve(ImageConfiguration.empty);
imageStream.addListener(ImageStreamListener((info, _) {
  // Обработка загруженного изображения
}));

// Загрузка JSON
final jsonString = await rootBundle.loadString('assets/file.json');
final jsonData = jsonDecode(jsonString);
```

### Управление игроком

Управление осуществляется с клавиатуры:
- **W / Стрелка вверх** — движение вверх
- **S / Стрелка вниз** — движение вниз
- **A / Стрелка влево** — движение влево
- **D / Стрелка вправо** — движение вправо

Обработка ввода реализована через `RawKeyboardListener` с периодическим опросом состояния клавиш (таймер каждые 16мс ~60 FPS).

### Слежение камеры за игроком

Камера может следить за игроком при движении:

- Включено по умолчанию (`_followPlayer = true`)
- Управление через кнопку в AppBar (иконка GPS)
- Плавное слежение с интерполяцией (lerp factor = 0.1)
- При отключении можно вручную перемещаться по карте

```dart
// Обновление позиции камеры
void _updateCameraPosition() {
  final scale = _cameraController.value.getMaxScaleOnAxis();
  final targetX = _playerX * scale - visibleWidth / 2;
  const lerpFactor = 0.1;
  final newX = currentX + (targetX - currentX) * lerpFactor;
  // Применяем трансформацию...
}
```

### Добавление новых карт

1. Создайте JSON файл в `assets/maps/` в формате Tiled
2. Убедитесь, что tileset изображение находится в `assets/`
3. Добавьте путь к карте в код загрузки (MapLoaderScreen)

Формат карты должен содержать:
- `layers` — массив слоёв (tilelayer, objectgroup)
- `tilewidth`, `tileheight` — размер тайла
- `width`, `height` — размер карты в тайлах

### Добавление новых спрайтов

1. Упакуйте спрайты в TexturePacker и экспортируйте JSON
2. Положите PNG в `assets/`, JSON в `assets/`
3. Добавьте пути в `pubspec.yaml`
4. Используйте `SpriteSheet.fromJson()` для загрузки

### Отладка

Для отладки используйте:
- `print()` для простого логирования
- `debugPrint()` для логирования с ограничением длины
- Флаги `_showDebug` в виджетах для отображения дополнительной информации

---

## Формат файлов

### Tiled Map JSON

Пример структуры:

```json
{
  "width": 64,
  "height": 48,
  "tilewidth": 64,
  "tileheight": 64,
  "layers": [
    {
      "name": "base",
      "type": "tilelayer",
      "data": [1, 2, 3, ...],
      "visible": true
    },
    {
      "name": "environment",
      "type": "objectgroup",
      "objects": [
        {
          "name": "QuadDamageSpawner",
          "type": "Spawner",
          "x": 2748,
          "y": 1022,
          "width": 14,
          "height": 12,
          "properties": {
            "SpawnItem": "QuadDamage"
          }
        }
      ]
    }
  ]
}
```

### TexturePacker JSON

Пример структуры:

```json
{
  "frames": {
    "sprite_name.png": {
      "frame": {"x": 100, "y": 50, "w": 64, "h": 64},
      "rotated": false,
      "trimmed": true,
      "spriteSourceSize": {"x": 0, "y": 0, "w": 64, "h": 64},
      "sourceSize": {"w": 128, "h": 128}
    }
  },
  "meta": {
    "image": "grits_effects.png",
    "size": {"w": 2048, "h": 2048}
  }
}
```

### Имена спрайтов анимации игрока

Анимация ходьбы использует формат:
- `walk_up_XXXX.png` — движение вверх (30 кадров, XXXX = 0000-0029)
- `walk_down_XXXX.png` — движение вниз
- `walk_left_XXXX.png` — движение влево
- `walk_right_XXXX.png` — движение вправо
- `walk_*_mask_XXXX.png` — маски для окраски командой

---

## Ассеты проекта

```
assets/
├── grits_master.png             # Основной tileset карты
├── grits_effects.png            # Спрайты эффектов и игрока
├── grits_effects.json           # Описание спрайт-листа (TexturePacker)
└── maps/
    ├── map1.json                # Карта 1 (Tiled формат)
    └── small_map1.json          # Маленькая карта для тестирования
```

---

## Известные проблемы и TODO

### TODO

- [ ] Добавить поддержку мультиплеера
- [ ] Реализовать систему частиц
- [ ] Добавить экспорт карты в изображение
- [ ] Улучшить коллизии для игрока
- [ ] Добавить звуковые эффекты
- [ ] Интегрировать CameraController в EffectsMapScreen
- [ ] Добавить больше анимаций персонажа (стрельба, смерть и т.д.)

### Известные ограничения

- Анимации работают только с предустановленными спрайтами
- Нет поддержки вращения тайлов (rotated спрайты не обрабатываются)
- Коллизии игрока не реализованы
- Поддерживается только ортогональная ориентация карт
- Нет проверки границ карты при движении игрока
- При отсутствии спрайтов ног рисуются простые овалы (fallback)

---

## Контакт и поддержка

Для вопросов по проекту обращайтесь к документации Flutter:
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Tiled Map Editor](https://www.mapeditor.org/)
