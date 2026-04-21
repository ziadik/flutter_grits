// lib/entities/player.dart
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/components/health_bar_component.dart';
import 'package:flutter_grits/flame_game/components/energy_bar_component.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

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

class Player extends PositionComponent with HasCollisionDetection {
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
  double _walkSpeed = 200.0; // Было final, теперь изменяемое для Thrusters
  double faceAngleRadians = 0;

  // Анимации (загружаются из ResourceManager)
  final List<List<TrimmedSprite>?> _walkAnimations = [null, null, null, null];
  final List<List<TrimmedSprite>?> _idleAnimations = [null, null, null, null];

  // Компоненты для отрисовки
  late TrimmedSpriteAnimationComponent _legsComponent;
  late TrimmedSpriteAnimationComponent _legsMaskComponent;
  late SpriteComponent _turretComponent;
  late PositionComponent _weaponComponent; // Отображение текущего оружия

  // UI компоненты
  late HealthBarComponent _healthBar;
  late EnergyBarComponent _energyBar;
  late TextComponent _nameLabel;

  // Оружие (3 слота как в JS коде) - опционально, не ломает существующую логику
  final List<WeaponBase?> _weapons = [null, null, null];
  int _selectedWeaponSlot = 0; // По умолчанию слот 0
  bool _isFiringWeapon0 = false;
  bool _isFiringWeapon1 = false;
  bool _isFiringWeapon2 = false;

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

    // Добавляем хитбокс для коллизий
    add(
      RectangleHitbox(
        position: Vector2(0, 0),
        anchor: Anchor.center,
        size: Vector2(64, 64),
      ),
    );
  }

  Future<void> _createComponents() async {
    // Ноги - без смещения, центр игрока
    _legsComponent = TrimmedSpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Маска ног
    _legsMaskComponent = TrimmedSpriteAnimationComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
    );

    // Турель - тоже по центру (убираем смещение)
    _turretComponent = SpriteComponent(
      size: Vector2(playerSize, playerSize),
      position: Vector2.zero(),
      anchor: Anchor.center,
    );

    // Оружие - тоже по центру
    _weaponComponent = PositionComponent(
      size: Vector2(playerSize, playerSize),
      position: Vector2.zero(),
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
      position: Vector2(0, -playerSize / 2 - 22),
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
      _weaponComponent,
      _healthBar,
      _energyBar,
      _nameLabel,
    ]);

    await _loadTurretSprite();
    await _loadWeaponSprite();
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

  Future<void> _loadWeaponSprite() async {
    // Загрузка спрайта оружия будет обновляться при смене оружия
    // _weaponComponent.removeAll(_weaponComponent.children.toList());
  }

  /// Обновить отображение оружия (вызывать при смене оружия)
  Future<void> updateWeaponSprite() async {
    debugPrint('=== updateWeaponSprite() called ===');

    final weapon = selectedWeapon;
    if (weapon == null) {
      debugPrint('No weapon selected, clearing weapon component');
      _weaponComponent.removeAll(_weaponComponent.children.toList());
      return;
    }

    debugPrint('Weapon: ${weapon.displayName}');
    debugPrint('Sprite name: ${weapon.weaponSpriteName}');

    final animator = resourceManager.playerAnimator;
    debugPrint('Animator loaded: ${animator.isLoaded}');

    final weaponSprite = animator.getSprite(weapon.weaponSpriteName);

    if (weaponSprite == null) {
      debugPrint('❌ Weapon sprite NOT FOUND: ${weapon.weaponSpriteName}');
      debugPrint(
        'Available sprites: ${animator.sprites.keys.take(10).toList()}',
      );
      return;
    }

    debugPrint('✅ Weapon sprite found!');
    debugPrint('Sprite size: ${weaponSprite.sprite.srcSize}');
    debugPrint('Using playerSize: $playerSize (128x128)');

    // Отладка размеров спрайта
    debugPrint('=== SPRITE DEBUG ===');
    debugPrint('Sprite name: ${weapon.weaponSpriteName}');
    debugPrint(
      'Raw sprite size: ${weaponSprite.sprite.srcSize.x}x${weaponSprite.sprite.srcSize.y}',
    );
    debugPrint('Trimmed: ${weaponSprite.trimmed}');
    if (weaponSprite.trimmed) {
      debugPrint(
        'Trimmed size: ${weaponSprite.spriteSourceSize.width}x${weaponSprite.spriteSourceSize.height}',
      );
      debugPrint(
        'Source size: ${weaponSprite.sourceSize.width}x${weaponSprite.sourceSize.height}',
      );
      debugPrint(
        'Frame position: ${weaponSprite.frame.left},${weaponSprite.frame.top}',
      );
    }

    // Удаляем старый компонент
    _weaponComponent.removeAll(_weaponComponent.children.toList());

    // Создаем SpriteComponent с правильными размерами
    final weaponSpriteComponent = SpriteComponent(
      size: Vector2(playerSize, playerSize),
      anchor: Anchor.center,
      position: Vector2.zero(),
    );

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    weaponSprite.renderCentered(
      canvas,
      Vector2.zero(),
      Size(playerSize, playerSize),
      null,
    );
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(playerSize.toInt(), playerSize.toInt());
    weaponSpriteComponent.sprite = Sprite(image);

    _weaponComponent.add(weaponSpriteComponent);
    debugPrint('✅ Weapon sprite added successfully');
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

    if (inputManager!.mousePosition != null) {
      final directionToAim = inputManager!.mousePosition! - position;
      if (directionToAim.length2 > 0) {
        faceAngleRadians = directionToAim.angleToSigned(Vector2(0, -1));
        // Исправлен угол поворота турели - убрана лишняя константа
        _turretComponent.angle = faceAngleRadians;
      }
    }
  }

  /// Метод для движения с проверкой коллизий
  void move(Vector2 direction, double dt) {
    if (direction == Vector2.zero()) return;

    final movement = direction.normalized() * _walkSpeed * dt;
    final newPosition = position + movement;

    // Проверка коллизий с миром
    final gameWorld = findParent<GameWorld>();
    if (gameWorld != null) {
      final collidable = gameWorld.isCollidable(newPosition);
      debugPrint('Move check: newPos=($newPosition), collidable=$collidable');

      if (!collidable) {
        position = newPosition;
      } else {
        debugPrint('🚫 COLLISION! Position blocked');
      }
    } else {
      position = newPosition;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Визуализация хитбокса (зеленым, чтобы было видно)
    final halfSize = 32.0; // Размер хитбокса 64x64
    canvas.drawRect(
      Rect.fromLTWH(-halfSize, -halfSize, 64, 64),
      Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Точка центра
    canvas.drawCircle(Offset.zero, 4, Paint()..color = Colors.yellow);

    // Визуализация размера спрайта (128x128) - красным
    final spriteHalfSize = 64.0;
    canvas.drawRect(
      Rect.fromLTWH(-spriteHalfSize, -spriteHalfSize, 128, 128),
      Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
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

  // Getter для _walkSpeed
  double get walkSpeed => _walkSpeed;

  /// Установить скорость ходьбы (для Thrusters)
  void setWalkSpeed(double newSpeed) {
    // Сохраняем ограничение
    _walkSpeed = newSpeed.clamp(100.0, 500.0);
  }

  // ========== Методы для работы с оружием ==========

  /// Установить оружие в слот
  void setWeapon(int slot, WeaponBase? weapon) {
    if (slot < 0 || slot >= _weapons.length) {
      throw ArgumentError('Slot must be 0, 1, or 2');
    }
    _weapons[slot] = weapon;
    weapon?.onInit(this);

    // Если это текущий выбранный слот, обновить отображение
    if (slot == _selectedWeaponSlot) {
      updateWeaponSprite();
    }
  }

  /// Переключить оружие на указанный слот
  void selectWeapon(int slot) {
    if (slot < 0 || slot >= _weapons.length) {
      debugPrint('Invalid weapon slot: $slot');
      return;
    }
    _selectedWeaponSlot = slot;
    debugPrint(
      'Selected weapon slot: $slot - ${_weapons[slot]?.displayName ?? "Empty"}',
    );

    // Обновить отображение оружия
    updateWeaponSprite();
  }

  /// Получить оружие из слота
  WeaponBase? getWeapon(int slot) {
    if (slot < 0 || slot >= _weapons.length) return null;
    return _weapons[slot];
  }

  /// Начать стрельбу из оружия в слоте
  void startFiring(int slot) {
    if (slot == 0) _isFiringWeapon0 = true;
    if (slot == 1) _isFiringWeapon1 = true;
    if (slot == 2) _isFiringWeapon2 = true;
    _updateFiringState(slot);
  }

  /// Прекратить стрельбу из оружия в слоте
  void stopFiring(int slot) {
    if (slot == 0) _isFiringWeapon0 = false;
    if (slot == 1) _isFiringWeapon1 = false;
    if (slot == 2) _isFiringWeapon2 = false;
  }

  /// Обновить состояние стрельбы для оружия
  void _updateFiringState(int slot) {
    final weapon = _weapons[slot];
    if (weapon == null) return;

    final isFiring = slot == 0
        ? _isFiringWeapon0
        : slot == 1
        ? _isFiringWeapon1
        : _isFiringWeapon2;

    if (isFiring) {
      weapon.tryFire(this);
    } else {
      weapon.firing = false;
    }
  }

  /// Добавить снаряд в игровой мир (вызывается из WeaponBase)
  void addToWorld(PositionComponent component) {
    // Находим родительский компонент (GameWorld) и добавляем снаряд
    final parent = findParent<PositionComponent>();
    if (parent != null) {
      parent.add(component);
    }
  }

  // Свойства для активации особых оружий
  bool isShieldActive = false;
  bool isSwordActive = false;
  bool isThrustersActive = false;

  /// Получить текущий выбранный слот оружия
  int get selectedWeaponSlot => _selectedWeaponSlot;

  /// Получить текущее выбранное оружие
  WeaponBase? get selectedWeapon => _weapons[_selectedWeaponSlot];

  @override
  void update(double dt) {
    super.update(dt);

    if (!isDead) {
      updateMovement(dt);

      // Обновляем все оружия
      for (int i = 0; i < _weapons.length; i++) {
        final weapon = _weapons[i];
        if (weapon != null) {
          weapon.onUpdate(this, dt);
          _updateFiringState(i);
        }
      }
    }

    // Восстановление энергии
    if (energy < maxEnergy) {
      energy = (energy + 20 * dt).clamp(0, maxEnergy);
      _energyBar.updateEnergy(energy, maxEnergy);
    }
  }
}
