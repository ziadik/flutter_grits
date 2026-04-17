// lib/entities/player.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/components/health_bar_component.dart';
import 'package:flutter_grits/flame_game/components/energy_bar_component.dart';

class Player extends PositionComponent {
  final ResourceManager resourceManager;
  InputManager? inputManager; // Подключается из мира

  // Статистика
  double health = 100;
  double maxHealth = 100;
  double energy = 100;
  double maxEnergy = 100;
  int team = 0;
  String playerName = 'Player 1';

  // Движение
  String _currentDirection = 'down';
  double _animationTimer = 0;
  bool _isWalking = false;
  final double _walkSpeed = 200.0;
  double _angle = 0;

  // Компоненты
  late SpriteAnimationComponent _legsComponent;
  late SpriteAnimationComponent _legsMaskComponent;
  late SpriteAnimationComponent _turretComponent;
  late HealthBarComponent _healthBar;
  late EnergyBarComponent _energyBar;
  late TextComponent _nameLabel;

  bool _legsAnimationLoaded = false;
  bool _turretAnimationLoaded = false;

  static const double playerSize = 64.0;

  @override
  double get angle => _angle;
  @override
  set angle(double value) {
    _angle = value;
    if (_turretAnimationLoaded) {
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
    await _createComponents();
    await _loadAnimations();
  }

  Future<void> _createComponents() async {
    // Ноги
    _legsComponent = SpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Маска ног (для цвета команды)
    _legsMaskComponent = SpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Турель
    _turretComponent = SpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // UI компоненты
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

    await addAll([
      _legsComponent,
      _legsMaskComponent,
      _turretComponent,
      _healthBar,
      _energyBar,
      _nameLabel,
    ]);
  }

  Future<void> _loadAnimations() async {
    final animator = resourceManager.playerAnimator;

    // Ждем загрузки аниматора
    int attempts = 0;
    while (!animator.isLoaded && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (animator.isLoaded) {
      await _createLegsAnimation();
      await _createTurret();
    }
  }

  Future<void> _createLegsAnimation() async {
    final animator = resourceManager.playerAnimator;
    final legSprites = animator.getLegSprites(_currentDirection);

    if (legSprites.isNotEmpty) {
      _legsComponent.animation = SpriteAnimation.spriteList(
        legSprites,
        stepTime: 1 / 30,
        loop: true,
      );
      _legsAnimationLoaded = true;
    }

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

  Future<void> _createTurret() async {
    final animator = resourceManager.playerAnimator;
    final turretSprite = animator.getTurretSprite();

    if (turretSprite != null) {
      _turretComponent.animation = SpriteAnimation.spriteList([
        turretSprite,
      ], stepTime: 1.0);
      _turretAnimationLoaded = true;
    }
  }

  void move(Vector2 direction, double dt) {
    _isWalking = direction != Vector2.zero();

    if (_isWalking) {
      // Движение
      final movement = direction * _walkSpeed * dt;
      position += movement;

      // Обновление направления анимации
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
    if (!_legsAnimationLoaded) return;

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
