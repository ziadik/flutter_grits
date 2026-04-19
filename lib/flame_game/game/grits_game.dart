// lib/game/grits_game.dart
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/components/hud/fps_counter.dart';
import 'package:flutter_grits/flame_game/components/hud/minimap.dart';
import 'package:flutter_grits/flame_game/components/hud/weapon_indicator.dart';
import 'package:flame/effects.dart';

class GritsGame extends FlameGame with KeyboardEvents {
  final ResourceManager resourceManager;
  late InputManager inputManager;
  late GameWorld gameWorld; // Явно храним ссылку на GameWorld

  GritsGame({required this.resourceManager}) : super();

  @override
  Future<void> onLoad() async {
    // Создаем менеджер ввода
    inputManager = InputManager();

    // Создаем игровой мир
    gameWorld = GameWorld(
      resourceManager: resourceManager,
      inputManager: inputManager,
    );

    // Устанавливаем мир
    world = gameWorld;

    // Настраиваем камеру после загрузки мира
    await _setupCamera();
  }

  Future<void> _setupCamera() async {
    // Ждем загрузки мира
    await gameWorld.onLoad();

    // Создаем камеру с фиксированным размером вьюпорта
    camera = CameraComponent(
      viewport: FixedSizeViewport(800, 800),
      world: gameWorld,
    );

    // Настраиваем следование за игроком
    camera.follow(gameWorld.player);

    // Добавляем HUD элементы на вьюпорт (не двигаются с миром!)
    _setupHUD();

    // Добавляем камеру в игру
    await add(camera);
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
    inputManager.handleKeyEvent(event);
    return KeyEventResult.handled;
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

  /// Обработка переключения оружия клавишами 1, 2, 3
  void _handleWeaponSwitching() {
    final slot = inputManager.getWeaponSlotKeyPress();
    if (slot != null && gameWorld.player != null) {
      gameWorld.player.selectWeapon(slot);
    }
  }
}

// class GritsGame extends FlameGame with KeyboardEvents {
//   late ResourceManager resourceManager;
//   late InputManager inputManager;
//   late GameWorld gameWorld;
//   late CameraComponent mainCamera;

//   // Конфигурация камеры
//   static const targetResolution = Size(1920, 1080); // Целевое разрешение
//   static const cameraZoom = 1.0;
//   static const cameraFollowSpeed = 300.0; // Макс. скорость следования

//   @override
//   Future<void> onLoad() async {
//     debugPrint('🎮 Загрузка игры...');

//     // 1. Инициализация менеджеров
//     resourceManager = ResourceManager();
//     inputManager = InputManager();
//     await resourceManager.loadResources();
//     debugPrint('✅ Менеджеры загружены');

//     // 2. Создание мира
//     gameWorld = GameWorld(
//       resourceManager: resourceManager,
//       inputManager: inputManager,
//     );
//     debugPrint('🌍 Мир создан');

//     // 3. Загружаем мир ПЕРВЫМ (чтобы player и карта были готовы)
//     await gameWorld.onLoad();
//     debugPrint('✅ Мир загружен: ${gameWorld.mapWidth}x${gameWorld.mapHeight}');

//     // // 4. Создание камеры с фиксированным разрешением (после загрузки мира)
//     // mainCamera = CameraComponent.withFixedResolution(
//     //   world: gameWorld,
//     //   width: targetResolution.width,
//     //   height: targetResolution.height,
//     // );
//     // debugPrint(
//     //   '📷 Камера создана: ${targetResolution.width}x${targetResolution.height}',
//     // );

//     // // 5. Настройка видоискателя - ЗУМ для отображения карты!
//     // mainCamera.viewfinder.anchor = Anchor.center;
//     // // Вычисляем зум, чтобы карта помещалась в экран
//     // final zoomX = targetResolution.width / gameWorld.mapWidth;
//     // final zoomY = targetResolution.height / gameWorld.mapHeight;
//     // final zoom = zoomX < zoomY ? zoomX : zoomY;
//     // mainCamera.viewfinder.zoom = zoom;
//     // mainCamera.viewfinder.position = Vector2(
//     //   gameWorld.mapWidth / 2 - targetResolution.width / 2 / zoom,
//     //   gameWorld.mapHeight / 2 - targetResolution.height / 2 / zoom,
//     // );
//     // debugPrint(
//     //   '🔍 Зум установлен: $zoom (игрок: ${gameWorld.player.position})',
//     // );
//     // debugPrint('🔍 Камера установлена на: ${mainCamera.viewfinder.position}');

//     // // 6. Установка границ камеры (ограничиваем картой)
//     // _setupCameraBounds();

//     // // 7. Включаем автоматическое следование за игроком
//     // _setupCameraFollow();
//     // debugPrint('📍 Следование за игроком включено');

//     // // 8. Добавляем HUD элементы на вьюпорт
//     // _setupHUD();

//     // // 9. Добавляем камеру в игру
//     // await add(mainCamera);
//     // debugPrint('✅ Камера добавлена в игру');

//     // // 10. Добавляем эффект появления (опционально)
//     // _addEntryEffect();
//     // debugPrint('✅ Игра готова к запуску');
//   }

//   void _setupCameraBounds() {
//     // Ограничиваем движение камеры границами карты
//     // Примечание: setBounds в Flame принимает Shape, а не Rect
//     // Здесь можно реализовать кастомные границы, если нужно
//   }

//   void _setupCameraFollow() {
//     // ВСТРОЕННОЕ СЛЕДОВАНИЕ - не нужно ручного обновления в update!
//     mainCamera.follow(
//       gameWorld.player,
//       maxSpeed: cameraFollowSpeed,
//       snap: true, // Мгновенное прилипание при старте
//     );
//   }

//   void _setupHUD() {
//     // HUD компоненты добавляются на вьюпорт - они НЕ двигаются с миром

//     // FPS счетчик в правом верхнем углу
//     final fpsCounter = FpsCounterComponent(
//       position: Vector2(targetResolution.width - 100, 50),
//       anchor: Anchor.topRight,
//     );

//     // Мини-карта в левом нижнем углу
//     final minimap = MinimapComponent(
//       position: Vector2(150, targetResolution.height - 150),
//       size: Vector2(200, 200),
//       world: gameWorld,
//       camera: mainCamera,
//     );

//     // Полоски здоровья/энергии игрока (статичные, не следуют за игроком)
//     final playerStats = _createPlayerStatsHUD();

//     mainCamera.viewport.addAll([fpsCounter, minimap, playerStats]);
//   }

//   PositionComponent _createPlayerStatsHUD() {
//     // Создаем контейнер для статистики игрока в левом верхнем углу
//     final statsContainer = PositionComponent(
//       position: Vector2(20, 20),
//       anchor: Anchor.topLeft,
//     );

//     // Здесь можно добавить статическое отображение здоровья/энергии
//     // (альтернатива полоскам над головой)
//     return statsContainer;
//   }

//   void _addEntryEffect() {
//     // Плавное появление камеры (эффект "наезда")
//     mainCamera.viewfinder.add(
//       ScaleEffect.by(
//         Vector2.all(cameraZoom - 1),
//         EffectController(duration: 1.0, curve: Curves.easeOutCubic),
//       ),
//     );
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);

//     // Камера автоматически следует за игроком через follow()!
//     // Никакого ручного управления camera.viewfinder.position не требуется!

//     // Обновляем систему спавна через мир
//     gameWorld.updateSpawners(dt);
//   }

//   @override
//   KeyEventResult onKeyEvent(
//     KeyEvent event,
//     Set<LogicalKeyboardKey> keysPressed,
//   ) {
//     inputManager.handleKeyEvent(event);
//     return KeyEventResult.handled;
//   }

//   // Метод для сброса игры
//   void reset() {
//     // Проверяем, что мир и игрок загружены
//     if (!gameWorld.isLoaded) {
//       debugPrint('GameWorld ещё не загружен, пропускаем сброс');
//       return;
//     }

//     // Перезагрузка мира
//     gameWorld.player.position = Vector2(
//       gameWorld.mapWidth / 2,
//       gameWorld.mapHeight / 2,
//     );
//     gameWorld.player.health = gameWorld.player.maxHealth;
//     gameWorld.player.energy = gameWorld.player.maxEnergy;
//   }
// }

// Интерфейс для компонентов, которые можно отключать
abstract class CullableComponent {
  bool shouldUpdate = true;
  Rect toRect();
}
