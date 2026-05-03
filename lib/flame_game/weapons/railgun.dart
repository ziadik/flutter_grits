// lib/flame_game/weapons/railgun.dart
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/projectiles/railgun_beam.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
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
    debugPrint('🔦 Railgun firing!');

    // Получить направление стрельбы
    final direction = getFireDirection(player);

    // Получить позицию спавна луча (от центра игрока)
    final spawnPos = getBulletSpawnOffset(player, 40);

    // Создать луч Railgun
    final beam = RailgunBeam(
      position: spawnPos,
      owner: player,
      direction: direction,
      damage: damage,
      lifetime: 0.1, // Луч существует очень короткое время
    );

    // Поворачиваем луч по направлению стрельбы
    beam.angle = player.faceAngleRadians;

    // Добавить луч в игровой мир (через addEffectToWorld так как это не ProjectileBase)
    addEffectToWorld(beam);

    // Создать muzzle flash
    createMuzzleFlash(player, Vector2(40, 0));

    // Звук выстрела (если есть)
    // SoundManager().playShootSound(SoundAssets.railgunShoot);
  }
}
