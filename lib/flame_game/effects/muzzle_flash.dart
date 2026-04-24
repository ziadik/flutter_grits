// lib/flame_game/effects/muzzle_flash.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

/// Компонент вспышки выстрела (muzzle flash)
class MuzzleFlash extends PositionComponent {
  final List<TrimmedSprite> _frames;
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration;
  bool _isPlaying = true;
  Sprite? _currentSprite;

  MuzzleFlash({
    required Vector2 position,
    required List<TrimmedSprite> frames,
    double frameDuration = 0.05,
    Vector2? size,
    double angle = 0,
  }) : _frames = frames,
       _frameDuration = frameDuration,
       super(
         position: position,
         size: size ?? Vector2(64, 64),
         anchor: Anchor.center,
       ) {
    this.angle = angle;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_frames.isNotEmpty) {
      await _updateSprite();
    }
  }

  Future<void> _updateSprite() async {
    if (_currentFrame >= _frames.length) return;

    final frame = _frames[_currentFrame];
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    frame.renderCentered(canvas, Vector2.zero(), Size(size.x, size.y), null);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    _currentSprite = Sprite(image);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _currentSprite?.render(canvas, position: Vector2.zero());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isPlaying) return;

    _frameTime += dt;
    if (_frameTime >= _frameDuration) {
      _frameTime = 0;
      _currentFrame++;

      if (_currentFrame >= _frames.length) {
        removeFromParent();
        return;
      }
      _updateSprite();
    }
  }
}

/// Простой muzzle flash без спрайтов (fallback)
class SimpleMuzzleFlash extends PositionComponent {
  double _lifeTime = 0.1;

  SimpleMuzzleFlash({required Vector2 position}) {
    this.position = position;
    size = Vector2(20, 20);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime -= dt;
    if (_lifeTime <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_lifeTime / 0.1).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      size.x / 2,
      Paint()
        ..color = Colors.yellow.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      size.x / 3,
      Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill,
    );
  }
}
