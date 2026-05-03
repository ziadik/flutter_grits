import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Кнопка настроек в HUD
class SettingsButtonComponent extends PositionComponent with TapCallbacks {
  final VoidCallback? onSettingsRequested;
  bool _isPressed = false;

  SettingsButtonComponent({this.onSettingsRequested, required Vector2 position})
    : super(position: position, size: Vector2(40, 40), anchor: Anchor.topRight);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Фон кнопки
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size.x / 2, bgPaint);

    // Рамка
    final borderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, size.x / 2, borderPaint);

    // Иконка шестеренки
    final gearPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, size.x / 3, gearPaint);

    // Зубцы шестеренки
    for (int i = 0; i < 8; i++) {
      final angle = i * 45 * pi / 180;
      final start = Offset(
        cos(angle) * size.x / 3.5,
        sin(angle) * size.x / 3.5,
      );
      final end = Offset(cos(angle) * size.x / 2.5, sin(angle) * size.x / 2.5);
      canvas.drawLine(start, end, gearPaint);
    }

    // Эффект нажатия
    if (_isPressed) {
      final pressPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, size.x / 2, pressPaint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('press _settingsButton');
    _isPressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isPressed = false;

    // Запрашиваем показ диалога через callback
    onSettingsRequested?.call();
  }
}
