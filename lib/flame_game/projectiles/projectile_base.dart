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

  // Ссылка на хитбокс для обновления размера (ShapeHitbox - базовый класс для всех форм)
  ShapeHitbox? hitbox;

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

    debugPrint('🔫 ProjectileBase onLoad: initial size=${size.x}x${size.y}');
    // Хитбокс будет создан в Bullet._loadAnimation() с правильным размером
  }

  /// Создать хитбокс с правильным размером (вызывается после загрузки спрайта)
  void createHitbox(Vector2 hitboxSize) {
    if (hitbox != null) return; // Уже создан

    // ✅ Делаем круглый хитбокс с радиусом в 2 раза меньше размера спрайта
    final radius =
        (hitboxSize.x > hitboxSize.y ? hitboxSize.y : hitboxSize.x) / 4;

    hitbox = CircleHitbox(radius: radius, anchor: Anchor.center)
      ..isSolid = true;

    hitbox!.collisionType = CollisionType.passive;
    add(hitbox!);

    debugPrint('🔫 ProjectileBase hitbox created: CircleHitbox radius=$radius');
    debugPrint('   Component size: ${size.x}x${size.y}');
  }

  /// Обновить размер хитбокса (вызывается после загрузки спрайта)
  void updateHitboxSize(Vector2 newSize) {
    if (hitbox != null) {
      hitbox!.size = newSize;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    debugPrint('🔥 COLLISION: Bullet ↔ ${other.runtimeType}');

    // ✅ Игнорируем столкновение с игроком-владельцем (чтобы не попасть в себя)
    if (other is Player && other == owner) {
      debugPrint('   ⚠️ Bullet hit owner - ignoring');
      return;
    }

    // ✅ Игнорируем столкновение с другими пулями (хотя passive уже должно это обрабатывать)
    if (other is ProjectileBase) {
      debugPrint('   ⚠️ Bullet hit another bullet - ignoring');
      return;
    }

    // ✅ Обрабатываем столкновение со стенами и другими объектами
    debugPrint('   ✅ Bullet hit ${other.runtimeType} - destroying');
    destroy();
  }
}
