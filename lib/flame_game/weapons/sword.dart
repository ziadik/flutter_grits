// lib/flame_game/weapons/sword.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';

/// Энергетический меч (Sword)
///
/// Ближний бой. Создает энергетический меч перед игроком.
///
/// Характеристики из JS кода:
/// - itemID: "4124"
/// - energyCost: 2
class Sword extends WeaponBase {
  SwordInstance? _swordInstance;

  @override
  String get itemID => "4124";

  @override
  String get displayName => "Energy Sword";

  @override
  double get energyCost => 2;

  @override
  double get fireDelayInSeconds => 0.5;

  @override
  double get damage => 20;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'offensive_shield.png';

  @override
  String get projectileSpritePattern => '';

  @override
  String get muzzleSpritePattern => '';

  @override
  String get impactSpritePattern => '';

  @override
  void onFire(Player player) {
    if (_swordInstance != null) return;

    // Воспроизвести звук активации меча
    SoundManager().playSfx(SoundAssets.swordActivate);

    // Создать меч перед игроком
    _swordInstance = SwordInstance(owner: player);
    _swordInstance!.position = player.position;

    player.addToWorld(_swordInstance!);
  }

  @override
  void onUpdate(Player player, double dt) {
    // Проверка, отпущена ли кнопка или кончилась энергия
    if (!player.isSwordActive || player.energy <= 0) {
      _swordInstance?.destroy();
      _swordInstance = null;
    } else {
      // Тратить энергию пока держишь меч
      player.useEnergy(energyCost * dt);
    }
  }
}

/// Экземпляр меча
class SwordInstance extends PositionComponent {
  final Player owner;

  SwordInstance({required this.owner}) {
    size = Vector2(60, 60);
    anchor = Anchor.center;
  }

  void destroy() {
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Отрисовка меча
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = Color(0xFF33FF33).withOpacity(0.5)
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
