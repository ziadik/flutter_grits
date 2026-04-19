// lib/flame_game/weapons/chain_gun.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Пулемет (ChainGun)
///
/// Скорострельное оружие с низким расходом энергии. Идеально для подавления.
///
/// Характеристики из JS кода:
/// - itemID: "1134"
/// - energyCost: 1
/// - fireDelayInSeconds: 0.05 (20 выстрелов в секунду!)
/// - damage: 5
/// - speed: 800
/// - lifetime: 1.5s
class ChainGun extends WeaponBase {
  @override
  String get itemID => "1134";

  @override
  String get displayName => "Chain Gun";

  @override
  double get energyCost => 1;

  @override
  double get fireDelayInSeconds => 0.05;

  @override
  double get damage => 5;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'chaingun.png';

  @override
  String get projectileSpritePattern => 'chaingun_projectile_';

  @override
  String get muzzleSpritePattern => 'chaingun_muzzle_';

  @override
  String get impactSpritePattern => 'chaingun_impact_';

  @override
  void onFire(Player player) {
    // Получить направление стрельбы
    final direction = getFireDirection(player);

    // Получить позицию спавна пули
    final spawnPos = getBulletSpawnOffset(player, 20);

    // Создать пулю
    final bullet = Bullet(
      position: spawnPos,
      owner: player,
      direction: direction,
      damage: damage,
      speed: 800,
      lifetime: 1.5,
      spritePattern: projectileSpritePattern,
    );

    // Добавить пулю в игровой мир
    addProjectileToWorld(bullet);

    // TODO: Звук выстрела
    // SoundManager.play('machine_shoot0.ogg');
  }
}
