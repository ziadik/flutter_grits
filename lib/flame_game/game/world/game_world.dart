// lib/game/world/game_world.dart

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter_grits/flame_game/systems/spawn_system.dart';
import 'package:flutter_grits/flame_game/components/environment_component.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_registry.dart';
import 'package:flutter/foundation.dart';

// Включаем HasCollisionDetection
class GameWorld extends World with HasCollisionDetection {
  final ResourceManager resourceManager;
  final InputManager inputManager;

  late Player player;
  late TiledComponent tiledMap;
  late SpawnSystem spawnSystem;

  int mapWidth = 6400;
  int mapHeight = 6400;

  // Список всех спавнеров для быстрого доступа
  final List<EnvironmentComponent> spawners = [];

  // Хранилище коллизионных блоков (публичное для отладки)
  final List<PositionComponent> collisionBlocks = [];

  GameWorld({required this.resourceManager, required this.inputManager});

  @override
  Future<void> onLoad() async {
    await _loadMap();
    await _createCollisionBlocks(); // Создаем Hitbox'ы из слоя коллизий

    // ТЕСТОВАЯ СТЕНА - красный квадрат для проверки коллизий
    final testWall = RectangleComponent(
      position: Vector2(1000, 1000),
      size: Vector2(100, 100),
      paint: Paint()..color = Colors.red,
    );
    testWall.add(RectangleHitbox());
    add(testWall);

    await _createPlayer();

    // Установка оружия для игрока
    _setupPlayerWeapons();

    // Ждем пока игрок полностью загрузится, затем обновим оружие
    await Future.delayed(const Duration(milliseconds: 100));
    player.updateWeaponSprite();

    _initSpawnSystem();
    _loadEnvironmentObjects();
  }

  Future<void> _loadMap() async {
    tiledMap = await TiledComponent.load('map1.tmx', Vector2.all(64));
    await add(tiledMap);
  }

  /// Создаем компоненты коллизий из слоя Tiled
  Future<void> _createCollisionBlocks() async {
    final collisionLayer = tiledMap.tileMap.getLayer('collision');
    if (collisionLayer == null) {
      debugPrint('⚠️ Слой collision не найден');
      return;
    }

    debugPrint('✅ Создание коллизий из слоя: ${collisionLayer.runtimeType}');

    if (collisionLayer is TileLayer) {
      // Для TileLayer - создаем блоки для каждого тайла
      final tileLayer = collisionLayer;
      const tileSize = 64.0;

      // Упрощенный подход: создаем блоки для всех тайлов
      for (var x = 0; x < tileLayer.width; x++) {
        for (var y = 0; y < tileLayer.height; y++) {
          // Создаем коллизионный блок для каждого тайла
          final collisionBlock = PositionComponent(
            position: Vector2(x * tileSize, y * tileSize),
            size: Vector2(tileSize, tileSize),
          );
          collisionBlock.add(RectangleHitbox());
          add(collisionBlock);
          collisionBlocks.add(collisionBlock);
        }
      }
      debugPrint(
        '✅ Создано ${collisionBlocks.length} коллизионных блоков из TileLayer',
      );
    } else if (collisionLayer is ObjectGroup) {
      // Для ObjectGroup - создаем блоки для каждого объекта
      for (final obj in collisionLayer.objects) {
        final collisionBlock = PositionComponent(
          position: Vector2(obj.x, obj.y),
          size: Vector2(obj.width, obj.height),
        );
        collisionBlock.add(RectangleHitbox());
        add(collisionBlock);
        collisionBlocks.add(collisionBlock);
      }
      debugPrint(
        '✅ Создано ${collisionBlocks.length} коллизионных блоков из ObjectGroup',
      );
    }
  }

  Future<void> _createPlayer() async {
    // Получаем стартовую позицию из карты или используем центр
    final startPosition =
        _getStartPositionFromMap() ?? Vector2(mapWidth / 2, mapHeight / 2);

    player = Player(
      position: startPosition,
      resourceManager: resourceManager,
      gameWorld: this,
    );

    // Подписываем игрока на ввод
    player.inputManager = inputManager;

    await add(player);
    debugPrint('✅ Player created at $startPosition');
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

  /// Установка оружия для игрока
  void _setupPlayerWeapons() {
    // Регистрация всех оружий
    WeaponRegistry.register();

    // Слот 1: Основное оружие (MachineGun)
    player.setWeapon(0, WeaponRegistry.createWeapon('MachineGun'));

    // Слот 2: Вторичное оружие (ShotGun)
    player.setWeapon(1, WeaponRegistry.createWeapon('ShotGun'));

    // Слот 3: Особое оружие (RocketLauncher)
    player.setWeapon(2, WeaponRegistry.createWeapon('RocketLauncher'));

    // debugPrint('Weapons set: MachineGun, ShotGun, RocketLauncher');
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
    // debugPrint('Spawning $itemType at $position');

    // Воспроизводим звук спавна
    SoundManager().playSfx(SoundAssets.spawn0);

    // Здесь можно создать компонент предмета и добавить в мир
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Отрисовка границ карты
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapWidth.toDouble(), mapHeight.toDouble()),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Отрисовка коллизионных блоков (для отладки)
    if (collisionBlocks.isNotEmpty) {
      for (final block in collisionBlocks) {
        canvas.drawRect(
          Rect.fromLTWH(
            block.position.x,
            block.position.y,
            block.size.x,
            block.size.y,
          ),
          Paint()
            ..color = Colors.red.withOpacity(0.3)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Обновляем движение игрока на основе ввода
    final moveDirection = inputManager.moveDirection;
    player.move(moveDirection, dt);

    // Обновляем спавнеры
    updateSpawners(dt);
  }
}
