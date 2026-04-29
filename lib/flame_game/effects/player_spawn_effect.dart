import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

/// Эффект появления игрока (спавн)
/// Показывает анимацию spawner_white_activate_ один раз при появлении игрока
class PlayerSpawnEffect extends PositionComponent {
  final PlayerAnimator animator;
  final GameWorld gameWorld;

  static const double lifetime =
      0.5; // 0.5 секунды как в JS (12 кадров при 60 FPS)
  static const double targetSize = 128.0; // Размер спрайта из JSON

  Sprite? _currentSprite;
  List<TrimmedSprite> _animationFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 1 / 30; // 30 FPS
  double _remainingLifetime = lifetime;

  PlayerSpawnEffect({
    required Vector2 position,
    required this.animator,
    required this.gameWorld,
  }) : super(position: position, anchor: Anchor.center) {
    size = Vector2(targetSize, targetSize);
    // Приоритет отрисовки: выше стен (0), но ниже или на уровне игрока (10)
    priority = 5;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimation();

    // Добавляем эффект в мир
    gameWorld.add(this);
    debugPrint('🎉 PlayerSpawnEffect created at $position');
  }

  Future<void> _loadAnimation() async {
    // Загружаем кадры анимации spawner_white_activate_
    for (int i = 0; i <= 15; i++) {
      final frameName =
          'spawner_white_activate_${i.toString().padLeft(4, '0')}.png';
      final sprite = animator.getSprite(frameName);
      if (sprite != null) {
        _animationFrames.add(sprite);
      }
    }

    if (_animationFrames.isNotEmpty) {
      await _updateSprite(0);
      debugPrint(
        '✅ PlayerSpawnEffect: Loaded ${_animationFrames.length} frames',
      );
    } else {
      debugPrint(
        '⚠️ PlayerSpawnEffect: No frames found for spawner_white_activate_',
      );
    }
  }

  Future<void> _updateSprite(int frameIndex) async {
    if (frameIndex >= _animationFrames.length) return;

    final frame = _animationFrames[frameIndex];
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    frame.renderCentered(canvas, Vector2.zero(), Size(size.x, size.y), null);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    _currentSprite = Sprite(image);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Уменьшаем время жизни
    _remainingLifetime -= dt;
    if (_remainingLifetime <= 0) {
      removeFromParent();
      return;
    }

    // Анимация кадров
    if (_animationFrames.isNotEmpty) {
      _frameTime += dt;
      if (_frameTime >= _frameDuration) {
        _frameTime = 0;
        _currentFrame = (_currentFrame + 1) % _animationFrames.length;
        _updateSprite(_currentFrame);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_currentSprite != null) {
      canvas.save();
      // Рисуем спрайт по центру
      _currentSprite!.render(
        canvas,
        position: Vector2(-size.x / 2, -size.y / 2),
      );
      canvas.restore();
    }
  }

  /// Метод для внешнего вызова - создать эффект спавна
  static void spawn({
    required Vector2 position,
    required PlayerAnimator animator,
    required GameWorld gameWorld,
  }) {
    final effect = PlayerSpawnEffect(
      position: position,
      animator: animator,
      gameWorld: gameWorld,
    );
    // Эффект добавится в мир через onLoad()
  }
}
