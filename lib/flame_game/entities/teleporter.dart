import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/game_entity.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';
import 'package:flutter_grits/flame_game/effects/player_spawn_effect.dart';

class Teleporter extends GameEntity {
  final Vector2 destination;
  final PlayerAnimator animator;

  Sprite? _currentSprite;
  List<TrimmedSprite> _idleFrames = [];
  List<TrimmedSprite> _activateFrames = [];
  int _currentFrame = 0;
  double _frameTime = 0;
  final double _frameDuration = 1 / 30; // 30 FPS
  bool _isActivating = false;
  double _activationTimer = 0;

  // Для предотвращения многократного телепорта
  final Map<Player, double> _lastTeleportTime = {};
  static const double teleportCooldown = 1.0;

  // Для хранения игрока во время анимации
  Player? _teleportingPlayer;
  bool _isTeleporting = false;

  Teleporter({
    required Vector2 position,
    required this.destination,
    required this.animator,
    required GameWorld gameWorld,
  }) : super(
         position: position,
         gameWorld: gameWorld,
         size: Vector2(128, 128),
       ) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimation();

    // Добавляем хитбокс для коллизий с игроком (уменьшенный размер)
    add(
      RectangleHitbox(
        position: Vector2.zero(),
        anchor: Anchor.center,
        size: Vector2(128, 128), // Уменьшили с 128x128 до 64x64
      ),
    );

    // debugPrint('🌀 Teleporter created at $position -> $destination');
    // debugPrint('   Hitbox size: 64x64');
  }

  @override
  void onInit() async {
    // onInit больше не используем - всё в onLoad
  }

  Future<void> _loadAnimation() async {
    // Загружаем idle анимацию (teleporter_idle_0000.png - teleporter_idle_0015.png)
    for (int i = 0; i <= 15; i++) {
      final frameName = 'teleporter_idle_${i.toString().padLeft(4, '0')}.png';
      final sprite = animator.getSprite(frameName);
      if (sprite != null) {
        _idleFrames.add(sprite);
      }
    }

    // Загружаем activate анимацию (teleporter_activate_0000.png - teleporter_activate_0015.png)
    for (int i = 0; i <= 15; i++) {
      final frameName =
          'teleporter_activate_${i.toString().padLeft(4, '0')}.png';
      final sprite = animator.getSprite(frameName);
      if (sprite != null) {
        _activateFrames.add(sprite);
      }
    }

    // Если есть idle кадры - обновляем спрайт
    if (_idleFrames.isNotEmpty) {
      await _updateSprite(_idleFrames.first);
    }
  }

  Future<void> _updateSprite(TrimmedSprite frame) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    frame.renderCentered(canvas, Vector2.zero(), Size(size.x, size.y), null);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.x.toInt(), size.y.toInt());
    _currentSprite = Sprite(image);
  }

  void _activateTeleporter() {
    if (_activateFrames.isEmpty) {
      debugPrint('⚠️ _activateFrames is empty!');
      return;
    }

    _isActivating = true;
    _activationTimer = 0.5; // 0.5 секунды активации
    _currentFrame = 0; // Сброс на первый кадр анимации активации
    _frameTime = 0;

    debugPrint(
      '🌀 Teleporter activated! Playing ${_activateFrames.length} frames',
    );
  }

  @override
  void onUpdate(double dt) {
    super.onUpdate(dt);

    // Обработка активации
    if (_isActivating) {
      _activationTimer -= dt;

      if (_activationTimer <= 0) {
        // Анимация завершена - телепортируем игрока
        _isActivating = false;
        _completeTeleport();
        return;
      }

      // Анимация активации
      if (_activateFrames.isNotEmpty) {
        _frameTime += dt;
        if (_frameTime >= _frameDuration) {
          _frameTime = 0;
          _currentFrame = (_currentFrame + 1) % _activateFrames.length;
          _updateSprite(_activateFrames[_currentFrame]);
        }
      }
    } else if (!_isTeleporting) {
      // Idle анимация (только если не телепортируем)
      if (_idleFrames.isNotEmpty) {
        _frameTime += dt;
        if (_frameTime >= _frameDuration) {
          _frameTime = 0;
          _currentFrame = (_currentFrame + 1) % _idleFrames.length;
          _updateSprite(_idleFrames[_currentFrame]);
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    debugPrint('🌀 Teleporter onCollisionStart with: ${other.runtimeType}');

    if (other is Player && !_isTeleporting) {
      debugPrint(
        '✅ Player touched teleporter! Starting activation animation...',
      );
      _startTeleportSequence(other);
    } else {
      debugPrint('⚠️ Collision with non-Player: ${other.runtimeType}');
    }
  }

  void teleporterPlayer(Player player) {
    debugPrint('✅ Player touched teleporter! Starting activation animation...');
    _startTeleportSequence(player);
  }

  void _startTeleportSequence(Player player) {
    if (player.isDead) return;

    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final lastTime = _lastTeleportTime[player] ?? 0;

    if (now - lastTime < teleportCooldown) {
      debugPrint('⚠️ Teleport cooldown active for player');
      return;
    }

    // Сохраняем игрока и запускаем анимацию
    _teleportingPlayer = player;
    _isTeleporting = true;
    _lastTeleportTime[player] = now;

    // Активируем анимацию
    _activateTeleporter();

    debugPrint(
      '🌀 Teleport animation started, will teleport after animation completes',
    );
  }

  void _completeTeleport() {
    if (_teleportingPlayer == null) return;

    final player = _teleportingPlayer!;

    // Телепортируем игрока
    player.position = destination;

    debugPrint('✨ Player teleported to $destination');

    // Показываем эффект появления игрока в точке назначения
    _showSpawnEffect(player);

    // Сбрасываем состояние
    _teleportingPlayer = null;
    _isTeleporting = false;

    // Возвращаемся к idle анимации
    if (_idleFrames.isNotEmpty) {
      _currentFrame = 0;
      _updateSprite(_idleFrames.first);
      debugPrint('🌀 Teleporter back to idle animation');
    }
  }

  Future<void> _showSpawnEffect(Player player) async {
    await PlayerSpawnEffect.spawn(
      position: destination,
      animator: player.gameWorld.resourceManager.playerAnimator,
      gameWorld: player.gameWorld,
    );
    debugPrint('🎉 Spawn effect shown at destination');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _currentSprite?.render(canvas, position: Vector2(-size.x / 2, -size.y / 2));

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
