// lib/flame_game/weapons/weapon_base.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/effects/muzzle_flash.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

/// Абстрактный базовый класс для всех видов оружия.
///
/// Все оружия должны наследоваться от этого класса и реализовать:
/// - [onInit] - инициализация при создании
/// - [onUpdate] - вызывается каждый кадр
/// - [onFire] - действие при выстреле
/// - [onDraw] - отрисовка оружия на игроке
abstract class WeaponBase {
  /// Уникальный идентификатор оружия (из JS кода, hex формат)
  String get itemID;

  /// Отображаемое название
  String get displayName;

  /// Стоимость выстрела в единицах энергии
  double get energyCost;

  /// Задержка между выстрелами в секундах
  double get fireDelayInSeconds;

  /// Текущее состояние стрельбы
  bool firing = false;

  /// Время следующего выстрела (timestamp)
  double nextFireTime = 0;

  /// Игрок, которому принадлежит оружие
  Player? _owningPlayer;

  /// Урон за выстрел (по умолчанию 0, переопределять в подклассах)
  double get damage => 0;

  /// Название спрайта основного изображения оружия (для отрисовки на игроке)
  String get weaponSpriteName => '';

  /// Название паттерна для спрайтов снаряда (например, 'machinegun_projectile_')
  String get projectileSpritePattern => '';

  /// Название паттерна для спрайтов эффекта выстрела (muzzle)
  String get muzzleSpritePattern => '';

  /// Название паттерна для спрайтов эффекта удара
  String get impactSpritePattern => '';

  /// Инициализация оружия (вызывается при создании)
  void onInit(Player player) {
    _owningPlayer = player;
  }

  /// Обновление состояния оружия каждый кадр
  ///
  /// [dt] - дельта времени в секундах
  void onUpdate(Player player, double dt) {}

  /// Действие при выстреле
  void onFire(Player player);

  /// Отрисовка оружия на игроке
  ///
  /// [canvas] - холст для отрисовки
  void onDraw(Canvas canvas, Player player) {}

  /// Проверка возможности выстрела
  bool canFire(Player player) {
    return player.energy >= energyCost &&
        DateTime.now().millisecondsSinceEpoch / 1000 >= nextFireTime;
  }

  /// Потребление энергии при выстреле
  void consumeEnergy(Player player) {
    player.useEnergy(energyCost);
  }

  /// Запуск выстрела (с проверками)
  void tryFire(Player player) {
    if (!canFire(player)) {
      firing = false;
      return;
    }

    consumeEnergy(player);
    firing = true;
    nextFireTime =
        DateTime.now().millisecondsSinceEpoch / 1000 + fireDelayInSeconds;

    onFire(player);
  }

  /// Получить направление стрельбы от игрока
  Vector2 getFireDirection(Player player) {
    return Vector2(cos(player.faceAngleRadians), sin(player.faceAngleRadians));
  }

  /// Получить позицию спавна пули (смещение от игрока)
  Vector2 getBulletSpawnOffset(Player player, [double offset = 20]) {
    final dir = getFireDirection(player);
    return player.position + dir * offset;
  }

  /// Добавить снаряд в игровой мир
  void addProjectileToWorld(ProjectileBase projectile) {
    // Найти GameWorld напрямую через игрока
    final gameWorld = _owningPlayer?.findParent<GameWorld>();
    if (gameWorld != null) {
      gameWorld.add(projectile);
      // debugPrint('✅ Projectile added to GameWorld at ${projectile.position}');
    } else {
      // debugPrint('❌ GameWorld not found for projectile!');
    }
  }

  /// Добавить эффект в игровой мир
  void addEffectToWorld(PositionComponent effect) {
    final gameWorld = _owningPlayer?.findParent<GameWorld>();
    if (gameWorld != null) {
      gameWorld.add(effect);
      // debugPrint('✅ Effect added to GameWorld');
    } else {
      // debugPrint('❌ GameWorld not found for effect!');
    }
  }

  /// Создать эффект вспышки выстрела (muzzle flash)
  void createMuzzleFlash(Player player, Vector2 offset) {
    if (muzzleSpritePattern.isEmpty) {
      // Fallback - простой muzzle flash без спрайтов
      createSimpleMuzzleFlash(player, offset);
      return;
    }

    final animator = player.resourceManager.playerAnimator;

    // Получаем все спрайты для muzzle flash по паттерну
    final muzzleSprites = animator.getSpritesByPattern(
      '${muzzleSpritePattern}.*\\.png',
    );

    // debugPrint(
    //   '🔫 Muzzle flash sprites for $displayName: ${muzzleSprites.length}',
    // );

    if (muzzleSprites.isEmpty) {
      // Если спрайты не найдены, используем простой fallback
      // debugPrint('⚠️ No muzzle flash sprites found for $displayName');
      createSimpleMuzzleFlash(player, offset);
      return;
    }

    // Вычисляем позицию muzzle flash относительно игрока
    final direction = getFireDirection(player);
    final muzzlePos =
        player.position +
        direction * offset.x +
        Vector2(-direction.y, direction.x) * offset.y;

    final muzzle = MuzzleFlash(
      position: muzzlePos,
      frames: muzzleSprites,
      frameDuration: 0.05,
      size: Vector2(64, 64),
      angle: player.faceAngleRadians,
    );

    // Добавляем эффект в мир через addEffectToWorld
    addEffectToWorld(muzzle);
  }

  /// Простой muzzle flash без спрайтов (fallback)
  void createSimpleMuzzleFlash(Player player, Vector2 offset) {
    final direction = getFireDirection(player);
    final muzzlePos =
        player.position +
        direction * offset.x +
        Vector2(-direction.y, direction.x) * offset.y;

    final flash = SimpleMuzzleFlash(position: muzzlePos);
    addEffectToWorld(flash);
  }
}

/// Абстрактный базовый класс для снарядов
abstract class ProjectileBase extends PositionComponent {
  final Player owner;
  final Vector2 direction;
  final double damage;
  final double speed;
  double lifetime;
  final double maxLifetime;
  final String spritePattern; // Паттерн для загрузки спрайтов из JSON

  ProjectileBase({
    required Vector2 position,
    required this.owner,
    required this.direction,
    required this.damage,
    required this.speed,
    required this.lifetime,
    this.spritePattern = '',
  }) : maxLifetime = lifetime,
       super(position: position) {
    size = Vector2(8, 8);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Движение снаряда
    position += direction.normalized() * speed * dt;

    // Уменьшение времени жизни
    lifetime -= dt;
    if (lifetime <= 0) {
      destroy();
    }
  }

  /// Обработка коллизии
  void onCollision(Vector2 collisionPoint, PositionComponent other) {
    // Базовая реализация - ничего не делает
  }

  /// Уничтожение снаряда
  void destroy() {
    removeFromParent();
  }

  /// Проверка, является ли объект целью (не союзник)
  bool isTarget(PositionComponent other) {
    if (other is! Player) return true; // Стены, объекты - цели
    return other.team != owner.team; // Только враги
  }
}
