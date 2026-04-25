// lib/components/health_bar_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HealthBarComponent extends PositionComponent {
  double health;
  double maxHealth;

  HealthBarComponent({
    required super.position,
    required this.health,
    required this.maxHealth,
  }) {
    width = 40;
    height = 6;
  }

  void updateHealth(double newHealth, double newMaxHealth) {
    health = newHealth;
    maxHealth = newMaxHealth;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final healthPercent = (health / maxHealth).clamp(0.0, 1.0);
    final healthColor = healthPercent >= 0.66
        ? Colors.green
        : healthPercent >= 0.33
        ? Colors.orange
        : Colors.red;

    // Фон
    canvas.drawRect(
      Rect.fromLTWH(-width / 2, 0, width, height),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Полоска здоровья
    canvas.drawRect(
      Rect.fromLTWH(-width / 2, 0, width * healthPercent, height),
      Paint()..color = healthColor,
    );

    // Рамка
    canvas.drawRect(
      Rect.fromLTWH(-width / 2, 0, width, height),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
