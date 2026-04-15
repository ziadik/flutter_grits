// lib/game/grits_game.dart
import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';

class GritsGame extends FlameGame with KeyboardEvents {
  late TiledComponent tiledMapComponent;
  late CameraComponent cameraComponent;
  late Player player;
  late ResourceManager resourceManager;
  late InputManager inputManager;

  static const double tileSize = 64.0;

  int mapWidth = 0;
  int mapHeight = 0;

  @override
  Future<void> onLoad() async {
    // Инициализация менеджеров
    resourceManager = ResourceManager();
    inputManager = InputManager();

    await resourceManager.loadResources();

    // Загрузка Tiled карты
    tiledMapComponent = await TiledComponent.load(
      'maps/small_map1.tmx',
      Vector2.all(tileSize),
    );
    await add(tiledMapComponent);

    // Получение размеров карты - ИСПРАВЛЕНО для новых версий flame_tiled
    // В новых версиях TiledComponent имеет свойство 'tileMap' (с маленькой 'm')
    // или нужно получить размер через компонент
    final mapSize = tiledMapComponent.size;
    mapWidth = (mapSize.x * tileSize).toInt();
    mapHeight = (mapSize.y * tileSize).toInt();

    // Создание игрока в центре карты
    final startPosition = Vector2(
      (mapSize.x / 2) * tileSize,
      (mapSize.y / 2) * tileSize,
    );

    player = Player(position: startPosition, resourceManager: resourceManager);
    await add(player);

    // Настройка камеры
    cameraComponent = CameraComponent(
      world: world,
      viewport: FixedResolutionViewport(resolution: Vector2(size.x, size.y)),
    );

    // Центрирование камеры на игроке
    cameraComponent.follow(player);
    cameraComponent.viewfinder.anchor = Anchor.center;

    await add(cameraComponent);

    // Адаптация к размерам экрана
    _adjustCameraZoom();
  }

  void _adjustCameraZoom() {
    final scaleX = size.x / (mapWidth);
    final scaleY = size.y / (mapHeight);
    final zoom = math.min(scaleX, scaleY).clamp(0.5, 2.0);
    cameraComponent.viewfinder.zoom = zoom;
  }

  @override
  void update(double dt) {
    super.update(dt);
    inputManager.update(dt);

    // Обновление направления игрока на основе ввода
    final moveDirection = inputManager.moveDirection;
    if (moveDirection != Vector2.zero()) {
      final angle = moveDirection.angleToSigned(Vector2(0, -1));
      player.move(moveDirection, dt);
      player.angle = angle;
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
  void onMount() {
    super.onMount();
  }
}
