import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Базовый класс для всех снарядов
abstract class ProjectileBase extends PositionComponent
    with CollisionCallbacks {
  final Player owner;
  final Vector2 direction;
  final double damage;
  final double speed;
  double lifetime;
  final String spritePattern;

  ProjectileBase({
    required super.position,
    required this.owner,
    required this.direction,
    required this.damage,
    required this.speed,
    required this.lifetime,
    this.spritePattern = 'machinegun_projectile_',
  }) : super(size: Vector2(8, 8), anchor: Anchor.center);

  /// Уничтожить снаряд
  void destroy();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Добавляем хитбокс с CollisionType.passive
    // Пули не будут сталкиваться друг с другом, но будут попадать в игроков и объекты
    final hitbox = RectangleHitbox(
      position: Vector2.zero(),
      anchor: Anchor.center,
      size: size,
    );

    // ✅ КЛЮЧЕВОЙ МОМЕНТ: passive collisionType
    // passive пули сталкиваются только с active объектами (игроки, враги),
    // но не с другими passive пулями
    hitbox.collisionType = CollisionType.passive;

    add(hitbox);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    debugPrint('🔥 COLLISION: Bullet ↔ ${other.runtimeType}');

    // Пуля уничтожается при попадании в любой объект
    destroy();
  }
}
