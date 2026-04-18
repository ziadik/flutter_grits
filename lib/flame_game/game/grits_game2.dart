// // lib/game/grits_game.dart
// import 'package:flame/camera.dart';
// import 'package:flame/components.dart';
// import 'package:flame/game.dart';
// import 'package:flame/input.dart';
// import 'package:flame_tiled/flame_tiled.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_grits/flame_game/managers/input_manager.dart';
// import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
// import 'package:flutter_grits/flame_game/game/world/game_world.dart';
// import 'package:flutter_grits/flame_game/components/hud/fps_counter.dart';
// import 'package:flutter_grits/flame_game/components/hud/minimap.dart';
// import 'package:flame/effects.dart';
// import 'package:flutter/material.dart';

// class GritsGame extends FlameGame with KeyboardEvents {
//   late ResourceManager resourceManager;
//   late InputManager inputManager;
//   // late GameWorld gameWorld;
//   late CameraComponent mainCamera;

//   late TiledComponent mapComponent;

//   // Конфигурация камеры
//   static const targetResolution = Size(1920, 1080);
//   static const cameraFollowSpeed = 300.0;
//   static const minZoom = 0.5;
//   static const maxZoom = 2.0;
//   static const defaultZoom = 1.0;

//   bool _isInitialized = false;

//   @override
//   Future<void> onLoad() async {
//     debugPrint('🎮 Загрузка GritsGame...');

//     await _initializeManagers();
//     mapComponent = await TiledComponent.load('map1.tmx', Vector2.all(64));
//     mapComponent.scale = Vector2.all(1);

//     await world.add(mapComponent);
//     //await _createWorld();
//     await _setupCamera();
//     _setupHUD();

//     _isInitialized = true;
//     debugPrint('✅ GritsGame полностью загружена');
//   }

//   Future<void> _initializeManagers() async {
//     debugPrint('📦 Инициализация менеджеров...');

//     resourceManager = ResourceManager();
//     inputManager = InputManager();

//     await resourceManager.loadResources();
//     debugPrint('✅ Ресурсы загружены');
//   }

//   // Future<void> _createWorld() async {
//   //   debugPrint('🌍 Создание игрового мира...');

//   //   gameWorld = GameWorld(
//   //     resourceManager: resourceManager,
//   //     inputManager: inputManager,
//   //   );

//   //   await gameWorld.onLoad();
//   //   await world.add(gameWorld);

//   //   debugPrint('✅ Мир создан: ${gameWorld.mapWidth}x${gameWorld.mapHeight}');
//   // }

//   Future<void> _setupCamera() async {
//     debugPrint('📷 Настройка камеры...');

//     // Создаем камеру с фиксированным вьюпортом
//     mainCamera = CameraComponent(
//       world: world,
//       viewport: FixedSizeViewport(
//         targetResolution.width,
//         targetResolution.height,
//       ),
//     );

//     // Настраиваем видоискатель
//     mainCamera.viewfinder.anchor = Anchor.center;
//     mainCamera.viewfinder.zoom = defaultZoom;

//     // Устанавливаем границы камеры
//     _setupCameraBounds();

//     // Включаем следование за игроком
//     _setupCameraFollow();

//     // Устанавливаем начальную позицию камеры
//     _centerCameraOnPlayer();

//     await add(mainCamera);
//     debugPrint('✅ Камера добавлена');
//   }

//   void _setupCameraBounds() {
//     // Ограничиваем движение камеры границами карты
//     final worldBounds = Rect.fromLTWH(
//       0,
//       0,
//       gameWorld.mapWidth.toDouble(),
//       gameWorld.mapHeight.toDouble(),
//     );

//     // Получаем размеры вьюпорта в мировых координатах с учетом зума
//     final viewportWidth = targetResolution.width / mainCamera.viewfinder.zoom;
//     final viewportHeight = targetResolution.height / mainCamera.viewfinder.zoom;

//     // Вычисляем границы для камеры
//     final minX = viewportWidth / 2;
//     final maxX = gameWorld.mapWidth - viewportWidth / 2;
//     final minY = viewportHeight / 2;
//     final maxY = gameWorld.mapHeight - viewportHeight / 2;

//     // Создаем прямоугольник ограничений
//     final boundsRect = Rect.fromLTWH(minX, minY, maxX - minX, maxY - minY);

//     // Применяем ограничения к видоискателю
//     mainCamera.viewfinder.position.clamp(
//       Vector2(minX, minY),
//       Vector2(maxX, maxY),
//     );
//   }

//   void _setupCameraFollow() {
//     // Настраиваем плавное следование за игроком
//     mainCamera.follow(
//       gameWorld.player,
//       maxSpeed: cameraFollowSpeed,
//       snap: true,
//     );
//   }

//   void _centerCameraOnPlayer() {
//     // Центрируем камеру на игроке
//     final playerPos = gameWorld.player.position;
//     mainCamera.viewfinder.position = playerPos;
//   }

//   void _setupHUD() {
//     debugPrint('🎨 Настройка HUD...');

//     // FPS счетчик (правый верхний угол)
//     final fpsCounter = FpsCounterComponent(
//       position: Vector2(targetResolution.width - 80, 30),
//       anchor: Anchor.topRight,
//     );

//     // Мини-карта (левый нижний угол)
//     final minimap = MinimapComponent(
//       position: Vector2(20, targetResolution.height - 20),
//       size: Vector2(200, 200),
//       world: gameWorld,
//       camera: mainCamera,
//     );

//     // Добавляем HUD на вьюпорт
//     mainCamera.viewport.addAll([fpsCounter, minimap]);
//   }

//   @override
//   void update(double dt) {
//     if (!_isInitialized) return;

//     super.update(dt);

//     // Обновляем систему спавна
//     gameWorld.updateSpawners(dt);

//     // Обновляем HUD элементы
//     _updateHUD();
//   }

//   void _updateHUD() {
//     // Обновляем позицию игрока на мини-карте (автоматически через перерисовку)
//     // Можно добавить дополнительную логику для динамических элементов
//   }

//   @override
//   void render(Canvas canvas) {
//     if (!_isInitialized) return;
//     super.render(canvas);
//   }

//   @override
//   KeyEventResult onKeyEvent(
//     KeyEvent event,
//     Set<LogicalKeyboardKey> keysPressed,
//   ) {
//     if (!_isInitialized) return KeyEventResult.ignored;

//     // Обработка специальных клавиш
//     if (event is KeyDownEvent) {
//       _handleSpecialKeys(event.logicalKey);
//     }

//     inputManager.handleKeyEvent(event);
//     return KeyEventResult.handled;
//   }

//   void _handleSpecialKeys(LogicalKeyboardKey key) {
//     // Камера: возврат к игроку по пробелу
//     if (key == LogicalKeyboardKey.space) {
//       _centerCameraOnPlayer();
//     }

//     // Зум камеры: + и -
//     if (key == LogicalKeyboardKey.equal ||
//         key == LogicalKeyboardKey.numpadAdd) {
//       zoomCamera(mainCamera.viewfinder.zoom + 0.1);
//     }
//     if (key == LogicalKeyboardKey.minus ||
//         key == LogicalKeyboardKey.numpadSubtract) {
//       zoomCamera(mainCamera.viewfinder.zoom - 0.1);
//     }

//     // Сброс зума
//     if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
//       zoomCamera(defaultZoom);
//     }
//   }

//   void zoomCamera(double newZoom) {
//     final clampedZoom = newZoom.clamp(minZoom, maxZoom);
//     mainCamera.viewfinder.zoom = clampedZoom;

//     // Обновляем границы после изменения зума
//     _setupCameraBounds();
//   }

//   // Публичные методы для управления игрой
//   void pauseGame() {
//     paused = true;
//     debugPrint('⏸️ Игра на паузе');
//   }

//   void resumeGame() {
//     paused = false;
//     debugPrint('▶️ Игра продолжена');
//   }

//   void resetGame() {
//     if (!_isInitialized) return;

//     debugPrint('🔄 Сброс игры...');

//     // Сбрасываем ввод
//     inputManager.reset();

//     // Возвращаем игрока на стартовую позицию
//     gameWorld.player.position = Vector2(
//       gameWorld.mapWidth / 2,
//       gameWorld.mapHeight / 2,
//     );
//     gameWorld.player.health = gameWorld.player.maxHealth;
//     gameWorld.player.energy = gameWorld.player.maxEnergy;

//     // Центрируем камеру
//     _centerCameraOnPlayer();

//     debugPrint('✅ Игра сброшена');
//   }

//   // Эффекты камеры
//   void shakeCamera({double intensity = 10.0, double duration = 0.3}) {
//     final shakeEffect = MoveEffect.by(
//       Vector2(
//         (DateTime.now().millisecondsSinceEpoch % 20 - 10).toDouble() *
//             intensity /
//             10,
//         (DateTime.now().millisecondsSinceEpoch % 20 - 10).toDouble() *
//             intensity /
//             10,
//       ),
//       EffectController(duration: duration, infinite: true),
//     );
//     mainCamera.viewfinder.add(shakeEffect);
//   }

//   void smoothZoomTo(double targetZoom, {double duration = 0.5}) {
//     final currentZoom = mainCamera.viewfinder.zoom;
//     final clampedTarget = targetZoom.clamp(minZoom, maxZoom);

//     mainCamera.viewfinder.add(
//       ScaleEffect.to(
//         Vector2.all(clampedTarget),
//         EffectController(duration: duration, curve: Curves.easeInOut),
//       ),
//     );

//     // Обновляем границы после завершения анимации
//     Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
//       _setupCameraBounds();
//     });
//   }

//   // Геттеры для внешнего доступа
//   bool get isGameReady => _isInitialized;
//   Vector2 get playerPosition => gameWorld.player.position;
//   double get playerHealth => gameWorld.player.health;
//   double get playerEnergy => gameWorld.player.energy;
// }
