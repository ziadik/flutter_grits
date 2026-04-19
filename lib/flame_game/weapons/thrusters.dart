// lib/flame_game/weapons/thrusters.dart
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Трюстеры / Ускорение (Thrusters)
///
/// Временно увеличивает скорость движения игрока на 50%.
///
/// Характеристики из JS кода:
/// - itemID: "4133"
/// - energyCost: 0 (не тратит энергию при активации)
class Thrusters extends WeaponBase {
  double? _storedSpeed;

  @override
  String get itemID => "4133";

  @override
  String get displayName => "Thrusters";

  @override
  double get energyCost => 0;

  @override
  double get fireDelayInSeconds => 0;

  @override
  double get damage => 0;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'thruster.png';

  @override
  String get projectileSpritePattern => '';

  @override
  String get muzzleSpritePattern => '';

  @override
  String get impactSpritePattern => '';

  @override
  void onFire(Player player) {
    if (_storedSpeed != null) return;

    // Сохранить текущую скорость и увеличить на 50%
    _storedSpeed = player.walkSpeed;
    player.setWalkSpeed(player.walkSpeed * 1.5);
  }

  @override
  void onUpdate(Player player, double dt) {
    // Если кнопка отпущена - вернуть скорость
    if (!player.isThrustersActive && _storedSpeed != null) {
      player.setWalkSpeed(_storedSpeed!);
      _storedSpeed = null;
    }
  }
}
