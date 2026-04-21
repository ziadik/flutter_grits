// lib/flame_game/effects/muzzle_flash.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

/// Компонент вспышки выстрела (muzzle flash)
class MuzzleFlash extends SpriteComponent {
  final List<TrimmedSprite> _frames;
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration;
  bool _isPlaying = true;

  MuzzleFlash({
    required Vector2 position,
    required List<TrimmedSprite> frames,
    double frameDuration = 0.05, // 50ms per frame
    Vector2? size,
  })  : _frames = frames,
        _frameDuration = frameDuration,
        super(
          position: position,
          size: size ?? Vector2(64, 64),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_frames.isNotEmpty) {
      _updateSprite();
    }
  }

  void _updateSprite() {
    if (_currentFrame < _frames.length) {
      final frame = _frames[_currentFrame];
      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder);
      frame.renderCentered(
        canvas,
        Vector2.zero(),
        Size(size.x, size.y),
        null,
      );
      final picture = pictureRecorder.endRecording();
      picture.toImage(size.x.toInt(), size.y.toInt()).then((img) {
        sprite = Sprite(img);
      });
    }
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
        // Анимация завершена, удаляем компонент
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
