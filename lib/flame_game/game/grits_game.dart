// lib/game/grits_game.dart
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart'
    show
        KeyboardEvents,
        PointerMoveCallbacks,
        TapCallbacks,
        TapDownEvent,
        TapUpEvent;

import 'package:flame/src/events/messages/pointer_move_event.dart';
import 'package:flutter/gestures.dart' hide PointerMoveEvent;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide PointerMoveEvent;
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/components/hud/fps_counter.dart';
import 'package:flutter_grits/flame_game/components/hud/minimap.dart';
import 'package:flutter_grits/flame_game/components/hud/weapon_indicator.dart';
import 'package:flutter_grits/flame_game/components/hud/settings_button.dart';
import 'package:flutter_grits/flame_game/components/debug/collision_debug_overlay.dart';
import 'package:flutter_grits/flame_game/components/crosshair.dart';
import 'package:flutter_grits/flame_game/widgets/settings_dialog.dart';
import 'package:flutter_grits/main.dart' show navigatorKey;
import 'package:flutter/material.dart' hide PointerMoveEvent;

class GritsGame extends FlameGame
    with
        KeyboardEvents,
        TapCallbacks,
        PointerMoveCallbacks,
        HasCollisionDetection {
  final ResourceManager resourceManager;
  late InputManager inputManager;
  late GameWorld gameWorld;
  CollisionDebugOverlay? _collisionDebugOverlay;
  bool _debugModeEnabled = false;

  late CrosshairComponent _crosshair;
  Vector2 _lastMouseScreenPos = Vector2.zero();
  BuildContext? _gameContext;
  SettingsButtonComponent? _settingsButton;

  GritsGame({required this.resourceManager}) : super();

  /// Метод для показа диалога настроек из Flame компонента
  void showSettingsDialog() {
    _showSettingsDialog();
  }

  void _showSettingsDialog() {
    // Используем глобальный navigatorKey для показа диалога
    try {
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: SettingsDialog(onClosed: () {})),
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error showing settings dialog: $e');
    }
  }

  @override
  void onMount() {
    super.onMount();
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

    // Настраиваем мгновенное слежение за игроком (без плавности)
    camera.follow(
      gameWorld.player,
      // anchor: Anchor.center,
      maxSpeed: 10000, // Максимально высокая скорость
    );

    // Добавляем камеру в игру
    await add(camera);

    // Настраиваем HUD после добавления камеры
    _setupHUD();

    // Запускаем фоновую музыку только после первого взаимодействия пользователя
    // SoundManager().playBackgroundMusic(SoundAssets.bgGame);
    // Музыка запустится при первом клике/нажатии через onUserInteraction()
  }

  void _setupHUD() {
    final screenSize = camera.viewport.size;

    // FPS счетчик
    final fpsCounter = FpsCounterComponent(
      position: Vector2(screenSize.x - 50, 30),
      anchor: Anchor.topRight,
    );
    camera.viewport.add(fpsCounter);

    // Кнопка настроек (слева от FPS)
    _settingsButton = SettingsButtonComponent(
      onSettingsRequested: () {
        // Показываем диалог через Overlay
        _showSettingsDialog();
      },
      position: Vector2(screenSize.x - 90, 30),
    );
    camera.viewport.add(_settingsButton!);

    // Мини-карта
    final minimap = MinimapComponent(
      position: Vector2(20, screenSize.y - 40),
      size: Vector2(180, 180),
      world: gameWorld,
      camera: camera,
    );
    camera.viewport.add(minimap);

    // Индикатор оружия
    Future.delayed(const Duration(milliseconds: 100), () {
      if (gameWorld.player.isLoaded) {
        _addWeaponIndicator();
      } else {
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
      // debugPrint('✅ Weapon indicator added to HUD');
    });
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    // Обновляем размер вьюпорта если камера уже создана
    if (camera != null && camera.viewport is FixedSizeViewport) {
      (camera.viewport as FixedSizeViewport).size = newSize;
    }

    // Обновляем позицию кнопки настроек при изменении размера экрана
    if (_settingsButton?.isMounted ?? false) {
      _settingsButton!.position = Vector2(newSize.x - 90, 30);
    }
  }

  /// Получить BuildContext из Flutter widget tree
  BuildContext? findGameWidgetContext() {
    // Ищем через GameWidget глобальный ключ
    // Это временное решение, можно улучшить через передачу контекста из main.dart
    return null;
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
        // debugPrint('🔍 Отладочный режим: ВКЛЮЧЕН');
      }
    } else {
      // Удаляем оверлей
      if (_collisionDebugOverlay != null) {
        _collisionDebugOverlay?.removeFromParent();
        // debugPrint('❌ Отладочный режим: ВЫКЛЮЧЕН');
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

  // ==================== ОБРАБОТКА МЫШИ ====================

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastMouseScreenPos = Vector2(event.localPosition.x, event.localPosition.y);

    // Конвертируем в мировые координаты
    final worldPos = camera.globalToLocal(_lastMouseScreenPos);

    inputManager.handleMouseMove(worldPos);
    _crosshair.updatePosition(_lastMouseScreenPos);

    // debugPrint(
    //   '🖱️ Mouse move - screen: $_lastMouseScreenPos, world: $worldPos',
    // );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // debugPrint('🖱️ Mouse DOWN - button: ${event.deviceKind}');

    final worldPos = camera.globalToLocal(_lastMouseScreenPos);

    if (event.deviceKind == PointerDeviceKind.mouse) {
      inputManager.handleMousePress(worldPos);
      inputManager.handleMouseButtonPress(1);
      // debugPrint('🎯 Left mouse DOWN at world: $worldPos');
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    // debugPrint('🖱️ Mouse UP - button: ${event.deviceKind}');

    if (event.deviceKind == PointerDeviceKind.mouse) {
      inputManager.handleMouseRelease();
      inputManager.handleMouseButtonRelease(1);
      // debugPrint('🎯 Left mouse UP');
    }
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
