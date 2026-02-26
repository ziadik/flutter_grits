# KODA — Документация проекта flutter_grits

## Обзор проекта

**flutter_grits** — это Flutter-приложение для просмотра и интерактивного взаимодействия с 2D тайловыми картами в стиле изометрических и ортогональных игр. Проект предоставляет инструментарий для визуализации карт из Tiled Map Editor, отрисовки анимированных спрайтов и управления игровым персонажем.

### Назначение

Приложение предназначено для:
- Отображения тайловых карт с поддержкой зума и панорамирования
- Визуализации слоёв карты (основной слой, декали, коллизии)
- Отрисовки анимированных объектов environment (спавнеры, powerup'ы)
- Управления игровым персонажем с клавиатуры (WASD или стрелки)
- Демонстрации работы со спрайт-листами в формате TexturePacker

### Основные технологии

- **Flutter** — фреймворк для кроссплатформенной разработки
- **Dart** — язык программирования (версия ^3.10.3)
- **CustomPainter** — высокопроизводительная отрисовка графики
- **Tiled Map Editor** — формат JSON для тайловых карт
- **TexturePacker** — формат JSON для спрайт-листов

### Архитектура

Проект организован по модульному принципу с разделением ответственности:

```
lib/
├── main.dart                    # Не используется (закомментирован)
├── player.dart                  # Основной код: приложение, игрок, просмотрщик с эффектами
├── tile_map_viewer.dart         # Базовый просмотрщик карт с доп. слоями
└── tile_map_viewer_effect.dart  # Дополнительные эффекты и анимации
```

**Основные компоненты:**

1. **ScrollableTileMapViewer** (tile_map_viewer.dart) — виджет для просмотра карт с поддержкой зума, скролла и отображения дополнительных слоёв (сетка, коллизии, точки спавна)

2. **TileMapViewerWithEffects** (player.dart / tile_map_viewer_effect.dart) — расширенный просмотрщик с анимированными объектами environment, спрайт-листами и эффектами (свечение, пульсация)

3. **PlayerAnimator & PlayerPainter** (player.dart) — система анимации персонажа с поддержкой 30 кадров на направление движения (up, down, left, right)

4. **SpriteSheet** (player.dart / tile_map_viewer_effect.dart) — утилита для работы со спрайтами из TexturePacker JSON

5. **EnvironmentPainter** (player.dart / tile_map_viewer_effect.dart) — отрисовка объектов карты с анимациями (QuadDamage, Energy, Health)

6. **MapLoaderScreen** (player.dart) — экран загрузки с асинхронной загрузкой ресурсов

7. **EffectsMapScreen** (player.dart) — основной игровой экран с управлением персонажем

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
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_grits/player.dart';
import 'tile_map_viewer.dart';
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

Обработка ввода реализована через `RawKeyboardListener` с периодическим опросом состояния клавиш.

### Добавление новых карт

1. Создайте JSON файл в `assets/maps/` в формате Tiled
2. Убедитесь, что tileset изображение находится в `assets/`
3. Добавьте путь к карте в код загрузки

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

---

## Известные проблемы и TODO

### TODO

- [ ] Добавить поддержку мультиплеера
- [ ] Реализовать систему частиц
- [ ] Добавить экспорт карты в изображение
- [ ] Улучшить коллизии для игрока
- [ ] Добавить звуковые эффекты
- [ ] Устранить дублирование кода (SpriteSheet, SpriteData, TileMapViewerWithEffects присутствуют в нескольких файлах)
- [ ] Реализовать нормальную загрузку спрайтов анимации персонажа

### Известные ограничения

- Анимации работают только с предустановленными спрайтами
- Нет поддержки вращения тайлов (rotated спрайты не обрабатываются)
- Коллизии игрока не реализованы
- Поддерживается только ортогональная ориентация карт
- Есть дублирование классов между файлами player.dart и tile_map_viewer_effect.dart

---

## Контакт и поддержка

Для вопросов по проекту обращайтесь к документации Flutter:
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Tiled Map Editor](https://www.mapeditor.org/)
