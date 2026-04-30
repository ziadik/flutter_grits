import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

enum GameObjectType {
  energyCanister,
  healthCanister,
  quadDamage,
  teleporter,
  // spawner, // Удалено - больше не используется
}

class GameObjectComponent extends PositionComponent with CollisionCallbacks {
  final GameObjectType type;
  final String name;
  final Map<String, dynamic> properties;
  final PlayerAnimator animator;
  final GameWorld gameWorld; // ✅ Добавляем ссылку на GameWorld

  Sprite? _sprite;
  late List<TrimmedSprite> _animationFrames;
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.1;
  bool _isAnimating = false;
  bool _isCollected = false; // ✅ Флаг для предотвращения повторного подбора

  GameObjectComponent({
    required Vector2 position,
    required this.type,
    required this.name,
    required this.properties,
    required this.animator,
    required this.gameWorld, // ✅ Добавляем gameWorld
    Vector2? size,
  }) : super(position: position) {
    this.size = size ?? Vector2(64, 64);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();

    // debugPrint('📦 GameObjectComponent onLoad START: $type at $position');
    // debugPrint('   Size: $size, Anchor: $anchor');

    // Добавляем хитбокс для коллизий
    final hitbox = CircleHitbox(radius: size.x / 2, anchor: Anchor.center);

    // debugPrint('   Creating hitbox: $hitbox');
    add(hitbox);
    // debugPrint('   Hitbox added! Children count: ${children.length}');

    // debugPrint('📦 GameObjectComponent onLoad END: $type');
  }

  Future<void> _loadSprite() async {
    switch (type) {
      case GameObjectType.energyCanister:
        _loadAnimatedSprite('energy_canister_blue_', 16);
        break;
      case GameObjectType.healthCanister:
        _loadAnimatedSprite('health_canister_blue_', 16);
        break;
      case GameObjectType.quadDamage:
        _loadAnimatedSprite('quad_damage_', 15);
        break;
      case GameObjectType.teleporter:
        _loadAnimatedSprite('teleporter_idle_', 16);
        break;
      default:
        debugPrint('⚠️ Unknown GameObjectType: $type');
        break;
    }
  }

  void _loadAnimatedSprite(String baseName, int frameCount) {
    _animationFrames = [];
    for (int i = 0; i <= frameCount; i++) {
      final frameName = i == 0
          ? '${baseName}0000.png'
          : '${baseName}${i.toString().padLeft(4, '0')}.png';
      final sprite = animator.getSprite(frameName);
      if (sprite != null) {
        _animationFrames.add(sprite);
      }
    }

    if (_animationFrames.isNotEmpty) {
      _isAnimating = true;
      _updateSpriteFromFrame(0);
    }
  }

  Future<void> _updateSpriteFromFrame(int frameIndex) async {
    if (frameIndex >= _animationFrames.length) return;

    final frame = _animationFrames[frameIndex];
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    frame.renderCentered(canvas, Vector2.zero(), Size(size.x, size.y), null);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    _sprite = Sprite(image);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isAnimating && _animationFrames.isNotEmpty) {
      _frameTime += dt;
      if (_frameTime >= _frameDuration) {
        _frameTime = 0;
        _currentFrame = (_currentFrame + 1) % _animationFrames.length;
        _updateSpriteFromFrame(_currentFrame);
      }
    }
  }

  // ✅ Добавляем метод обработки коллизий
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // debugPrint('🎯 [GameObjectComponent] onCollisionStart called!');
    // debugPrint('   Object type: $type');
    // debugPrint('   Object position: $position');
    // debugPrint('   Other type: ${other.runtimeType}');
    // debugPrint('   Other position: ${other.position}');
    // debugPrint('   Is collected: $_isCollected');

    // Игрок уже подобрал этот предмет — игнорируем
    if (_isCollected) {
      debugPrint('   ⚠️ Already collected, ignoring');
      return;
    }

    if (other is Player && !other.isDead) {
      debugPrint('   ✅ Player detected! Applying effect...');
      _applyEffect(other);
      _collect();
    } else {
      debugPrint('   ⚠️ Not a player or player is dead');
    }
  }

  // ✅ Применяем эффект предмета игроку
  void _applyEffect(Player player) {
    switch (type) {
      case GameObjectType.healthCanister:
        player.health = (player.health + 25).clamp(0, player.maxHealth);
        debugPrint('❤️ Player picked up Health: ${player.health}');
        break;
      case GameObjectType.energyCanister:
        player.energy = (player.energy + 10).clamp(0, player.maxEnergy);
        debugPrint('🔋 Player picked up Energy: ${player.energy}');
        break;
      case GameObjectType.quadDamage:
        player.activateQuadDamage();
        debugPrint(
          '⚡ Player picked up Quad Damage! Multiplier: ${player.getDamageMultiplier()}x',
        );
        break;
      case GameObjectType.teleporter:
        debugPrint('🌀 Teleporter object touched (not implemented)');
        break;
    }
  }

  // ✅ Метод подбора предмета
  void _collect() {
    _isCollected = true;

    // Добавляем эффект исчезновения (можно улучшить)
    // Просто удаляем предмет после небольшой задержки
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isMounted && !_isCollected) return;
      removeFromParent();
      debugPrint('✨ GameObjectComponent removed from world: $type');
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Не рисуем, если предмет подобран
    if (_isCollected) return;

    _sprite?.render(canvas, position: Vector2.zero());

    // ✅ Отладочная визуализация хитбокса (зелёный круг)
    canvas.drawCircle(
      Offset(size.x / 2, size.x / 2),
      size.x / 2,

      Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
