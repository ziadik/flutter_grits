// lib/flame_game/weapons/rocket_launcher.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Ракетница (RocketLauncher)
///
/// Мощная ракета с высоким уроном.
///
/// Характеристики из JS кода:
/// - itemID: "4805"
/// - energyCost: 10
/// - fireDelayInSeconds: 0.5
/// - damage: 25
/// - speed: 900
/// - lifetime: 3s
class RocketLauncher extends WeaponBase {
  @override
  String get itemID => "4805";

  @override
  String get displayName => "Rocket Launcher";

  @override
  double get energyCost => 10;

  @override
  double get fireDelayInSeconds => 0.5;

  @override
  double get damage => 25;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'rocket_launcher.png';

  @override
  String get projectileSpritePattern => 'rocket_launcher_projectile_';

  @override
  String get muzzleSpritePattern => 'rocket_launcher_muzzle_';

  @override
  String get impactSpritePattern => 'rocket_launcher_impact_';

  @override
  void onFire(Player player) {
    // Получить направление стрельбы
    final direction = getFireDirection(player);

    // Получить позицию спавна ракеты
    final spawnPos = getBulletSpawnOffset(player, 20);

    // Создать ракету
    final rocket = Bullet(
      position: spawnPos,
      owner: player,
      direction: direction,
      damage: damage,
      speed: 900,
      lifetime: 3.0,
      spritePattern: projectileSpritePattern,
    );

    // Добавить ракету в игровой мир
    addProjectileToWorld(rocket);

    // TODO: Звук выстрела
    // SoundManager.play('rocket_shoot0.ogg');
  }
}
