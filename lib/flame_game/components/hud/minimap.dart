// lib/components/hud/minimap.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

class MinimapComponent extends PositionComponent {
  final GameWorld world;
  final CameraComponent camera;

  MinimapComponent({
    required super.position,
    required super.size,
    required this.world,
    required this.camera,
  }) {
    anchor = Anchor.bottomLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Фон мини-карты
    final backgroundRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      backgroundRect,
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    // Рамка
    canvas.drawRect(
      backgroundRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Отрисовка игрока на мини-карте
    _drawPlayerOnMinimap(canvas);

    // Отрисовка камеры (область видимости)
    _drawCameraView(canvas);
  }

  void _drawPlayerOnMinimap(Canvas canvas) {
    if (world.player == null) return;

    final playerPos = world.player!.position;
    final mapSize = Vector2(
      world.mapWidth.toDouble(),
      world.mapHeight.toDouble(),
    );

    // Масштабируем позицию на мини-карту
    final scaledX = (playerPos.x / mapSize.x) * size.x;
    final scaledY = (playerPos.y / mapSize.y) * size.y;

    canvas.drawCircle(
      Offset(scaledX, scaledY),
      4,
      Paint()..color = Colors.green,
    );
  }

  void _drawCameraView(Canvas canvas) {
    final visibleRect = camera.visibleWorldRect;
    final mapSize = Vector2(
      world.mapWidth.toDouble(),
      world.mapHeight.toDouble(),
    );

    // Масштабируем область видимости
    final scaledRect = Rect.fromLTWH(
      (visibleRect.left / mapSize.x) * size.x,
      (visibleRect.top / mapSize.y) * size.y,
      (visibleRect.width / mapSize.x) * size.x,
      (visibleRect.height / mapSize.y) * size.y,
    );

    canvas.drawRect(
      scaledRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
