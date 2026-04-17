// lib/models/player_animator.dart (переименуйте файл или исправьте импорты)
import 'dart:ui';
import 'package:flame/sprite.dart';
import 'package:vector_math/vector_math.dart';

/// Класс для анимации игрока - загрузка и управление спрайтами анимации
class PlayerAnimator {
  final Map<String, List<Sprite>> _legSpriteAnimList = {};
  final Map<String, List<Sprite>> _legSpriteMaskAnimList = {};
  final Map<String, Sprite> _sprites = {};
  bool _loaded = false;
  late Image _effectsImage;

  /// Загружает изображение для спрайтов
  void loadImages(Image effectsImage) {
    _effectsImage = effectsImage;
  }

  /// Загружает данные анимации из JSON
  void loadFromJson(Map<String, dynamic> effectsJson) {
    if (_loaded) return;

    final frames = effectsJson['frames'] as Map<String, dynamic>;

    // Загружаем все спрайты
    frames.forEach((key, value) {
      final frame = value['frame'] as Map<String, dynamic>;

      _sprites[key] = Sprite(
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
    });

    // Инициализируем анимации ног
    _initLegAnimations();
    _loaded = true;
  }

  void _initLegAnimations() {
    final directions = ['up', 'left', 'down', 'right'];

    for (final dir in directions) {
      final frames = <Sprite>[];
      final maskFrames = <Sprite>[];

      // Загружаем кадры для анимации (30 кадров)
      for (int i = 0; i < 30; i++) {
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

  /// Получает список спрайтов ног для направления
  List<Sprite> getLegSprites(String direction) {
    return _legSpriteAnimList[direction] ?? [];
  }

  /// Получает список спрайтов маски ног для направления
  List<Sprite> getLegMaskSprites(String direction) {
    return _legSpriteMaskAnimList[direction] ?? [];
  }

  /// Получает спрайт турели
  Sprite? getTurretSprite() {
    return _sprites['turret_player_color.png'];
  }

  bool get isLoaded => _loaded;
}
