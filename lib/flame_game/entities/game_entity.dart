// lib/flame_game/entities/game_entity.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

/// Базовый класс для всех игровых объектов (аналог EntityClass из JS)
abstract class GameEntity extends PositionComponent
    with HasCollisionDetection, CollisionCallbacks {
  final GameWorld gameWorld;
  String entityName = '';
  bool _isKilled = false;

  GameEntity({
    required Vector2 position,
    required this.gameWorld,
    Vector2? size,
  }) : super(position: position) {
    this.size = size ?? Vector2(32, 32);
    anchor = Anchor.center;
  }

  bool get isKilled => _isKilled;

  void kill() {
    if (_isKilled) return;
    _isKilled = true;
    onKill();
    removeFromParent();
  }

  void onKill() {}
  void onInit() async {}
  void onUpdate(double dt) {}
  void onTouch(PositionComponent other, Vector2 point, Vector2 impulse) {}

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Добавляем хитбокс для коллизий с игроком
    add(
      RectangleHitbox(
        position: Vector2.zero(),
        anchor: Anchor.center,
        size: size,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isKilled) {
      onUpdate(dt);
    }
  }
}
