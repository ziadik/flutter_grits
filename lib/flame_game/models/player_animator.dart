// lib/models/player_animator.dart
import 'dart:ui';
import 'package:flame/sprite.dart';
import 'package:vector_math/vector_math.dart';

/// Расширенный Sprite с информацией об обрезке
class TrimmedSprite {
  final Sprite sprite;
  final Rect
  spriteSourceSize; // Позиция обрезанного спрайта относительно оригинального
  final Size sourceSize; // Оригинальный размер изображения (128x128)
  final bool trimmed;
  final Rect frame; // Оригинальный фрейм в атласе

  TrimmedSprite({
    required this.sprite,
    required this.spriteSourceSize,
    required this.sourceSize,
    required this.trimmed,
    required this.frame,
  });

  /// Отрисовка спрайта с правильным центрированием (без растягивания)
  void renderCentered(
    Canvas canvas,
    Vector2 position,
    Size targetSize,
    Paint? paint,
  ) {
    if (trimmed) {
      // Вычисляем центр целевого контейнера
      final centerX = position.x + targetSize.width / 2;
      final centerY = position.y + targetSize.height / 2;

      // Оригинальный центр изображения (64, 64 для 128x128)
      final originalCenterX = sourceSize.width / 2;
      final originalCenterY = sourceSize.height / 2;

      // Смещение обрезанного спрайта относительно оригинального центра
      final offsetX = originalCenterX - spriteSourceSize.left;
      final offsetY = originalCenterY - spriteSourceSize.top;

      // Финальная позиция для отрисовки (центрируем)
      final finalX = centerX - (spriteSourceSize.width / 2) - offsetX;
      final finalY = centerY - (spriteSourceSize.height / 2) - offsetY;

      // Рисуем спрайт в ОРИГИНАЛЬНОМ размере (не растягиваем!)
      sprite.render(
        canvas,
        position: Vector2(finalX, finalY),
        size: Vector2(spriteSourceSize.width, spriteSourceSize.height),
        overridePaint: paint,
      );
    } else {
      // Если не обрезано, тоже не растягиваем, а центрируем
      final centerX = position.x + targetSize.width / 2;
      final centerY = position.y + targetSize.height / 2;
      final spriteWidth = sprite.srcSize.x;
      final spriteHeight = sprite.srcSize.y;

      final finalX = centerX - (spriteWidth / 2);
      final finalY = centerY - (spriteHeight / 2);

      sprite.render(
        canvas,
        position: Vector2(finalX, finalY),
        size: Vector2(spriteWidth, spriteHeight),
        overridePaint: paint,
      );
    }
  }
}

class PlayerAnimator {
  final Map<String, TrimmedSprite> _sprites = {};
  final Map<String, List<TrimmedSprite>> _legSpriteAnimList = {};
  final Map<String, List<TrimmedSprite>> _legSpriteMaskAnimList = {};
  bool _loaded = false;
  late Image _effectsImage;

  // Getter для отладки
  Map<String, TrimmedSprite> get sprites => _sprites;

  void loadImages(Image effectsImage) {
    _effectsImage = effectsImage;
  }

  void loadFromJson(Map<String, dynamic> effectsJson) {
    if (_loaded) return;

    final frames = effectsJson['frames'] as Map<String, dynamic>;

    // Загружаем все спрайты с информацией об обрезке
    frames.forEach((key, value) {
      final frame = value['frame'] as Map<String, dynamic>;
      final spriteSourceSize =
          value['spriteSourceSize'] as Map<String, dynamic>;
      final sourceSize = value['sourceSize'] as Map<String, dynamic>;
      final trimmed = value['trimmed'] as bool;
      final rotated = value['rotated'] as bool;

      final sprite = Sprite(
        _effectsImage,
        srcPosition: Vector2(
          (frame['x'] as num).toDouble(),
          (frame['y'] as num).toDouble(),
        ),
        srcSize: Vector2(
          (frame['w'] as num).toDouble(),
          (frame['h'] as num).toDouble(),
        ),
      );

      _sprites[key] = TrimmedSprite(
        sprite: sprite,
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
        trimmed: trimmed,
        frame: Rect.fromLTWH(
          (frame['x'] as num).toDouble(),
          (frame['y'] as num).toDouble(),
          (frame['w'] as num).toDouble(),
          (frame['h'] as num).toDouble(),
        ),
      );
    });

    _initLegAnimations();
    _loaded = true;
  }

  void _initLegAnimations() {
    final directions = ['up', 'left', 'down', 'right'];

    for (final dir in directions) {
      final frames = <TrimmedSprite>[];
      final maskFrames = <TrimmedSprite>[];

      // Собираем все кадры для направления
      for (int i = 1; i <= 30; i++) {
        final frameNumber = i.toString().padLeft(4, '0');
        final spriteName = 'walk_${dir}_$frameNumber.png';
        final maskSpriteName = 'walk_${dir}_mask_$frameNumber.png';

        final sprite = _sprites[spriteName];
        final maskSprite = _sprites[maskSpriteName];

        if (sprite != null) {
          frames.add(sprite);
        }

        if (maskSprite != null) {
          maskFrames.add(maskSprite);
        }
      }

      if (frames.isNotEmpty) {
        _legSpriteAnimList[dir] = frames;
      }

      if (maskFrames.isNotEmpty) {
        _legSpriteMaskAnimList[dir] = maskFrames;
      }
    }
  }

  List<TrimmedSprite> getLegSprites(String direction) {
    return _legSpriteAnimList[direction] ?? [];
  }

  List<TrimmedSprite> getLegMaskSprites(String direction) {
    return _legSpriteMaskAnimList[direction] ?? [];
  }

  TrimmedSprite? getTurretSprite() {
    return _sprites['turret_player_color.png'];
  }

  /// Получить спрайт по имени
  TrimmedSprite? getSprite(String name) {
    return _sprites[name];
  }

  /// Получить все спрайты по паттерну (регулярное выражение)
  List<TrimmedSprite> getSpritesByPattern(String pattern) {
    final regex = RegExp(pattern);
    return _sprites.entries
        .where((entry) => regex.hasMatch(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  bool get isLoaded => _loaded;
}
