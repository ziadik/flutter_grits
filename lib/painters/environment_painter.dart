import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_grits/models/sprite_data.dart';
import 'package:flutter_grits/sprites/sprite_sheet.dart';

/// Painter для отрисовки объектов environment (спавнеры, точки спавна)
class EnvironmentPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final SpriteSheet? spriteSheet;
  final List<dynamic> objects;
  final bool showLabels;
  final bool showDebug;

  EnvironmentPainter({required this.imageInfo, required this.spriteSheet, required this.objects, this.showLabels = true, this.showDebug = false});

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      final x = (obj['x'] ?? 0).toDouble();
      final y = (obj['y'] ?? 0).toDouble();
      final width = (obj['width'] ?? 32).toDouble();
      final height = (obj['height'] ?? 32).toDouble();
      final name = (obj['name'] ?? '').toString();
      final type = (obj['type'] ?? '').toString();
      final properties = obj['properties'] as Map<String, dynamic>? ?? {};

      // Определяем спрайт для объекта
      String spriteName = '';
      if (type == 'Spawner') {
        final spawnItem = properties['SpawnItem']?.toString() ?? '';
        if (spawnItem.contains('QuadDamage')) {
          spriteName = 'powerup';
        } else if (spawnItem.contains('Energy')) {
          spriteName = 'energy';
        } else if (spawnItem.contains('Health')) {
          spriteName = 'health';
        }
      } else if (type == 'SpawnPoint') {
        spriteName = 'spawn';
      }

      SpriteData? sprite;
      if (spriteName.isNotEmpty && spriteSheet != null) {
        sprite = spriteSheet!.findSprite(spriteName);
      }

      // Рисуем объект
      if (sprite != null) {
        _drawSprite(canvas, sprite, x, y, width, height);
      } else {
        _drawFallback(canvas, name, type, x, y, width, height);
      }

      // Подпись объекта
      if (showLabels && name.isNotEmpty) {
        _drawLabel(canvas, name, x, y, width);
      }

      // Отладочная информация
      if (showDebug) {
        _drawDebugInfo(canvas, obj, x, y, width, height);
      }
    }
  }

  void _drawSprite(Canvas canvas, SpriteData sprite, double x, double y, double width, double height) {
    final srcRect = sprite.frame;
    final dstRect = Rect.fromLTWH(x, y, width, height);

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.drawImageRect(imageInfo.image, srcRect, dstRect, paint);
  }

  void _drawFallback(Canvas canvas, String name, String type, double x, double y, double width, double height) {
    Color color;
    if (type == 'Spawner') {
      if (name.contains('Quad')) {
        color = Colors.orange;
      } else if (name.contains('Energy')) {
        color = Colors.blue;
      } else if (name.contains('Health')) {
        color = Colors.green;
      } else {
        color = Colors.purple;
      }
    } else if (type == 'SpawnPoint') {
      color = name.contains('Team0') ? Colors.blue : Colors.red;
    } else {
      color = Colors.grey;
    }

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);

    // Иконка
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (type == 'Spawner') {
      canvas.drawCircle(Offset(x + width / 2, y + height / 2), math.min(width, height) / 3, iconPaint);
    } else if (type == 'SpawnPoint') {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + width / 2, y + height / 2), width: width * 0.6, height: height * 0.6), const Radius.circular(4)), iconPaint);
    }
  }

  void _drawLabel(Canvas canvas, String name, double x, double y, double width) {
    final text = name.length > 15 ? '${name.substring(0, 15)}...' : name;
    final span = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
      ),
    );

    final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

    tp.paint(canvas, Offset(x + width / 2 - tp.width / 2, y - tp.height - 2));
  }

  void _drawDebugInfo(Canvas canvas, dynamic obj, double x, double y, double width, double height) {
    const textStyle = TextStyle(fontSize: 9, color: Colors.black);

    final coordText = '(${x.toInt()}, ${y.toInt()})';
    final coordSpan = TextSpan(text: coordText, style: textStyle);
    final coordTp = TextPainter(text: coordSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr)..layout();

    coordTp.paint(canvas, Offset(x, y + height + 2));
  }

  @override
  bool shouldRepaint(covariant EnvironmentPainter oldDelegate) {
    return oldDelegate.objects != objects || oldDelegate.showLabels != showLabels || oldDelegate.showDebug != showDebug;
  }
}
