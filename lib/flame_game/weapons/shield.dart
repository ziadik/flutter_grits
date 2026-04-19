// lib/flame_game/weapons/shield.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Защитный щит (Shield)
///
/// Создает защитный щит перед игроком. Тратит энергию пока удерживаешь кнопку.
///
/// Характеристики из JS кода:
/// - itemID: "4188"
/// - energyCost: 2 (в секунду при удержании)
class Shield extends WeaponBase {
  ShieldInstance? _shieldInstance;

  @override
  String get itemID => "4188";

  @override
  String get displayName => "Shield";

  @override
  double get energyCost => 2;

  @override
  double get fireDelayInSeconds => 0.5;

  @override
  double get damage => 0; // Защитное оружие

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'defensive_shield.png';

  @override
  String get projectileSpritePattern => '';

  @override
  String get muzzleSpritePattern => '';

  @override
  String get impactSpritePattern => '';

  @override
  void onFire(Player player) {
    if (_shieldInstance != null) return;

    // Создать щит перед игроком
    _shieldInstance = ShieldInstance(owner: player);
    _shieldInstance!.position = player.position;

    player.addToWorld(_shieldInstance!);
  }

  @override
  void onUpdate(Player player, double dt) {
    // Проверка, отпущена ли кнопка или кончилась энергия
    if (!player.isShieldActive || player.energy <= 0) {
      _shieldInstance?.destroy();
      _shieldInstance = null;
    } else {
      // Тратить энергию пока держишь щит
      player.useEnergy(energyCost * dt);
    }
  }
}

/// Экземпляр щита
class ShieldInstance extends PositionComponent {
  final Player owner;

  ShieldInstance({required this.owner}) {
    size = Vector2(60, 60);
    anchor = Anchor.center;
  }

  void destroy() {
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Отрисовка щита
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = Color(0xFF3366FF).withOpacity(0.5)
        ..style = PaintingStyle.fill,
    );

    // Рамка
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
