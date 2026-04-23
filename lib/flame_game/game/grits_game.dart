// lib/game/grits_game.dart
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart' show KeyboardEvents, PointerMoveCallbacks;
import 'package:flame/src/events/messages/pointer_move_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide PointerMoveEvent;
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/components/hud/fps_counter.dart';
import 'package:flutter_grits/flame_game/components/hud/minimap.dart';
import 'package:flutter_grits/flame_game/components/hud/weapon_indicator.dart';
import 'package:flutter_grits/flame_game/components/debug/collision_debug_overlay.dart';
import 'package:flutter_grits/flame_game/components/crosshair.dart';

class GritsGame extends FlameGame
    with
        HasCollisionDetection,
        KeyboardEvents,
        // HoverCallbacks,
        PointerMoveCallbacks {
  final ResourceManager resourceManager;
  late InputManager inputManager;
  late GameWorld gameWorld;
  CollisionDebugOverlay? _collisionDebugOverlay;
  bool _debugModeEnabled = false;

  late Vector2 _mouseWorldPosition;
  late CrosshairComponent _crosshair;
  Vector2 _lastMouseScreenPos = Vector2.zero();

  GritsGame({required this.resourceManager}) : super() {
    _mouseWorldPosition = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    // Создаем менеджер ввода
    inputManager = InputManager();

    // Создаем игровой мир
    gameWorld = GameWorld(
      resourceManager: resourceManager,
      inputManager: inputManager,
    );

    // Добавляем мир вручную (не через world)
    await add(gameWorld);

    // Ждем пока игрок будет готов (с таймаутом)
    await _waitForPlayer();

    // После загрузки настраиваем камеру
    await _setupCamera();

    // Создаем прицел
    _crosshair = CrosshairComponent();
    camera.viewport.add(_crosshair);
  }

  Future<void> _waitForPlayer() async {
    // Ждем пока игрок будет доступен (макс 3 секунды)
    int attempts = 0;
    while (attempts < 30) {
      if (gameWorld.player.isLoaded) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> _setupCamera() async {
    // Проверяем что игрок загружен
    if (!gameWorld.player.isLoaded) {
      await gameWorld.player.onLoad();
    }

    // Создаем камеру с фиксированным размером вьюпорта
    camera = CameraComponent(
      viewport: FixedSizeViewport(800, 800),
      world: gameWorld,
    );

    // Настраиваем следование за игроком
    camera.follow(gameWorld.player);

    // Добавляем камеру в игру
    await add(camera);

    // Настраиваем HUD после добавления камеры
    _setupHUD();

    // Запускаем фоновую музыку
    await SoundManager().playBackgroundMusic(SoundAssets.bgGame);
  }

  void _setupHUD() {
    // FPS счетчик в правом верхнем углу
    final fpsCounter = FpsCounterComponent(
      position: Vector2(750, 30),
      anchor: Anchor.topRight,
    );
    camera.viewport.add(fpsCounter);

    // Мини-карта в левом нижнем углу
    final minimap = MinimapComponent(
      position: Vector2(20, 750),
      size: Vector2(180, 180),
      world: gameWorld,
      camera: camera,
    );
    camera.viewport.add(minimap);

    // Индикатор оружия в левом верхнем углу
    // Ждем немного пока игрок загрузится
    Future.delayed(const Duration(milliseconds: 100), () {
      if (gameWorld.player.isLoaded) {
        _addWeaponIndicator();
      } else {
        // Если игрок еще не готов, пробуем позже
        gameWorld.player.onLoad().then((_) => _addWeaponIndicator());
      }
    });
  }

  void _addWeaponIndicator() {
    // Индикатор оружия
    WeaponIndicatorComponent.create(
      player: gameWorld.player,
      position: Vector2(20, 20),
    ).then((indicator) {
      camera.viewport.add(indicator);
      debugPrint('✅ Weapon indicator added to HUD');
    });
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    // Обновляем размер вьюпорта если камера уже создана
    if (camera != null && camera.viewport is FixedSizeViewport) {
      (camera.viewport as FixedSizeViewport).size = newSize;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Обработка F1 - переключение отладочного оверлея
    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.f1)) {
      _toggleDebugOverlay();
      return KeyEventResult.handled;
    }

    // Передаем остальные события в InputManager
    inputManager.handleKeyEvent(event);
    return KeyEventResult.handled;
  }

  void _toggleDebugOverlay() {
    _debugModeEnabled = !_debugModeEnabled;

    if (_debugModeEnabled) {
      if (_collisionDebugOverlay == null) {
        _collisionDebugOverlay = CollisionDebugOverlay(
          gameWorld: gameWorld,
          showPlayerBounds: true,
          showCollisionTiles: true,
          showInteractiveItems: true,
        );
      }

      // Добавляем оверлей В МИР, а не на камеру
      if (!gameWorld.children.contains(_collisionDebugOverlay)) {
        gameWorld.add(_collisionDebugOverlay!);
        debugPrint('🔍 Отладочный режим: ВКЛЮЧЕН');
      }
    } else {
      // Удаляем оверлей
      if (_collisionDebugOverlay != null) {
        _collisionDebugOverlay?.removeFromParent();
        debugPrint('❌ Отладочный режим: ВЫКЛЮЧЕН');
      }
    }
  }

  /// Обработка переключения оружия клавишами 1, 2, 3
  void _handleWeaponSwitching() {
    final slot = inputManager.getWeaponSlotKeyPress();
    if (slot != null && gameWorld.player != null) {
      gameWorld.player.selectWeapon(slot);
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    // Сохраняем экранные координаты
    _lastMouseScreenPos = Vector2(event.localPosition.x, event.localPosition.y);

    // Конвертируем в мировые координаты через камеру
    final worldPos = camera.globalToLocal(_lastMouseScreenPos);

    // Обновляем InputManager с мировыми координатами
    inputManager.handleMouseMove(worldPos);

    // Обновляем прицел (экранные координаты)
    _crosshair.updatePosition(_lastMouseScreenPos);
    //super.onPointerMove(event);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Обновляем систему спавна
    if (gameWorld != null) {
      gameWorld.updateSpawners(dt);

      // Обработка переключения оружия
      _handleWeaponSwitching();
    }

    // Обновляем InputManager (для очистки justPressedKeys)
    inputManager.update(dt);
  }
}
