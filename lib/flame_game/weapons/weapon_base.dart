// lib/flame_game/weapons/weapon_base.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/effects/muzzle_flash.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/projectiles/projectile_base.dart';

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
    return player.energy >= energyCost && DateTime.now().millisecondsSinceEpoch / 1000 >= nextFireTime;
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
    nextFireTime = DateTime.now().millisecondsSinceEpoch / 1000 + fireDelayInSeconds;

    onFire(player);
  }

  /// Получить направление стрельбы от игрока
  Vector2 getFireDirection(Player player) {
    return player.getFireDirection(player); //Vector2(cos(player.faceAngleRadians), sin(player.faceAngleRadians));
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
      debugPrint('✅ Projectile added to GameWorld at ${projectile.position}');
    } else {
      debugPrint('❌ GameWorld not found for projectile!');
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
      createSimpleMuzzleFlash(player, offset);
      return;
    }

    final animator = player.resourceManager.playerAnimator;

    // Получаем все спрайты для muzzle flash по паттерну
    final muzzleSprites = animator.getSpritesByPattern('${muzzleSpritePattern}');

    // debugPrint(
    //   '🔫 $displayName: Found ${muzzleSprites.length} muzzle sprites for pattern: $muzzleSpritePattern',
    // );

    if (muzzleSprites.isEmpty) {
      debugPrint('⚠️ No muzzle flash sprites found for $displayName, using fallback');
      createSimpleMuzzleFlash(player, offset);
      return;
    }

    // Получаем направление стрельбы (единичный вектор)
    final direction = player.getAimDirection();

    // ✅ Правильное вычисление позиции muzzle flash:
    // offset.x - расстояние по направлению выстрела (вперёд от центра игрока)
    // offset.y - боковое смещение дула относительно центра игрока
    // Используем левый перпендикуляр (direction.y, -direction.x) для корректной работы с отрицательными значениями Y
    final forward = direction * offset.x;
    final side = Vector2(direction.y, -direction.x) * offset.y;

    final muzzlePos = player.position + forward + side;

    // debugPrint(
    //   '🔫 Muzzle flash - pos: $muzzlePos, dir: $direction, offset: $offset, angle: ${player.faceAngleRadians * 180 / pi}°',
    // );

    final muzzle = MuzzleFlash(position: muzzlePos, frames: muzzleSprites, frameDuration: 0.05, size: Vector2(256, 256), angle: player.faceAngleRadians);

    // Добавляем эффект в мир через addEffectToWorld
    addEffectToWorld(muzzle);
  }

  /// Простой muzzle flash без спрайтов (fallback)
  void createSimpleMuzzleFlash(Player player, Vector2 offset) {
    final direction = player.getAimDirection();

    final forward = direction * offset.x;
    final side = Vector2(direction.y, -direction.x) * offset.y;
    final muzzlePos = player.position + forward + side;

    final flash = SimpleMuzzleFlash(position: muzzlePos, angle: player.faceAngleRadians);
    addEffectToWorld(flash);
  }
}

/// Простой muzzle flash без спрайтов (для отладки)
