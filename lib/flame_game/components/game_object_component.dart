// lib/flame_game/components/game_object_component.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

enum GameObjectType {
  energyCanister,
  healthCanister,
  quadDamage,
  teleporter,
  spawner,
}

class GameObjectComponent extends PositionComponent {
  final GameObjectType type;
  final String name;
  final Map<String, dynamic> properties;
  final PlayerAnimator animator;
  
  Sprite? _sprite;
  late List<TrimmedSprite> _animationFrames;
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.1;
  bool _isAnimating = false;

  GameObjectComponent({
    required Vector2 position,
    required this.type,
    required this.name,
    required this.properties,
    required this.animator,
    Vector2? size,
  }) : super(position: position) {
    this.size = size ?? Vector2(64, 64);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();
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
      case GameObjectType.spawner:
        _loadAnimatedSprite('spawner_white_activate_', 16);
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
    
    frame.renderCentered(
      canvas,
      Vector2.zero(),
      Size(size.x, size.y),
      null,
    );
    
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _sprite?.render(canvas, position: Vector2.zero());
  }
}
