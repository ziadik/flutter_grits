// lib/flame_game/weapons/machine_gun.dart
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';

/// Машинное оружие (Machine Gun)
///
/// Стандартное оружие игрока. Баланс между скорострельностью и расходом энергии.
///
/// Характеристики из JS кода:
/// - itemID: "1234"
/// - energyCost: 2
/// - fireDelayInSeconds: 0.1 (10 выстрелов в секунду)
/// - damage: 5
/// - speed: 700
/// - lifetime: 2s
class MachineGun extends WeaponBase {
  @override
  String get itemID => "1234";

  @override
  String get displayName => "MG ";

  @override
  double get energyCost => 2;

  @override
  double get fireDelayInSeconds => 0.1;

  @override
  double get damage => 5;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'machinegun.png';

  @override
  String get projectileSpritePattern => 'machinegun_projectile_';

  @override
  String get muzzleSpritePattern => 'machinegun_muzzle_';

  @override
  String get impactSpritePattern => 'machinegun_impact_';

  @override
  void onFire(Player player) {
    // debugPrint('🔫 MachineGun firing!');
    // debugPrint('   Player position: ${player.position}');
    // debugPrint('   Face angle: ${player.faceAngleRadians}');

    // Получить направление стрельбы
    final direction = getFireDirection(player);
    // debugPrint('   Fire direction: $direction');
    // debugPrint('   Muzzle pattern: $muzzleSpritePattern');

    // Получить позицию спавна пули (смещение на 50px вперед - дальше от игрока)
    final spawnPos = getBulletSpawnOffset(player, 50);
    // debugPrint('   Spawn position: $spawnPos');

    // Создать пулю
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

    // Добавить пулю в игровой мир
    addProjectileToWorld(bullet);

    // Создать muzzle flash (позиция дула: x=38, y=-4)
    createMuzzleFlash(player, Vector2(38, -4));

    // Воспроизвести звук выстрела
    SoundManager().playShootSound(SoundAssets.machineShoot0);
  }
}
