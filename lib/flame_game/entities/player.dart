// lib/entities/player.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/components/health_bar_component.dart';
import 'package:flutter_grits/flame_game/components/energy_bar_component.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';
import 'dart:ui' as ui;

class TrimmedSpriteAnimationComponent extends PositionComponent {
  List<TrimmedSprite> _frames = [];
  List<TrimmedSprite> _idleFrames = [];
  double _stepTime = 0.1;
  double _currentTime = 0;
  int _currentFrame = 0;
  bool _loop = true;
  Paint? _paint;
  bool _isPlaying = true;
  bool _isWalking = false;
  int _lastFrameIndex = 0; // Запоминаем последний кадр

  TrimmedSpriteAnimationComponent({
    required super.size,
    required super.anchor,
    List<TrimmedSprite>? frames,
    List<TrimmedSprite>? idleFrames,
    double stepTime = 0.1,
    bool loop = true,
    Paint? paint,
  }) {
    if (frames != null) {
      _frames = frames;
    }
    if (idleFrames != null && idleFrames.isNotEmpty) {
      _idleFrames = idleFrames;
    } else if (frames != null && frames.isNotEmpty) {
      // Если нет idle кадров, используем первый кадр анимации
      _idleFrames = [frames.first];
    }
    _stepTime = stepTime;
    _loop = loop;
    _paint = paint;
  }

  void setAnimation(
    List<TrimmedSprite> frames, {
    double stepTime = 0.1,
    bool loop = true,
  }) {
    _frames = frames;
    _stepTime = stepTime;
    _loop = loop;
    _currentFrame = 0;
    _currentTime = 0;
  }

  void setWalking(bool walking) {
    if (_isWalking == walking) return;
    _isWalking = walking;

    if (!_isWalking) {
      // Останавливаемся - запоминаем последний кадр
      _lastFrameIndex = _currentFrame;
    } else {
      // Начинаем движение - продолжаем с того же кадра
      _currentFrame = _lastFrameIndex;
    }
    _currentTime = 0;
  }

  void play() {
    _isPlaying = true;
  }

  void stop() {
    _isPlaying = false;
  }

  set paint(Paint? paint) {
    _paint = paint;
  }

  Paint? get paint => _paint;

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isPlaying) return;

    // Если не идем, не обновляем кадры - оставляем последний кадр
    if (!_isWalking) {
      return;
    }

    if (_frames.isEmpty) return;

    _currentTime += dt;

    if (_currentTime >= _stepTime) {
      _currentTime = 0;
      _currentFrame++;

      if (_currentFrame >= _frames.length) {
        if (_loop) {
          _currentFrame = 0;
        } else {
          _currentFrame = _frames.length - 1;
          _isPlaying = false;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_frames.isEmpty) return;

    // При ходьбе показываем текущий кадр анимации
    // При остановке показываем последний кадр, на котором остановились
    final frameIndex = _isWalking ? _currentFrame : _lastFrameIndex;
    final frame = _frames[frameIndex.clamp(0, _frames.length - 1)];

    frame.renderCentered(canvas, Vector2.zero(), Size(size.x, size.y), _paint);
  }
}

class Player extends PositionComponent {
  final ResourceManager resourceManager;
  InputManager? inputManager;

  // Статистика
  double health = 100;
  double maxHealth = 100;
  double energy = 100;
  double maxEnergy = 100;
  int team = 0;
  String playerName = 'Player 1';
  bool isDead = false;

  // Движение
  int _currLegAnimIndex = 2; // 2 = down
  bool walking = false;
  final double _walkSpeed = 200.0;
  double faceAngleRadians = 0;

  // Компоненты для отрисовки
  late TrimmedSpriteAnimationComponent _legsComponent;
  late TrimmedSpriteAnimationComponent _legsMaskComponent;
  late SpriteComponent _turretComponent;

  // UI компоненты
  late HealthBarComponent _healthBar;
  late EnergyBarComponent _energyBar;
  late TextComponent _nameLabel;

  // Хранилище анимаций для каждого направления
  final Map<int, List<TrimmedSprite>> _walkAnimations = {};
  final Map<int, List<TrimmedSprite>> _idleAnimations = {};

  static const double playerSize = 128.0;

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
    _legsComponent = TrimmedSpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Маска ног
    _legsMaskComponent = TrimmedSpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Турель
    _turretComponent = SpriteComponent(
      size: Vector2(playerSize * 0.6, playerSize * 0.6),
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

    await _loadTurretSprite();
  }

  Future<void> _loadTurretSprite() async {
    final animator = resourceManager.playerAnimator;
    final turretTrimmedSprite = animator.getTurretSprite();

    if (turretTrimmedSprite != null) {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      turretTrimmedSprite.renderCentered(
        canvas,
        Vector2.zero(),
        Size(_turretComponent.size.x, _turretComponent.size.y),
        null,
      );
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(
        _turretComponent.size.x.toInt(),
        _turretComponent.size.y.toInt(),
      );
      _turretComponent.sprite = Sprite(image);
    }
  }

  Future<void> _loadAnimations() async {
    final animator = resourceManager.playerAnimator;

    int attempts = 0;
    while (!animator.isLoaded && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (animator.isLoaded) {
      await _loadAllAnimations();
      _updateAnimation();
    }
  }

  Future<void> _loadAllAnimations() async {
    final animator = resourceManager.playerAnimator;
    final directions = ['up', 'left', 'down', 'right'];

    for (int i = 0; i < directions.length; i++) {
      final dir = directions[i];
      final walkSprites = animator.getLegSprites(dir);
      final maskSprites = animator.getLegMaskSprites(dir);

      if (walkSprites.isNotEmpty) {
        _walkAnimations[i] = walkSprites;
        // Idle анимация - только первый кадр
        _idleAnimations[i] = [walkSprites.first];
      }

      if (maskSprites.isNotEmpty) {
        // Для маски тоже сохраняем
      }
    }
  }

  void _updateAnimation() {
    final walkFrames = _walkAnimations[_currLegAnimIndex];
    final idleFrames = _idleAnimations[_currLegAnimIndex];

    if (walkFrames != null) {
      _legsComponent.setAnimation(walkFrames, stepTime: 1 / 30, loop: true);
    }

    if (idleFrames != null) {
      // Передаем idle кадры в компонент
    }

    final maskWalkFrames = resourceManager.playerAnimator.getLegMaskSprites(
      _getDirectionString(_currLegAnimIndex),
    );
    if (maskWalkFrames.isNotEmpty) {
      _legsMaskComponent.setAnimation(
        maskWalkFrames,
        stepTime: 1 / 30,
        loop: true,
      );
      // _legsMaskComponent.paint = Paint()
      //   ..colorFilter = ColorFilter.mode(_getTeamColor(), BlendMode.multiply);
    }

    final maskIdleFrames = maskWalkFrames.isNotEmpty
        ? [maskWalkFrames.first]
        : [];
    if (maskIdleFrames.isNotEmpty) {
      // Idle кадры для маски
    }
  }

  String _getDirectionString(int index) {
    const directions = ['up', 'left', 'down', 'right'];
    return directions[index];
  }

  Color _getTeamColor() {
    const teamColors = [Color(0xFF33FF33), Color(0xFFFF9933)];
    return teamColors[team % teamColors.length];
  }

  void updateMovement(double dt) {
    if (inputManager == null) return;

    final moveDir = inputManager!.moveDirection;
    final wasWalking = walking;
    walking = moveDir != Vector2.zero();

    // Обновляем состояние анимации (ходьба/покой)
    if (walking != wasWalking) {
      _legsComponent.setWalking(walking);
      _legsMaskComponent.setWalking(walking);
    }

    final pressedKeys = inputManager!.getPressedKeys();

    int newAnimIndex = _currLegAnimIndex;

    if (pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      newAnimIndex = 0;
    } else if (pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      newAnimIndex = 2;
    }

    if (pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      newAnimIndex = 1;
    } else if (pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      newAnimIndex = 3;
    }

    if (newAnimIndex != _currLegAnimIndex) {
      _currLegAnimIndex = newAnimIndex;
      _updateAnimation();
      // Сбрасываем состояние ходьбы для новой анимации
      _legsComponent.setWalking(walking);
      _legsMaskComponent.setWalking(walking);
    }

    if (walking) {
      final movement = moveDir * _walkSpeed * dt;
      position += movement;
    }

    if (inputManager!.mousePosition != null) {
      final directionToAim = inputManager!.mousePosition! - position;
      if (directionToAim.length2 > 0) {
        faceAngleRadians = directionToAim.angleToSigned(Vector2(0, -1));
        _turretComponent.angle = -1.0 * 3.14159 + faceAngleRadians;
      }
    }
  }

  void takeDamage(double amount) {
    health = (health - amount).clamp(0, maxHealth);
    _healthBar.updateHealth(health, maxHealth);

    if (health <= 0 && !isDead) {
      die();
    }
  }

  void die() {
    isDead = true;
    removeFromParent();
  }

  void useEnergy(double amount) {
    energy = (energy - amount).clamp(0, maxEnergy);
    _energyBar.updateEnergy(energy, maxEnergy);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isDead) {
      updateMovement(dt);
    }

    if (energy < maxEnergy) {
      energy = (energy + 20 * dt).clamp(0, maxEnergy);
      _energyBar.updateEnergy(energy, maxEnergy);
    }
  }
}
