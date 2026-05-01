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
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';

/// Базовый снаряд для всех оружий
class Bullet extends ProjectileBase {
  final GameWorld gameWorld; // Добавляем ссылку на мир
  Sprite? _currentSprite;
  List<TrimmedSprite> _animationFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 0.05; // 20 FPS для анимации снаряда
  double _rotationAngle = 0; // Угол поворота снаряда

  // Защита от столкновения с владельцем при вылете
  bool _ignoreOwner = true;
  double _ignoreOwnerTimer = 0.2; // 0.2 секунды игнорирования владельца

  // Флаг для предотвращения двойного уничтожения
  bool _isDestroyed = false;

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
    if (spritePattern?.contains('rocket_launcher_projectile') ?? false) {
      size = Vector2(114, 76);
    } else if (spritePattern?.contains('shotun_projectile') ?? false) {
      size = Vector2(56, 30);
    } else if (spritePattern?.contains('grenade') ?? false) {
      size = Vector2(16, 16);
    } else {
      size = Vector2(48, 46);
    }

    // Вычисляем угол поворота из направления полета
    if (direction.x != 0 || direction.y != 0) {
      _rotationAngle = atan2(direction.y, direction.x);
      _rotationAngle += pi;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimation();
    // Хитбокс создаётся в ProjectileBase.onLoad() с правильными размерами
  }

  Future<void> _loadAnimation() async {
    final animator = owner.resourceManager.playerAnimator;

    // Ждем пока аниматор загрузится
    int attempts = 0;
    while (!animator.isLoaded && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 10));
      attempts++;
    }

    if (!animator.isLoaded) {
      debugPrint('❌ Bullet: PlayerAnimator not loaded after waiting!');
      return;
    }

    debugPrint('🎯 Bullet: Animator loaded, spritePattern = $spritePattern');

    // Загружаем анимацию снаряда по паттерну
    final sprites = animator.getSpritesByPattern('${spritePattern}.*\\.png');

    // debugPrint(
    //   '🔫 Bullet: Found ${sprites.length} sprites for pattern: ${spritePattern}.*\\.png',
    // );

    if (sprites.isEmpty) {
      // Пробуем альтернативный поиск без расширения
      final altSprites = animator.getSpritesByPattern(spritePattern);
      debugPrint('🔍 Alternative search: ${altSprites.length} sprites');

      if (altSprites.isEmpty) {
        debugPrint(
          '⚠️ No projectile sprites found for $spritePattern, using fallback',
        );
        return;
      }

      _animationFrames = altSprites;
    } else {
      _animationFrames = sprites;
    }

    if (_animationFrames.isNotEmpty) {
      // ✅ Автоматически устанавливаем размер из первого спрайта
      final firstSprite = _animationFrames.first;
      final spriteSize = Vector2(
        firstSprite.spriteSourceSize.width,
        firstSprite.spriteSourceSize.height,
      );

      // Обновляем размер компонента
      size = spriteSize;

      // ✅ Создаем хитбокс с правильным размером (вместо updateHitboxSize)
      createHitbox(spriteSize);

      debugPrint('✅ Bullet: size=${size.x}x${size.y}, hitbox created');

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
  void update(double dt) {
    super.update(dt);

    // Уменьшаем таймер игнорирования владельца
    if (_ignoreOwnerTimer > 0) {
      _ignoreOwnerTimer -= dt;
      if (_ignoreOwnerTimer <= 0) {
        _ignoreOwner = false;
      }
    }

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

      // ✅ Перемещаемся в центр компонента (как в MuzzleFlash)
      canvas.translate(size.x / 2, size.y / 2);
      // Поворачиваем на угол направления полёта
      canvas.rotate(_rotationAngle);
      // Возвращаемся обратно и рисуем спрайт с учетом смещения
      canvas.translate(-size.x / 2, -size.y / 2);

      // Рисуем спрайт
      _currentSprite!.render(canvas, position: Vector2.zero());

      canvas.restore();
    } else {
      // Fallback отрисовка для отладки
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_rotationAngle);
      canvas.translate(-size.x / 2, -size.y / 2);

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2,
        Paint()..color = Colors.red,
      );
      // Линия направления
      canvas.drawLine(
        Offset(size.x / 2, size.y / 2),
        Offset(
          size.x / 2 + cos(_rotationAngle) * size.x,
          size.y / 2 + sin(_rotationAngle) * size.y,
        ),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
      canvas.restore();
    }

    // ✅ Визуализация круглого хитбокса (синий круг)
    if (hitbox is CircleHitbox) {
      final circleHitbox = hitbox as CircleHitbox;
      final radius = circleHitbox.radius;

      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_rotationAngle);
      canvas.translate(-size.x / 2, -size.y / 2);

      // Рисуем круглый хитбокс
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        radius,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
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
    // ✅ СРОЧНАЯ ПРОВЕРКА - немедленно прерываем если уже уничтожена
    if (_isDestroyed) {
      return; // Без логов - это происходит каждый кадр
    }

    super.onCollisionStart(intersectionPoints, other);

    debugPrint(
      '🔫 Bullet onCollisionStart with: ${other.runtimeType} at ${other.position}',
    );

    // ✅ Игнорируем столкновение с игроком-владельцем в первые 0.2 сек после вылета
    if (other is Player && other == owner && _ignoreOwner) {
      debugPrint('   ⚠️ Bullet hit owner (ignore period) - ignoring');
      return;
    }

    // ✅ Игнорируем столкновение с другими пулями
    if (other is Bullet) {
      debugPrint('   ⚠️ Bullet hit another bullet - ignoring');
      return;
    }

    // ✅ Игнорируем стены с флагом projectileignore
    if (other is CollisionBlock) {
      if (other.collisionFlags.contains('projectileignore')) {
        debugPrint(
          '   ⚠️ Bullet hit projectileignore wall at ${other.position} - ignoring',
        );
        return;
      }

      // ✅ СТОЛКНОВЕНИЕ СО СТЕННОЙ - создаем взрыв и уничтожаем пулю
      final collisionPoint = intersectionPoints.isNotEmpty
          ? intersectionPoints.first
          : position;

      debugPrint('   ✅ Bullet hit WALL at $collisionPoint - DESTROYING');

      final explosion = ExplosionEffect(
        position: collisionPoint,
        animator: owner.resourceManager.playerAnimator,
      );
      gameWorld.add(explosion);
      SoundManager().playSfx(SoundAssets.explode0);

      destroy();
      return;
    }

    // ✅ Для ВСЕХ остальных объектов - игнорируем (только стены должны вызывать столкновение)
    debugPrint(
      '   ⚠️ Bullet hit ${other.runtimeType} - ignoring (NOT DESTROYING)',
    );
  }

  @override
  void destroy() {
    if (_isDestroyed) {
      debugPrint('💥 Bullet.destroy() already called - ignoring');
      return;
    }

    debugPrint('💥 Bullet.destroy() called!');
    _isDestroyed = true;
    removeFromParent();
  }
}
