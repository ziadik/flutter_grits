// lib/game/world/game_world.dart
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/systems/spawn_system.dart';
import 'package:flutter_grits/flame_game/components/environment_component.dart';
import 'package:flutter/foundation.dart';

class GameWorld extends World {
  final ResourceManager resourceManager;
  final InputManager inputManager;

  late Player player;
  late TiledComponent tiledMap;
  late SpawnSystem spawnSystem;
  late CameraComponent camera;

  int mapWidth = 0;
  int mapHeight = 0;

  // Список всех спавнеров для быстрого доступа
  final List<EnvironmentComponent> spawners = [];

  GameWorld({required this.resourceManager, required this.inputManager});

  @override
  Future<void> onLoad() async {
    await _loadMap();
    await _createPlayer();
    _initSpawnSystem();
    _loadEnvironmentObjects();
  }

  Future<void> _loadMap() async {
    debugPrint('🗺️ Загрузка карты...');

    // Загрузка Tiled карты
    tiledMap = await TiledComponent.load(
      'map1.tmx',
      Vector2.all(Player.playerSize),
    );
    await add(tiledMap);
    debugPrint('✅ TiledComponent добавлен к GameWorld');

    // Получение размеров карты в пикселях (tiledMap.size уже возвращает размер в пикселях!)
    mapWidth = tiledMap.size.x.toInt();
    mapHeight = tiledMap.size.y.toInt();

    debugPrint(
      '✅ Карта загружена: ${tiledMap.size.x.toInt()}x${tiledMap.size.y.toInt()} пикселей',
    );

    _centerCameraOnMap(Vector2.all(800));
    await add(camera);
    debugPrint('✅ Камера добавлена к GameWorld');
  }

  Future<void> _centerCameraOnMap(Vector2 gameSize) async {
    final mapWidth = tiledMap.size.x;
    final mapHeight = tiledMap.size.y;

    final viewWidth = gameSize.x;
    final viewHeight = gameSize.y;

    camera = CameraComponent(
      world: this,
      viewport: FixedSizeViewport(viewWidth, viewHeight),
    );
    camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
    camera.viewfinder.anchor = Anchor.center;
  }

  Future<void> _createPlayer() async {
    // Получаем стартовую позицию из карты или используем центр
    final startPosition =
        _getStartPositionFromMap() ?? Vector2(mapWidth / 2, mapHeight / 2);

    player = Player(position: startPosition, resourceManager: resourceManager);

    // Подписываем игрока на ввод
    player.inputManager = inputManager;

    await add(player);
  }

  Vector2? _getStartPositionFromMap() {
    // Ищем spawnPoint на карте Tiled
    final spawnLayer = tiledMap.tileMap.getLayer<ObjectGroup>('SpawnPoints');
    if (spawnLayer != null && spawnLayer.objects.isNotEmpty) {
      final spawnPoint = spawnLayer.objects.first;
      return Vector2(spawnPoint.x, spawnPoint.y);
    }
    return null;
  }

  void _initSpawnSystem() {
    spawnSystem = SpawnSystem();
  }

  void _loadEnvironmentObjects() {
    // Загружаем объекты окружения из Tiled карты
    final objectsLayer = tiledMap.tileMap.getLayer<ObjectGroup>('Environment');
    if (objectsLayer == null) return;

    for (final obj in objectsLayer.objects) {
      final type = obj.properties['Type']?.toString();
      if (type == null) continue;

      final environmentType = _parseEnvironmentType(type);
      if (environmentType != null) {
        final properties = <String, dynamic>{};
        for (final customProperty in obj.properties) {
          properties[customProperty.name] = customProperty.value;
        }

        final component = EnvironmentComponent(
          position: Vector2(obj.x, obj.y),
          size: Vector2(obj.width, obj.height),
          type: environmentType,
          name: obj.name,
          properties: properties,
          effectsImage: null,
        );

        add(component);
        spawnSystem.registerEnvironmentComponent(component);

        if (environmentType == EnvironmentType.spawner) {
          spawners.add(component);
        }
      }
    }
  }

  EnvironmentType? _parseEnvironmentType(String type) {
    switch (type.toLowerCase()) {
      case 'spawner':
        return EnvironmentType.spawner;
      case 'spawnpoint':
        return EnvironmentType.spawnPoint;
      case 'pickup':
        return EnvironmentType.pickup;
      default:
        return null;
    }
  }

  void updateSpawners(double dt) {
    spawnSystem.update(dt, _spawnItem);
  }

  void _spawnItem(Vector2 position, String itemType) {
    // Логика спавна предметов
    debugPrint('Spawning $itemType at $position');
    // Здесь можно создать компонент предмета и добавить в мир
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Обновляем движение игрока на основе ввода
    final moveDirection = inputManager.moveDirection;
    player.move(moveDirection, dt);

    // Обновляем угол поворота турели
    if (moveDirection != Vector2.zero()) {
      final angle = moveDirection.angleToSigned(Vector2(0, -1));
      player.angle = angle;
    }
  }
}
