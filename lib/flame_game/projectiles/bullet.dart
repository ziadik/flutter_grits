// lib/flame_game/projectiles/bullet.dart
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';

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
}
