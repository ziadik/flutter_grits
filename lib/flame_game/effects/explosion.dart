import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

/// Эффект взрыва при попадании снаряда
class ExplosionEffect extends PositionComponent {
  final PlayerAnimator animator;
  List<TrimmedSprite> _frames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.05;
  Sprite? _currentSprite;

  ExplosionEffect({
    required Vector2 position,
    required this.animator,
    Vector2? size,
  }) : super(position: position) {
    this.size = size ?? Vector2(64, 64);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    // Загружаем анимацию взрыва
    for (int i = 0; i <= 29; i++) {
      final frameName =
          'landmine_explosion_large_${i.toString().padLeft(4, '0')}.png';
      final sprite = animator.getSprite(frameName);
      if (sprite != null) {
        _frames.add(sprite);
      }
    }

    if (_frames.isNotEmpty) {
      await _updateSprite(0);
    }
  }

  Future<void> _updateSprite(int frameIndex) async {
    if (frameIndex >= _frames.length) return;

    final frame = _frames[frameIndex];
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

    _frameTime += dt;
    if (_frameTime >= _frameDuration) {
      _frameTime = 0;
      _currentFrame++;

      if (_currentFrame >= _frames.length) {
        removeFromParent();
        return;
      }
      _updateSprite(_currentFrame);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_currentSprite != null) {
      // anchor: Anchor.center уже центрирует компонент,
      // поэтому рисуем спрайт в (0, 0) относительно центра компонента
      _currentSprite!.render(canvas, position: Vector2.zero());
    }
  }
}
