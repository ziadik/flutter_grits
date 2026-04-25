// lib/components/hud/fps_counter.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FpsCounterComponent extends PositionComponent {
  double _accumulatedTime = 0;
  int _frameCount = 0;
  double _currentFps = 0;

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 16,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
    ),
  );

  FpsCounterComponent({required super.position, required super.anchor}) {
    width = 100;
    height = 30;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _accumulatedTime += dt;
    _frameCount++;

    if (_accumulatedTime >= 1.0) {
      _currentFps = _frameCount / _accumulatedTime;
      _frameCount = 0;
      _accumulatedTime = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final fpsText = 'FPS: ${_currentFps.toStringAsFixed(1)}';
    _textPaint.render(canvas, fpsText, Vector2(0, 0));
  }
}
