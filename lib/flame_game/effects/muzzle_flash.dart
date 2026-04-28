// lib/flame_game/effects/muzzle_flash.dart
import 'dart:ui' as ui;
import 'dart:math';
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
  double _rotationAngle = 0;

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
         size: size ?? Vector2(256, 256),
         anchor: Anchor.center,
       ) {
    // Сохраняем угол поворота
    _rotationAngle = angle;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (_frames.isNotEmpty) {
      await _updateSprite(0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_currentSprite != null) {
      canvas.save();

      // Перемещаемся в центр компонента
      canvas.translate(size.x / 2, size.y / 2);
      // Поворачиваем
      canvas.rotate(_rotationAngle);
      // Возвращаемся обратно и рисуем спрайт с учетом смещения
      canvas.translate(-size.x / 2, -size.y / 2);

      // Рисуем спрайт
      _currentSprite!.render(canvas, position: Vector2.zero());

      canvas.restore();
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
        removeFromParent();
        return;
      }
      _updateSprite(_currentFrame);
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
}

/// Простой muzzle flash без спрайтов (fallback)
class SimpleMuzzleFlash extends PositionComponent {
  double _lifeTime = 0.1;
  double _rotationAngle = 0;

  SimpleMuzzleFlash({required Vector2 position, double angle = 0}) {
    this.position = position;
    size = Vector2(24, 24);
    anchor = Anchor.center;
    _rotationAngle = angle;
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

    canvas.save();
    canvas.translate(0, 0);
    canvas.rotate(_rotationAngle);

    // Основной круг
    canvas.drawCircle(
      Offset.zero,
      size.x / 2,
      Paint()
        ..color = Colors.yellow.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.fill,
    );

    // Внутренний круг
    canvas.drawCircle(
      Offset.zero,
      size.x / 3,
      Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill,
    );

    // Лучи в направлении выстрела
    final rayPaint = Paint()
      ..color = Colors.orange.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(Offset.zero, Offset(size.x, 0), rayPaint);
    canvas.drawLine(Offset.zero, Offset(size.x * 0.6, -size.x * 0.3), rayPaint);
    canvas.drawLine(Offset.zero, Offset(size.x * 0.6, size.x * 0.3), rayPaint);

    canvas.restore();
  }
}
