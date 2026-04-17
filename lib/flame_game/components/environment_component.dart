// lib/components/environment_component.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum EnvironmentType { spawner, spawnPoint, pickup }

class EnvironmentComponent extends PositionComponent {
  final EnvironmentType type;
  final String name;
  final Map<String, dynamic> properties;
  final Image? effectsImage;

  EnvironmentComponent({
    required super.position,
    required super.size,
    required this.type,
    required this.name,
    required this.properties,
    this.effectsImage,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    Color color;
    String label = name;

    switch (type) {
      case EnvironmentType.spawner:
        final spawnItem = properties['SpawnItem']?.toString() ?? '';
        if (spawnItem.contains('QuadDamage')) {
          color = Colors.orange;
          label = '⚡ Quad';
        } else if (spawnItem.contains('Energy')) {
          color = Colors.blue;
          label = '🔋 Energy';
        } else if (spawnItem.contains('Health')) {
          color = Colors.green;
          label = '❤️ Health';
        } else {
          color = Colors.purple;
          label = '📦 Spawner';
        }
        break;
      case EnvironmentType.spawnPoint:
        color = name.contains('Team0') ? Colors.blue : Colors.red;
        label = '🏃 Spawn';
        break;
      case EnvironmentType.pickup:
        color = Colors.yellow;
        label = '✨ Pickup';
        break;
    }

    // Отрисовка области
    final rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.5));
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Отрисовка иконки
    final center = Offset(width / 2, height / 2);
    canvas.drawCircle(
      center,
      math.min(width, height) / 4,
      Paint()..color = Colors.white,
    );

    // Отрисовка подписи
    _drawLabel(canvas, label);
  }

  void _drawLabel(Canvas canvas, String label) {
    final span = TextSpan(
      text: label,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
      ),
    );

    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(width / 2 - tp.width / 2, -tp.height - 2));
  }
}
