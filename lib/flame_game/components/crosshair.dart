// lib/flame_game/components/crosshair.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CrosshairComponent extends PositionComponent {
  CrosshairComponent() {
    size = Vector2(32, 32);
    anchor = Anchor.center;
  }

  void updatePosition(Vector2 screenPos) {
    position = screenPos;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset.zero;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Внешний круг
    canvas.drawCircle(center, 12, paint);

    // Перекрестие
    canvas.drawLine(Offset(-20, 0), Offset(-14, 0), paint);
    canvas.drawLine(Offset(14, 0), Offset(20, 0), paint);
    canvas.drawLine(Offset(0, -20), Offset(0, -14), paint);
    canvas.drawLine(Offset(0, 14), Offset(0, 20), paint);

    // Центральная точка
    canvas.drawCircle(center, 3, Paint()..color = Colors.red);

    // Внутренний круг
    canvas.drawCircle(center, 6, paint);
  }
}
