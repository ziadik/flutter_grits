// lib/flame_game/weapons/machine_gun.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/bullet.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

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
  String get displayName => "Machine_Gun ";

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
    // Получить направление стрельбы
    final direction = getFireDirection(player);

    // Получить позицию спавна пули (смещение на 20px вперед)
    final spawnPos = getBulletSpawnOffset(player, 20);

    // Создать пулю
    final bullet = Bullet(
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

    // TODO: Воспроизвести звук выстрела
    // SoundManager.play('machine_shoot0.ogg');
  }
}
