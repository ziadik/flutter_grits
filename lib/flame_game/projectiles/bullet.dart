// lib/flame_game/projectiles/bullet.dart
import 'dart:ui' show Canvas, Offset, Paint;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';

/// Базовая пуля для MachineGun, ChainGun и других скорострельных оружий.
///
/// Характеристики из JS кода (SimpleProjectile):
/// - speed: 700-800
/// - lifetime: 1.5-2s
/// - damage: 5
class Bullet extends ProjectileBase {
  Bullet({
    required super.position,
    required super.owner,
    required super.direction,
    required super.damage,
    required super.speed,
    required super.lifetime,
    String? spritePattern,
  }) : super(spritePattern: spritePattern ?? 'machinegun_projectile_');

  @override
  void onCollision(Vector2 collisionPoint, PositionComponent other) {
    // Проверка, является ли объект целью
    if (!isTarget(other)) {
      return;
    }

    // Нанести урон игроку
    if (other is Player) {
      other.takeDamage(damage);
    }

    // Воспроизвести звук удара/взрыва
    SoundManager().playSfx(SoundAssets.bounce0);

    // Уничтожить пулю
    destroy();
  }

  @override
  void destroy() {
    // TODO: Добавить эффект исчезновения
    super.destroy();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Движение снаряда
    final moveVector = direction.normalized() * speed * dt;
    position += moveVector;

    debugPrint(
      '📍 Bullet update: pos=$position, dir=${direction.normalized()}, speed=$speed',
    );

    lifetime -= dt;
    if (lifetime <= 0) {
      debugPrint('💥 Bullet lifetime expired');
      destroy();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Рисуем пулю как красный круг для отладки
    canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFFFF0000));

    // Линия направления
    final dirOffset = Offset(direction.x * 15, direction.y * 15);
    canvas.drawLine(
      Offset.zero,
      dirOffset,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2,
    );
  }
}
