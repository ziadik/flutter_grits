import 'dart:ui' as ui;
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/game_entity.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/projectiles/projectile_base.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';
import 'package:flutter_grits/flame_game/effects/explosion.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

/// Базовый снаряд для всех оружий
class Bullet extends ProjectileBase {
  final GameWorld gameWorld; // Добавляем ссылку на мир
  Sprite? _currentSprite;
  List<TrimmedSprite> _animationFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.05; // 20 FPS для анимации снаряда
  double _rotationAngle = 0; // Угол поворота снаряда

  Bullet({
    required this.gameWorld,
    required super.position,
    required super.owner,
    required super.direction,
    required super.damage,
    required super.speed,
    required super.lifetime,
    String? spritePattern,
  }) : super(spritePattern: spritePattern ?? 'machinegun_projectile_') {
    // Размер снаряда зависит от типа оружия
    if (spritePattern?.contains('rocket') ?? false) {
      size = Vector2(16, 16);
    } else if (spritePattern?.contains('grenade') ?? false) {
      size = Vector2(12, 12);
    } else {
      size = Vector2(8, 8);
    }

    // Вычисляем угол поворота из направления полета
    if (direction.x != 0 || direction.y != 0) {
      _rotationAngle = atan2(direction.y, direction.x);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimation();

    // Добавляем хитбокс для коллизий
    add(RectangleHitbox(size: size, anchor: Anchor.center));
  }

  Future<void> _loadAnimation() async {
    final animator = owner.resourceManager.playerAnimator;

    // Загружаем анимацию снаряда по паттерну
    final sprites = animator.getSpritesByPattern('${spritePattern}.*\\.png');

    debugPrint(
      '🔫 Bullet: Found ${sprites.length} sprites for pattern: $spritePattern',
    );

    if (sprites.isNotEmpty) {
      _animationFrames = sprites;
      await _updateSprite(0);
    } else {
      debugPrint(
        '⚠️ No projectile sprites found for $spritePattern, using fallback',
      );
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
  void update(double dt) {
    super.update(dt);

    // Анимация снаряда
    if (_animationFrames.isNotEmpty) {
      _frameTime += dt;
      if (_frameTime >= _frameDuration) {
        _frameTime = 0;
        _currentFrame = (_currentFrame + 1) % _animationFrames.length;
        _updateSprite(_currentFrame);
      }
    }

    // Движение снаряда
    final moveVector = direction.normalized() * speed * dt;
    position += moveVector;

    lifetime -= dt;
    if (lifetime <= 0) {
      destroy();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_currentSprite != null) {
      canvas.save();
      // Применяем поворот в центре снаряда
      canvas.translate(0, 0);
      canvas.rotate(_rotationAngle);
      _currentSprite!.render(canvas, position: Vector2.zero());
      canvas.restore();
    } else {
      // Fallback отрисовка для отладки
      canvas.save();
      canvas.translate(0, 0);
      canvas.rotate(_rotationAngle);
      canvas.drawCircle(Offset.zero, size.x / 2, Paint()..color = Colors.red);
      // Линия направления
      canvas.drawLine(
        Offset.zero,
        Offset(size.x, 0),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
      canvas.restore();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // Создаем взрыв при столкновении
    final explosion = ExplosionEffect(
      position: position,
      animator: owner.resourceManager.playerAnimator,
    );
    gameWorld.add(explosion);

    // Звук взрыва
    SoundManager().playSfx(SoundAssets.explode0);

    destroy();
  }

  @override
  void destroy() {
    removeFromParent();
  }
}
