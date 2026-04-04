import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_grits/models/sprite_data.dart';
import 'package:flutter_grits/player/player_animator.dart';

/// Painter для отрисовки игрока с анимацией
class PlayerPainter extends CustomPainter {
  final PlayerAnimator animator;
  final ImageInfo effectsImageInfo;
  final int direction;
  final bool walking;
  final double animationValue;
  final double angle;
  final int team;
  final String name;
  final double health;
  final double maxHealth;
  final double energy;
  final double maxEnergy;
  final bool isLocalPlayer;

  static const double _spriteScale = 1.0; // Уменьшено с 2.0 до 1.0

  const PlayerPainter({
    required this.animator,
    required this.effectsImageInfo,
    required this.direction,
    required this.walking,
    required this.animationValue,
    required this.angle,
    required this.team,
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.energy,
    required this.maxEnergy,
    required this.isLocalPlayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final directionName = _getDirectionName();

    // Приводим animationValue к double и убеждаемся что оно в диапазоне [0, 1]
    final animValue = animationValue.clamp(0.0, 1.0);

    // Получаем текущий кадр анимации
    final legSprite = walking
        ? animator.getLegSprite(directionName, animValue)
        : animator.getLegSprite(directionName, 0.0);

    final legMaskSprite = walking
        ? animator.getLegMaskSprite(directionName, animValue)
        : animator.getLegMaskSprite(directionName, 0.0);

    final turretSprite = animator.getTurretSprite();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    // Рисуем ноги с маской
    if (legMaskSprite != null) {
      _drawLegMask(canvas, legMaskSprite);
    }

    // Рисуем ноги
    if (legSprite != null) {
      _drawLegs(canvas, legSprite);
    } else {
      _drawDefaultLegs(canvas);
    }

    // Рисуем туловище
    _drawTorso(canvas);

    // Рисуем маску команды
    _drawTeamMask(canvas);

    // Рисуем пушку
    _drawTurret(canvas, turretSprite);

    canvas.restore();

    // Рисуем полоски здоровья и энергии или имя
    if (isLocalPlayer) {
      _drawHealthBar(canvas, size);
      _drawEnergyBar(canvas, size);
    } else {
      _drawNameTag(canvas, size);
    }
  }

  String _getDirectionName() {
    switch (direction) {
      case 0:
        return 'up';
      case 1:
        return 'left';
      case 2:
        return 'down';
      case 3:
        return 'right';
      default:
        return 'down';
    }
  }

  void _drawLegMask(Canvas canvas, SpriteData sprite) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..color = _getTeamColor().withOpacity(0.6)
      ..blendMode = BlendMode.multiply;

    _drawSprite(canvas, sprite, paint);
  }

  void _drawLegs(Canvas canvas, SpriteData sprite) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    _drawSprite(canvas, sprite, paint);
  }

  void _drawSprite(Canvas canvas, SpriteData sprite, Paint paint) {
    final srcRect = sprite.frame;
    final dstWidth = srcRect.width * _spriteScale;
    final dstHeight = srcRect.height * _spriteScale;
    final dstRect = Rect.fromCenter(
      center: Offset.zero,
      width: dstWidth,
      height: dstHeight,
    );

    canvas.drawImageRect(effectsImageInfo.image, srcRect, dstRect, paint);
  }

  void _drawDefaultLegs(Canvas canvas) {
    final legPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Уменьшено с 15 до 8, радиус с 12 до 6
    canvas.drawOval(
      Rect.fromCircle(center: const Offset(-8, 0), radius: 6),
      legPaint,
    );
    canvas.drawOval(
      Rect.fromCircle(center: const Offset(8, 0), radius: 6),
      legPaint,
    );
  }

  void _drawTorso(Canvas canvas) {
    final torsoPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    // Уменьшено с 25 до 12
    canvas.drawCircle(Offset.zero, 12, torsoPaint);

    final borderPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // Уменьшено с 2 до 1

    canvas.drawCircle(Offset.zero, 12, borderPaint);
  }

  Color _getTeamColor() {
    const teamColors = [
      Color(0xFF33FF33), // Зеленый для команды 0
      Color(0xFFFF9933), // Оранжевый для команды 1
    ];
    return team < teamColors.length ? teamColors[team] : Colors.blue;
  }

  void _drawTeamMask(Canvas canvas) {
    final maskPaint = Paint()
      ..color = _getTeamColor().withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.multiply;

    // Уменьшено с 22 до 10
    canvas.drawCircle(Offset.zero, 10, maskPaint);
  }

  void _drawTurret(Canvas canvas, SpriteData? turretSprite) {
    canvas.save();
    canvas.rotate(angle + math.pi); // +180 градусов

    if (turretSprite != null) {
      final paint = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;

      _drawSprite(canvas, turretSprite, paint);
    } else {
      final turretPaint = Paint()
        ..color = Colors.grey[700]!
        ..style = PaintingStyle.fill;

      // Уменьшено с 40x15 до 20x8
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 8),
        turretPaint,
      );

      final barrelPaint = Paint()
        ..color = Colors.grey[900]!
        ..style = PaintingStyle.fill;

      // Уменьшено с 20x8 до 10x4
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(10, 0), width: 10, height: 4),
        barrelPaint,
      );
    }

    canvas.restore();
  }

  void _drawHealthBar(Canvas canvas, Size size) {
    final healthPercent = (health / maxHealth).clamp(0.0, 1.0);
    final healthColor = healthPercent >= 0.66
        ? Colors.green
        : healthPercent >= 0.33
        ? Colors.orange
        : Colors.red;

    _drawBar(canvas, size, healthPercent, healthColor, -20);
  }

  void _drawEnergyBar(Canvas canvas, Size size) {
    final energyPercent = (energy / maxEnergy).clamp(0.0, 1.0);
    final energyColor = energyPercent >= 0.66
        ? Colors.lightBlue
        : energyPercent >= 0.33
        ? Colors.blue
        : Colors.blue[900]!;

    _drawBar(canvas, size, energyPercent, energyColor, -14);
  }

  void _drawBar(
    Canvas canvas,
    Size size,
    double percent,
    Color color,
    double yOffset,
  ) {
    const barWidth = 30.0; // Уменьшено с 60 до 30
    const barHeight = 5.0; // Уменьшено с 10 до 5
    final x = -barWidth / 2;
    final y = -size.height / 2 + yOffset;

    // Фон
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), bgPaint);

    // Полоска
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(x, y, barWidth * percent, barHeight),
      barPaint,
    );

    // Рамка
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // Уменьшено с 2 до 1

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), borderPaint);
  }

  void _drawNameTag(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      fontSize: 10, // Уменьшено с 18 до 10
      fontWeight: FontWeight.bold,
      color: Colors.green,
    );

    const shadowStyle = TextStyle(
      fontSize: 10, // Уменьшено с 18 до 10
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final x = -25.0; // Уменьшено с -50 до -25
    final y = -size.height / 2 - 20;

    final textPainter = TextPainter(
      text: TextSpan(text: name, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final shadowPainter = TextPainter(
      text: TextSpan(text: name, style: shadowStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    shadowPainter.paint(canvas, Offset(x + 1, y + 1));
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant PlayerPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.walking != walking ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.angle != angle ||
        oldDelegate.health != health ||
        oldDelegate.energy != energy;
  }
}
