// lib/flame_game/weapons/grenade_launcher.dart
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:vector_math/vector_math.dart';

/// Гранатомет (GrenadeLauncher)
///
/// Стреляет прыгающими гранатами. Высокий расход энергии.
///
/// Характеристики из JS кода:
/// - itemID: "1232"
/// - energyCost: 8
/// - fireDelayInSeconds: 0.5
/// - damage: 15
/// - speed: 800
/// - lifetime: 2.5s
class GrenadeLauncher extends WeaponBase {
  @override
  String get itemID => "1232";

  @override
  String get displayName => "Grenade Launcher";

  @override
  double get energyCost => 8;

  @override
  double get fireDelayInSeconds => 0.5;

  @override
  double get damage => 15;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'grenade_launcher.png';

  @override
  String get projectileSpritePattern => 'grenade_launcher_projectile_';

  @override
  String get muzzleSpritePattern => 'grenade_launcher_muzzle_';

  @override
  String get impactSpritePattern => 'grenade_launcher_impact_';

  @override
  void onFire(Player player) {
    // Получить направление стрельбы
    final direction = getFireDirection(player);

    // Получить позицию спавна гранаты
    final spawnPos = getBulletSpawnOffset(player, 20);

    // Создать гранату
    final grenade = Bullet(
      position: spawnPos,
      owner: player,
      direction: direction,
      damage: damage,
      speed: 800,
      lifetime: 2.5,
      spritePattern: projectileSpritePattern,
    );

    // Добавить гранату в игровой мир
    addProjectileToWorld(grenade);

    // Создать muzzle flash для гранатомета (позиция дула: x=40, y=-5)
    createMuzzleFlash(player, Vector2(40, -5));

    // Воспроизвести звук выстрела
    SoundManager().playShootSound(SoundAssets.grenadeShoot0);
  }
}
