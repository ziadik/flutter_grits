// lib/flame_game/weapons/landmine.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Наземная мина (Landmine)
///
/// Ставит мину позади игрока. Взрывается при приближении врага.
///
/// Характеристики из JS кода:
/// - itemID: "4123"
/// - energyCost: 10
/// - fireDelayInSeconds: 0.5
class Landmine extends WeaponBase {
  @override
  String get itemID => "4123";

  @override
  String get displayName => "Landmine";

  @override
  double get energyCost => 10;

  @override
  double get fireDelayInSeconds => 0.5;

  @override
  double get damage => 50;

  // Спрайты из grits_effects.json
  @override
  String get weaponSpriteName => 'landmine.png';

  @override
  String get projectileSpritePattern => '';

  @override
  String get muzzleSpritePattern => '';

  @override
  String get impactSpritePattern => 'landmine_explosion_large_';

  @override
  void onFire(Player player) {
    // Ставим мину ЗА спиной (-25px)
    final backDirection = Vector2(
      cos(player.faceAngleRadians + pi),
      sin(player.faceAngleRadians + pi),
    );
    final spawnPos = player.position + backDirection * 25;

    final mine = LandmineDisk(
      position: spawnPos,
      team: player.team,
      damage: damage,
    );

    player.addToWorld(mine);
  }
}

/// Мина на земле
class LandmineDisk extends PositionComponent {
  final int team;
  final double damage;
  bool _exploded = false;

  LandmineDisk({
    required Vector2 position,
    required this.team,
    required this.damage,
  }) {
    this.position = position;
    size = Vector2(40, 40);
    anchor = Anchor.center;
  }

  bool get isExploded => _exploded;

  void explode() {
    if (_exploded) return;
    _exploded = true;

    // TODO: Создать эффект взрыва
    // final explosion = ExplosionEffect(position: position);
    // addToWorld(explosion);

    // Нанести урон всем вокруг
    // TODO: Добавить логику AreaCollision

    // Уничтожить мину через короткое время
    Future.delayed(const Duration(milliseconds: 500), () {
      destroy();
    });
  }

  void destroy() {
    removeFromParent();
  }

  void addToWorld(PositionComponent component) {
    // Находим родительский компонент (GameWorld) и добавляем
    final parent = findParent<PositionComponent>();
    if (parent != null) {
      parent.add(component);
    }
  }

  @override
  void render(Canvas canvas) {
    // Отрисовка мины
    final color = team == 0 ? Colors.blue : Colors.red;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = color.withOpacity(0.7)
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

    // Символ опасности (используем TextPainter)
    final painter = TextPainter(
      text: const TextSpan(
        text: '⚠',
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset(size.x / 2 - 10, size.y / 2 - 10));
  }
}
