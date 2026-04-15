// lib/entities/player.dart
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/components/health_bar_component.dart';
import 'package:flutter_grits/flame_game/components/energy_bar_component.dart';

class Player extends PositionComponent with HasGameReference {
  final ResourceManager resourceManager;

  // Статистика
  double health = 100;
  double maxHealth = 100;
  double energy = 100;
  double maxEnergy = 100;
  int team = 0;
  String playerName = 'Player 1';

  // Анимация
  String _currentDirection = 'down';
  double _animationTimer = 0;
  bool _isWalking = false;
  final double _walkSpeed = 200.0;
  double _angle = 0;

  // Компоненты
  late SpriteAnimationComponent _legsComponent;
  late SpriteAnimationComponent _legsMaskComponent;
  late SpriteComponent _torsoComponent;
  late SpriteAnimationComponent _turretComponent;
  late HealthBarComponent _healthBar;
  late EnergyBarComponent _energyBar;
  late TextComponent _nameLabel;

  // Параметры спрайтов
  static const double spriteScale = 1.0;
  static const double playerSize = 64.0;

  @override
  double get angle => _angle;
  @override
  set angle(double value) {
    _angle = value;
    if (_turretComponent != null) {
      _turretComponent.angle = value;
    }
  }

  Player({required super.position, required this.resourceManager}) {
    width = playerSize;
    height = playerSize;
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Инициализация компонентов
    _legsComponent = SpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );
    _legsMaskComponent = SpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );
    _torsoComponent = SpriteComponent(
      size: Vector2(playerSize * 0.75, playerSize * 0.75),
      anchor: Anchor.center,
    );
    _turretComponent = SpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Создание анимаций
    _createLegsAnimation();
    _createTorso();
    _createTurret();
    _createUIComponents();

    // Добавление всех компонентов
    await add(_legsComponent);
    await add(_legsMaskComponent);
    await add(_torsoComponent);
    await add(_turretComponent);
    await add(_healthBar);
    await add(_energyBar);
    await add(_nameLabel);
  }

  void _createLegsAnimation() {
    final animator = resourceManager.playerAnimator;

    final legSprites = animator.getLegSprites(_currentDirection);
    if (legSprites.isNotEmpty) {
      _legsComponent.animation = SpriteAnimation.spriteList(
        legSprites,
        stepTime: 1 / 30,
        loop: true,
      );

      final maskSprites = animator.getLegMaskSprites(_currentDirection);
      if (maskSprites.isNotEmpty) {
        _legsMaskComponent.animation = SpriteAnimation.spriteList(
          maskSprites,
          stepTime: 1 / 30,
          loop: true,
        );
        _legsMaskComponent.paint = Paint()
          ..colorFilter = ColorFilter.mode(_getTeamColor(), BlendMode.multiply);
      }
    }
  }

  void _createTorso() {
    // Можно использовать спрайт или простую фигуру
    _torsoComponent.paint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
  }

  void _createTurret() {
    final turretSprite = resourceManager.playerAnimator.getTurretSprite();
    if (turretSprite != null) {
      _turretComponent.animation = SpriteAnimation.spriteList([
        turretSprite,
      ], stepTime: 1.0);
    } else {
      _turretComponent.paint = Paint()..color = Colors.grey[700]!;
    }
  }

  void _createUIComponents() {
    _healthBar = HealthBarComponent(
      position: Vector2(0, -playerSize / 2 - 10),
      health: health,
      maxHealth: maxHealth,
    );

    _energyBar = EnergyBarComponent(
      position: Vector2(0, -playerSize / 2 - 5),
      energy: energy,
      maxEnergy: maxEnergy,
    );

    _nameLabel = TextComponent(
      text: playerName,
      position: Vector2(0, -playerSize / 2 - 18),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
        ),
      ),
    );
  }

  void move(Vector2 direction, double dt) {
    _isWalking = direction != Vector2.zero();

    if (_isWalking) {
      final movement = direction * _walkSpeed * dt;
      position += movement;

      // Обновление направления для анимации
      _updateAnimationDirection(direction);

      // Обновление анимации
      _animationTimer += dt;
      if (_animationTimer >= 1 / 30) {
        _animationTimer = 0;
        _updateLegsAnimation();
      }
    }
  }

  void _updateAnimationDirection(Vector2 direction) {
    if (direction.y.abs() > direction.x.abs()) {
      _currentDirection = direction.y > 0 ? 'down' : 'up';
    } else {
      _currentDirection = direction.x > 0 ? 'right' : 'left';
    }
  }

  void _updateLegsAnimation() {
    final animator = resourceManager.playerAnimator;
    final legSprites = animator.getLegSprites(_currentDirection);
    final maskSprites = animator.getLegMaskSprites(_currentDirection);

    if (legSprites.isNotEmpty) {
      _legsComponent.animation = SpriteAnimation.spriteList(
        legSprites,
        stepTime: 1 / 30,
        loop: true,
      );
    }

    if (maskSprites.isNotEmpty) {
      _legsMaskComponent.animation = SpriteAnimation.spriteList(
        maskSprites,
        stepTime: 1 / 30,
        loop: true,
      );
    }
  }

  Color _getTeamColor() {
    const teamColors = [
      Color(0xFF33FF33), // Team 0 - Green
      Color(0xFFFF9933), // Team 1 - Orange
    ];
    return teamColors[team % teamColors.length];
  }

  void takeDamage(double amount) {
    health = (health - amount).clamp(0, maxHealth);
    _healthBar.updateHealth(health, maxHealth);

    if (health <= 0) {
      die();
    }
  }

  void useEnergy(double amount) {
    energy = (energy - amount).clamp(0, maxEnergy);
    _energyBar.updateEnergy(energy, maxEnergy);
  }

  void die() {
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Регенерация энергии
    if (energy < maxEnergy) {
      energy = (energy + 20 * dt).clamp(0, maxEnergy);
      _energyBar.updateEnergy(energy, maxEnergy);
    }
  }
}
