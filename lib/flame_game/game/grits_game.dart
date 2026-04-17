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
import 'package:flame/effects.dart';

class TiledGame extends FlameGame {
  late TiledComponent mapComponent;

  TiledGame()
    : super(
        //camera: CameraComponent.withFixedResolution(width: 2048, height: 2048),
      );

  @override
  Future<void> onLoad() async {
    mapComponent = await TiledComponent.load('map1.tmx', Vector2.all(64));
    mapComponent.scale = Vector2.all(1);

    await world.add(mapComponent);

    _centerCameraOnMap(Vector2(800.0, 800.0));
  }

  Future<void> _centerCameraOnMap(Vector2 gameSize) async {
    final mapWidth = mapComponent.size.x;
    final mapHeight = mapComponent.size.y;

    // camera = CameraComponent.withFixedResolution(
    //   world: world,
    //   width: mapWidth,
    //   height: mapHeight,
    // );
    // camera.viewfinder.anchor = Anchor.topLeft;

    final viewWidth = gameSize.x;
    final viewHeight = gameSize.y;

    camera = CameraComponent(
      world: world,
      viewport: FixedSizeViewport(viewWidth, viewHeight),
    );
    camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    _centerCameraOnMap(newSize); // Пересчитываем при изменении
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
