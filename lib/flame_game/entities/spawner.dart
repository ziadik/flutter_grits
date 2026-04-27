// lib/flame_game/entities/spawner.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/game_entity.dart';
import 'package:flutter_grits/flame_game/entities/pickup.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

enum SpawnItemType {
  healthCanister,
  energyCanister,
  quadDamage,
}

class Spawner extends GameEntity {
  final SpawnItemType spawnItem;
  final PlayerAnimator animator;

  GameEntity? _lastSpawned;
  double _nextSpawnTime = 0;
  static const double spawnDelay = 20.0; // 20 секунд как в JS

  Sprite? _currentSprite;
  List<TrimmedSprite> _animationFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.1;

  Spawner({
    required Vector2 position,
    required this.spawnItem,
    required this.animator,
    required GameWorld gameWorld,
  }) : super(position: position, gameWorld: gameWorld, size: Vector2(64, 64));

  @override
  void onInit() async {
    debugPrint('📦 Spawner created at $position for $spawnItem');
    await _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    // Загружаем анимацию спавнера
    for (int i = 0; i <= 15; i++) {
      final frameName = 'spawner_white_activate_${i.toString().padLeft(4, '0')}.png';
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

    frame.renderCentered(
      canvas,
      Vector2.zero(),
      Size(size.x, size.y),
      null,
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    _currentSprite = Sprite(image);
  }

  @override
  void onUpdate(double dt) {
    super.onUpdate(dt);

    // Анимация
    if (_animationFrames.isNotEmpty) {
      _frameTime += dt;
      if (_frameTime >= _frameDuration) {
        _frameTime = 0;
        _currentFrame = (_currentFrame + 1) % _animationFrames.length;
        _updateSprite(_currentFrame);
      }
    }

    // Логика спавна
    final now = DateTime.now().millisecondsSinceEpoch / 1000;

    if (_lastSpawned == null || _lastSpawned!.isKilled) {
      if (_nextSpawnTime <= now) {
        _spawnItem();
        _nextSpawnTime = now + spawnDelay;
      }
    }
  }

  void _spawnItem() {
    final pickup = PickupItem(
      position: position,
      itemType: _convertSpawnType(),
      animator: animator,
      gameWorld: gameWorld,
    );

    gameWorld.add(pickup);
    _lastSpawned = pickup;

    debugPrint('✨ Spawned ${_convertSpawnType()} at $position');
  }

  String _convertSpawnType() {
    switch (spawnItem) {
      case SpawnItemType.healthCanister:
        return 'HealthCanister';
      case SpawnItemType.energyCanister:
        return 'EnergyCanister';
      case SpawnItemType.quadDamage:
        return 'QuadDamage';
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _currentSprite?.render(canvas, position: Vector2.zero());

    // Визуализация для отладки
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
      paint,
    );
  }
}
