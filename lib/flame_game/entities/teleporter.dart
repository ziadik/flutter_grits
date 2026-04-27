// lib/flame_game/entities/teleporter.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/game_entity.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

class Teleporter extends GameEntity {
  final Vector2 destination;
  final PlayerAnimator animator;

  Sprite? _currentSprite;
  List<TrimmedSprite> _animationFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.1;

  // Для предотвращения многократного телепорта
  final Map<Player, double> _lastTeleportTime = {};
  static const double teleportCooldown = 1.0;

  Teleporter({
    required Vector2 position,
    required this.destination,
    required this.animator,
    required GameWorld gameWorld,
  }) : super(position: position, gameWorld: gameWorld, size: Vector2(64, 64));

  @override
  void onInit() async {
    debugPrint('🌀 Teleporter created at $position -> $destination');
    await _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    // Загружаем анимацию телепорта (teleporter_idle_0000.png - teleporter_idle_0015.png)
    for (int i = 0; i <= 15; i++) {
      final frameName = 'teleporter_idle_${i.toString().padLeft(4, '0')}.png';
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

    // Анимация
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
  void onTouch(PositionComponent other, Vector2 point, Vector2 impulse) {
    final Player player = other as Player;
    if (player.isDead) return;

    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final lastTime = _lastTeleportTime[player] ?? 0;

    if (now - lastTime >= teleportCooldown) {
      _lastTeleportTime[player] = now;

      // Телепортируем игрока
      player.position = destination;

      debugPrint('✨ Player teleported to $destination');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _currentSprite?.render(canvas, position: Vector2.zero());

    // Визуализация для отладки
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
      paint,
    );
  }
}
