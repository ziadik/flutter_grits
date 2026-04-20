// lib/flame_game/components/debug/collision_debug_overlay.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

/// Отладочный оверлей для визуализации коллизий
class CollisionDebugOverlay extends PositionComponent {
  final GameWorld gameWorld;
  final bool showPlayerBounds;
  final bool showCollisionTiles;
  final bool showInteractiveItems;

  CollisionDebugOverlay({
    required this.gameWorld,
    this.showPlayerBounds = true,
    this.showCollisionTiles = false,
    this.showInteractiveItems = true,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(
      gameWorld.mapWidth.toDouble(),
      gameWorld.mapHeight.toDouble(),
    );
    position = Vector2.zero();
    anchor = Anchor.topLeft;
    priority = 1000; // Высокий приоритет для отрисовки поверх всего
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (showCollisionTiles) {
      _renderCollisionTiles(canvas);
    }

    if (showInteractiveItems) {
      _renderInteractiveItems(canvas);
    }

    if (showPlayerBounds && gameWorld.player.isLoaded) {
      _renderPlayerBounds(canvas);
    }
  }

  /// Отрисовка границ игрока
  void _renderPlayerBounds(Canvas canvas) {
    final player = gameWorld.player;
    final halfSize = 32.0;

    // Основной прямоугольник игрока
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(
        player.position.x - halfSize,
        player.position.y - halfSize,
        64.0,
        64.0,
      ),
      paint,
    );

    // 4 угла проверки
    final cornerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final corners = [
      Vector2(player.position.x - halfSize, player.position.y - halfSize),
      Vector2(player.position.x + halfSize, player.position.y - halfSize),
      Vector2(player.position.x - halfSize, player.position.y + halfSize),
      Vector2(player.position.x + halfSize, player.position.y + halfSize),
    ];

    for (final corner in corners) {
      canvas.drawCircle(Offset(corner.x, corner.y), 4.0, cornerPaint);
    }

    // Точка центра игрока
    canvas.drawCircle(
      Offset(player.position.x, player.position.y),
      6.0,
      Paint()..color = Colors.yellow,
    );
  }

  /// Отрисовка тайлов коллизий
  void _renderCollisionTiles(Canvas canvas) {
    if (gameWorld.collisionTiles.isEmpty) return;

    final collisionMap = gameWorld.collisionTiles['collision'];
    if (collisionMap == null || collisionMap.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const tileSize = 64.0;

    // Проходим по всем тайлам
    for (var x = 0; x < collisionMap.length; x++) {
      for (var y = 0; y < collisionMap[x].length; y++) {
        if (collisionMap[x][y]) {
          // Этот тайл — коллизия
          final rect = Rect.fromLTWH(
            x * tileSize,
            y * tileSize,
            tileSize,
            tileSize,
          );
          canvas.drawRect(rect, paint);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }

    // Статистика
    var collisionCount = 0;
    for (var x = 0; x < collisionMap.length; x++) {
      for (var y = 0; y < collisionMap[x].length; y++) {
        if (collisionMap[x][y]) collisionCount++;
      }
    }

    // Рисуем текст статистики
    final textPainter = TextPainter(
      text: TextSpan(
        text:
            'Коллизий: $collisionCount/${collisionMap.length * collisionMap[0].length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));
  }

  /// Отрисовка интерактивных предметов
  void _renderInteractiveItems(Canvas canvas) {
    // Проходим по всем спавнерам
    for (final spawner in gameWorld.spawners) {
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(spawner.position.x, spawner.position.y),
          width: spawner.size.x,
          height: spawner.size.y,
        ),
        paint,
      );

      // Имя предмета
      final textPainter = TextPainter(
        text: TextSpan(
          text: spawner.name,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          spawner.position.x - textPainter.width / 2,
          spawner.position.y - spawner.size.y / 2 - 20,
        ),
      );
    }
  }
}
