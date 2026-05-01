// lib/flame_game/weapons/railgun.dart
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';

import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';

/// Railgun (Электромагнитная пушка)
///
/// Мощное оружие с мгновенным лучом. Пробивает цели насквозь.
///
/// Характеристики:
/// - itemID: "railgun"
/// - energyCost: 15
/// - fireDelayInSeconds: 1.5 (медленная перезарядка)
/// - damage: 50
/// - beam lifetime: 0.1s (очень короткий луч)
class Railgun extends WeaponBase {
  @override
  String get itemID => "railgun";

  @override
  String get displayName => "Railgun";

  @override
  double get energyCost => 15;

  @override
  double get fireDelayInSeconds => 1.5;

  @override
  double get damage => 50;

  @override
  String get weaponSpriteName => 'railgun.png';

  @override
  String get projectileSpritePattern => 'railgun_projectile_';

  @override
  String get muzzleSpritePattern => 'railgun_muzzle_';

  @override
  String get impactSpritePattern => 'railgun_impact_';

  @override
  void onFire(Player player) {
    // Получить направление стрельбы
    final direction = getFireDirection(player);

    // Получить позицию спавна пули
    final spawnPos = getBulletSpawnOffset(player, 20);

    // Создать пулю
    final bullet = Bullet(
      gameWorld: player.gameWorld,
      position: spawnPos,
      owner: player,
      direction: direction,
      damage: damage,
      speed: 900,
      lifetime: 1.5,
      spritePattern: projectileSpritePattern,
    );

    // Добавить пулю в игровой мир
    addProjectileToWorld(bullet);

    // Создать muzzle flash для chain gun (позиция дула: x=35, y=-3)
    createMuzzleFlash(player, Vector2(32, 32));

    // Воспроизвести звук выстрела
    SoundManager().playShootSound(SoundAssets.machineShoot0);
  }
}
