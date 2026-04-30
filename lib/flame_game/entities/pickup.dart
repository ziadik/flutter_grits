// lib/flame_game/entities/pickup.dart
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_grits/flame_game/entities/game_entity.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

class PickupItem extends GameEntity {
  final String itemType;
  final PlayerAnimator animator;

  Sprite? _currentSprite;
  List<TrimmedSprite> _animationFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.1;

  PickupItem({
    required Vector2 position,
    required this.itemType,
    required this.animator,
    required GameWorld gameWorld,
  }) : super(position: position, gameWorld: gameWorld, size: Vector2(48, 48));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Добавляем хитбокс для Flame Collision Detection
    add(CircleHitbox(radius: 24, anchor: Anchor.center));
  }

  @override
  void onInit() async {
    await _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    String baseName;
    int frameCount;

    switch (itemType) {
      case 'HealthCanister':
        baseName = 'health_canister_blue_';
        frameCount = 16;
        break;
      case 'EnergyCanister':
        baseName = 'energy_canister_blue_';
        frameCount = 16;
        break;
      case 'QuadDamage':
        baseName = 'quad_damage_';
        frameCount = 15;
        break;
      default:
        return;
    }

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
      await _updateSprite(0);
    }
  }

  Future<void> _updateSprite(int frameIndex) async {
    if (frameIndex >= _animationFrames.length) return;

    final frame = _animationFrames[frameIndex];
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    frame.renderCentered(canvas, Vector2.zero(), Size(size.x, size.y), null);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    _currentSprite = Sprite(image);
  }

  @override
  void onUpdate(double dt) {
    super.onUpdate(dt);

    if (_animationFrames.isNotEmpty) {
      _frameTime += dt;
      if (_frameTime >= _frameDuration) {
        _frameTime = 0;
        _currentFrame = (_currentFrame + 1) % _animationFrames.length;
        _updateSprite(_currentFrame);
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player && !other.isDead) {
      debugPrint('⚡ [Flame Collision] PickupItem touched by player!');
      _applyEffect(other);
      kill(); // Удаляем предмет после подбора
    }
  }

  @override
  void onTouch(PositionComponent other, Vector2 point, Vector2 impulse) {
    if (other is Player && !other.isDead) {
      _applyEffect(other);
      debugPrint('🎒 [Legacy onTouch] Pickup touched by player');
    }
  }

  void _applyEffect(Player player) {
    switch (itemType) {
      case 'HealthCanister':
        player.health = (player.health + 10).clamp(
          0,
          player.maxHealth,
        ); // JS: +10
        debugPrint('❤️ Player picked up Health: ${player.health}');
        break;
      case 'EnergyCanister':
        player.energy = (player.energy + 10).clamp(
          0,
          player.maxEnergy,
        ); // JS: +10
        debugPrint('🔋 Player picked up Energy: ${player.energy}');
        break;
      case 'QuadDamage':
        player.activateQuadDamage(); // JS: powerUpTime = 30 секунд
        debugPrint('⚡ Player picked up Quad Damage!');
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _currentSprite?.render(canvas, position: Vector2.zero());
  }
}
