// lib/flame_game/weapons/shot_gun.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:vector_math/vector_math.dart';

/// Дробовик (ShotGun)
///
/// Мощное оружие ближнего боя. Стреляет 5 дробинок с разбросом.
///
/// Характеристики из JS кода:
/// - itemID: "8234"
/// - energyCost: 4
/// - fireDelayInSeconds: 0.25
/// - damage: 10 (на дробинку)
/// - speed: 700
/// - lifetime: 2s
class ShotGun extends WeaponBase {
  @override
  String get itemID => "8234";

  @override
  String get displayName => "ShotGun";

  @override
  double get energyCost => 4;

  @override
  double get fireDelayInSeconds => 0.25;

  @override
  double get damage => 10;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'shotgun.png';

  @override
  String get projectileSpritePattern => 'shotgun_projectile_';

  @override
  String get muzzleSpritePattern => 'shotgun_muzzle_';

  @override
  String get impactSpritePattern => 'shotgun_impact_';

  @override
  void onFire(Player player) {
    const numBullets = 5;
    const spread = 2.0 / numBullets; // Разброс ±1 радиан

    // Добавляем все дробинки в мир
    for (int i = 0; i < numBullets; i++) {
      // Вычисляем угол с разбросом
      final offset = (spread * (i + 1)) - 1; // От -1 до +1 радиан

      final baseDirection = getFireDirection(player);
      final direction = _rotateVector(baseDirection, offset);

      final spawnPos = getBulletSpawnOffset(player, 20);

      final bullet = Bullet(
        gameWorld: player.gameWorld,
        position: spawnPos,
        owner: player,
        direction: direction,
        damage: damage,
        speed: 700,
        lifetime: 2.0,
        spritePattern: projectileSpritePattern,
      );

      addProjectileToWorld(bullet);
    }

    // Создаем muzzle flash для дробовика (позиция дула: x=38, y=-4)
    createMuzzleFlash(player, Vector2(38, -4));

    // Воспроизводим звук выстрела
    SoundManager().playShootSound(SoundAssets.shotgunShoot0);
  }

  // Вспомогательный метод для вращения вектора
  Vector2 _rotateVector(Vector2 v, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Vector2(v.x * cosA - v.y * sinA, v.x * sinA + v.y * cosA);
  }
}
