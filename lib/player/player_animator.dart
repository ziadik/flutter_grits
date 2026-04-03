import 'dart:ui';

import 'package:flutter_grits/models/sprite_data.dart';

/// Класс для анимации игрока - загрузка и управление спрайтами анимации
class PlayerAnimator {
  final Map<String, List<SpriteData>> _legSpriteAnimList = {};
  final Map<String, List<SpriteData>> _legSpriteMaskAnimList = {};
  final Map<String, SpriteData> _sprites = {};
  bool _loaded = false;

  /// Загружает данные анимации из JSON
  void loadFromJson(Map<String, dynamic> effectsJson) {
    if (_loaded) return;

    final frames = effectsJson['frames'] as Map<String, dynamic>;

    // Загружаем все спрайты
    frames.forEach((key, value) {
      final frame = value['frame'] as Map<String, dynamic>;
      final spriteSourceSize = value['spriteSourceSize'] as Map<String, dynamic>;
      final sourceSize = value['sourceSize'] as Map<String, dynamic>;

      _sprites[key] = SpriteData(
        name: key,
        frame: Rect.fromLTWH(
          (frame['x'] as num).toDouble(),
          (frame['y'] as num).toDouble(),
          (frame['w'] as num).toDouble(),
          (frame['h'] as num).toDouble(),
        ),
        spriteSourceSize: Rect.fromLTWH(
          (spriteSourceSize['x'] as num).toDouble(),
          (spriteSourceSize['y'] as num).toDouble(),
          (spriteSourceSize['w'] as num).toDouble(),
          (spriteSourceSize['h'] as num).toDouble(),
        ),
        sourceSize: Size(
          (sourceSize['w'] as num).toDouble(),
          (sourceSize['h'] as num).toDouble(),
        ),
        trimmed: value['trimmed'] as bool,
        rotated: value['rotated'] as bool,
      );
    });

    // Инициализируем анимации ног
    _initLegAnimations();
    _loaded = true;
  }

  void _initLegAnimations() {
    final directions = ['up', 'left', 'down', 'right'];

    for (final dir in directions) {
      final frames = <SpriteData>[];
      final maskFrames = <SpriteData>[];

      // Загружаем кадры для анимации (30 кадров)
      for (int i = 0; i < 30; i++) {
        final frameNumber = i.toString().padLeft(4, '0');
        final spriteName = 'walk_${dir}_$frameNumber.png';
        final maskSpriteName = 'walk_${dir}_mask_$frameNumber.png';

        // Ищем спрайты в загруженных данных
        final sprite = _sprites[spriteName];
        final maskSprite = _sprites[maskSpriteName];

        if (sprite != null) {
          frames.add(sprite);
        } else {
          // Запасной вариант, если спрайт не найден
          frames.add(SpriteData(
            name: spriteName,
            frame: Rect.fromLTWH(0, 0, 64, 64),
            spriteSourceSize: Rect.fromLTWH(0, 0, 64, 64),
            sourceSize: const Size(128, 128),
            trimmed: false,
            rotated: false,
          ));
        }

        if (maskSprite != null) {
          maskFrames.add(maskSprite);
        } else {
          // Запасной вариант, если спрайт не найден
          maskFrames.add(SpriteData(
            name: maskSpriteName,
            frame: Rect.fromLTWH(0, 0, 64, 64),
            spriteSourceSize: Rect.fromLTWH(0, 0, 64, 64),
            sourceSize: const Size(128, 128),
            trimmed: false,
            rotated: false,
          ));
        }
      }

      _legSpriteAnimList[dir] = frames;
      _legSpriteMaskAnimList[dir] = maskFrames;
    }
  }

  /// Получает кадр анимации ног по направлению и значению анимации
  SpriteData? getLegSprite(String direction, double animationValue) {
    final frames = _legSpriteAnimList[direction];
    if (frames == null || frames.isEmpty) return null;

    final frameIndex = (animationValue * frames.length).floor() % frames.length;
    return frames[frameIndex];
  }

  /// Получает кадр маски ног по направлению и значению анимации
  SpriteData? getLegMaskSprite(String direction, double animationValue) {
    final frames = _legSpriteMaskAnimList[direction];
    if (frames == null || frames.isEmpty) return null;

    final frameIndex = (animationValue * frames.length).floor() % frames.length;
    return frames[frameIndex];
  }

  /// Получает спрайт турели
  SpriteData? getTurretSprite() {
    return _sprites['turret_player_color.png'];
  }

  /// Проверяет, загружены ли данные
  bool get isLoaded => _loaded;
}
