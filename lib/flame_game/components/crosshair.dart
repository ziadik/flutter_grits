// lib/flame_game/components/crosshair.dart

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CrosshairComponent extends PositionComponent {
  CrosshairComponent() {
    size = Vector2(32, 32);
    anchor = Anchor.center;
    position = Vector2(400, 400);
    // debugPrint('🎯 Crosshair created at position: $position');
  }

  void updatePosition(Vector2 screenPos) {
    position = screenPos;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset.zero;

    // Внешний круг (белый)
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 12, outerPaint);

    // Перекрестие (белое)
    canvas.drawLine(Offset(-20, 0), Offset(-14, 0), outerPaint);
    canvas.drawLine(Offset(14, 0), Offset(20, 0), outerPaint);
    canvas.drawLine(Offset(0, -20), Offset(0, -14), outerPaint);
    canvas.drawLine(Offset(0, 14), Offset(0, 20), outerPaint);

    // Центральная точка (красная)
    canvas.drawCircle(center, 3, Paint()..color = Colors.red);

    // Внутренний круг (белый)
    canvas.drawCircle(center, 6, outerPaint);

    // Добавляем тень для лучшей видимости на любом фоне
    final shadowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 12, shadowPaint);
  }
}
