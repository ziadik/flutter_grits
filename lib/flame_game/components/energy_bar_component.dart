// lib/components/energy_bar_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnergyBarComponent extends PositionComponent {
  double energy;
  double maxEnergy;

  EnergyBarComponent({
    required super.position,
    required this.energy,
    required this.maxEnergy,
  }) {
    width = 40;
    height = 6;
  }

  void updateEnergy(double newEnergy, double newMaxEnergy) {
    energy = newEnergy;
    maxEnergy = newMaxEnergy;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final energyPercent = (energy / maxEnergy).clamp(0.0, 1.0);
    final energyColor = energyPercent >= 0.66
        ? Colors.lightBlue
        : energyPercent >= 0.33
        ? Colors.blue
        : Colors.blue[900]!;

    // Фон
    canvas.drawRect(
      Rect.fromLTWH(-width / 2, 0, width, height),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Полоска энергии
    canvas.drawRect(
      Rect.fromLTWH(-width / 2, 0, width * energyPercent, height),
      Paint()..color = energyColor,
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
