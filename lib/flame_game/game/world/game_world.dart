// lib/game/world/game_world.dart

import 'dart:convert';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/input_manager.dart';
import 'package:flutter_grits/flame_game/systems/spawn_system.dart';
import 'package:flutter_grits/flame_game/projectiles/projectile_base.dart';
import 'package:flutter_grits/flame_game/components/environment_component.dart';
import 'package:flutter_grits/flame_game/components/game_object_component.dart';
// import 'package:flutter_grits/flame_game/entities/spawn_point.dart';
import 'package:flutter_grits/flame_game/entities/teleporter.dart';
// import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_registry.dart';
import 'package:flutter_grits/flame_game/effects/player_spawn_effect.dart';
import 'package:flutter_grits/main.dart';
import 'package:flutter_grits/network/network_manager.dart';
import 'package:http/http.dart' as http;

/// Коллизионный блок с поддержкой флагов
class CollisionBlock extends PositionComponent with CollisionCallbacks {
  final List<String> collisionFlags;

  CollisionBlock({required super.position, required super.size, this.collisionFlags = const []}) : super(anchor: Anchor.topLeft); // ✅ Важно: anchor.topLeft для правильного совпадения хитбокса

  bool hasFlag(String flag) => collisionFlags.contains(flag);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Хитбокс должен совпадать с размером и позицией блока
    add(RectangleHitbox(position: Vector2.zero(), anchor: Anchor.topLeft, size: size));
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    // Если блок имеет флаг projectileignore - не сталкиваться с пулями
    if (hasFlag('projectileignore') && other is ProjectileBase) {
      return false;
    }
    return super.onComponentTypeCheck(other);
  }
}

class GameWorld extends World {
  final ResourceManager resourceManager;
  final InputManager inputManager;

  late Player player;
  late TiledComponent tiledMap;
  late SpawnSystem spawnSystem;
  late NetworkManager networkManager;
  int mapWidth = 6400;
  int mapHeight = 6400;

  // Список всех EnvironmentComponent spawners для быстрого доступа
  final List<EnvironmentComponent> spawners = [];

  // Игровые сущности (SpawnPoint, Teleporter, Spawner)
  // final List<SpawnPoint> spawnPoints = [];
  final List<Teleporter> teleporters = [];
  // final List<Spawner> entitySpawners = []; // Удалено - Spawner больше не используется

  // Игровые объекты из слоя game_objects
  final List<GameObjectComponent> gameEntities = [];

  // Хранилище коллизионных блоков (публичное для отладки)
  final List<CollisionBlock> collisionBlocks = [];

  GameWorld({required this.resourceManager, required this.inputManager});

  @override
  Future<void> onLoad() async {
    await _loadMap();
    await _createCollisionBlocks(); // Создаем Hitbox'ы из слоя коллизий

    // // ТЕСТОВАЯ СТЕНА - красный квадрат для проверки коллизий
    // final testWall = RectangleComponent(
    //   position: Vector2(1000, 1000),
    //   size: Vector2(100, 100),
    //   paint: Paint()..color = Colors.red,
    // );
    // testWall.add(RectangleHitbox());
    // add(testWall);

    await _createPlayer();

    // Инициализация сетевого менеджера
    networkManager = NetworkManager(gameWorld: this);

    // Установка оружия для игрока
    _setupPlayerWeapons();

    // Ждем пока игрок полностью загрузится, затем обновим оружие
    await Future.delayed(const Duration(milliseconds: 100));
    player.updateWeaponSprite();

    _initSpawnSystem();
    _loadEnvironmentObjects();
    _loadGameObjects(); // Загружаем игровые объекты из слоя game_objects
    _loadGameEntities(); // Загружаем игровые сущности (спавны, телепорты)
    // _displaySpawnersAsGameObjects(); // УДАЛЕНО - больше не нужно
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
          final collisionBlock = CollisionBlock(position: Vector2(x * tileSize, y * tileSize), size: Vector2(tileSize, tileSize));
          add(collisionBlock);
          collisionBlocks.add(collisionBlock);
        }
      }
      debugPrint('✅ Создано ${collisionBlocks.length} коллизионных блоков из TileLayer');

      // Устанавливаем низкий приоритет для стен
      for (final block in collisionBlocks) {
        block.priority = 0;
      }
    } else if (collisionLayer is ObjectGroup) {
      // Для ObjectGroup - создаем блоки для каждого объекта с поддержкой collisionFlags
      for (final obj in collisionLayer.objects) {
        // Читаем свойство collisionFlags
        final flags = <String>[];
        for (final prop in obj.properties) {
          if (prop.name == 'collisionFlags') {
            final flagValue = prop.value.toString().trim();
            if (flagValue.isNotEmpty) {
              flags.add(flagValue);
            }
            break;
          }
        }

        final collisionBlock = CollisionBlock(position: Vector2(obj.x, obj.y), size: Vector2(obj.width, obj.height), collisionFlags: flags);
        add(collisionBlock);
        collisionBlocks.add(collisionBlock);
      }
      debugPrint('✅ Создано ${collisionBlocks.length} коллизионных блоков из ObjectGroup');
    }
  }

  Future<void> _createPlayer() async {
    // Получаем стартовую позицию из карты или используем центр
    final startPosition = _getStartPositionFromMap() ?? Vector2(mapWidth / 2, mapHeight / 2);

    player = Player(position: startPosition, resourceManager: resourceManager, gameWorld: this);

    // Подписываем игрока на ввод
    player.inputManager = inputManager;

    await add(player);
    debugPrint('✅ Player created at $startPosition');

    // ✅ Показываем эффект появления игрока (спавн)
    // Эффект будет показан под игроком и удалится через 0.5 сек
    PlayerSpawnEffect.spawn(position: startPosition, animator: resourceManager.playerAnimator, gameWorld: this);
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

    // Слот 3: Chain Gun
    player.setWeapon(2, WeaponRegistry.createWeapon('ChainGun'));

    // Слот 4: Ракетница (RocketLauncher)
    player.setWeapon(3, WeaponRegistry.createWeapon('RocketLauncher'));

    // Слот 5: Гранатомёт (GrenadeLauncher)
    player.setWeapon(4, WeaponRegistry.createWeapon('GrenadeLauncher'));

    // Слот 6: Рейлган (Railgun)
    player.setWeapon(5, WeaponRegistry.createWeapon('Railgun'));

    debugPrint('✅ Weapons set: MachineGun, ShotGun, ChainGun, RocketLauncher, GrenadeLauncher, Railgun');
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

  /// Загрузка игровых объектов из слоя game_objects
  void _loadGameObjects() {
    final layer = tiledMap.tileMap.getLayer('game_objects');
    if (layer == null) {
      debugPrint('⚠️ Слой game_objects не найден');
      return;
    }

    debugPrint('✅ Загрузка игровых объектов из слоя game_objects (тип: ${layer.runtimeType})...');

    if (layer is TileLayer) {
      // Если это TileLayer - ищем специальные тайлы-предметы
      _loadGameObjectsFromTileLayer(layer);
    } else if (layer is ObjectGroup) {
      // Если это ObjectGroup - читаем объекты
      _loadGameObjectsFromObjectGroup(layer);
    } else {
      debugPrint('⚠️ Слой game_objects имеет неподдерживаемый тип: ${layer.runtimeType}');
    }
  }

  /// Загрузка объектов из TileLayer (по специальным тайлам)
  void _loadGameObjectsFromTileLayer(TileLayer layer) {
    debugPrint('   Чтение объектов из TileLayer...');

    // TODO: Здесь можно реализовать поиск специальных тайлов
    // Например, если у вас есть ID тайлов для предметов
    debugPrint('   ⚠️ Поддержка TileLayer для game_objects в разработке');
  }

  /// Загрузка объектов из ObjectGroup
  void _loadGameObjectsFromObjectGroup(ObjectGroup layer) {
    debugPrint('   Найдено объектов: ${layer.objects.length}');

    for (final obj in layer.objects) {
      final objName = obj.name ?? '';
      final objType = obj.type ?? '';

      debugPrint('   Объект: $objName, тип: $objType, позиция: (${obj.x}, ${obj.y})');

      GameObjectType? type;

      // Определяем тип объекта по имени или типу
      if (objName.contains('Energy') || objType.contains('Energy')) {
        type = GameObjectType.energyCanister;
      } else if (objName.contains('Health') || objType.contains('Health')) {
        type = GameObjectType.healthCanister;
      } else if (objName.contains('Quad') || objType.contains('Quad')) {
        type = GameObjectType.quadDamage;
      } else if (objName.contains('TP') || objType.contains('teleporter')) {
        type = GameObjectType.teleporter;
      }
      // Spawner предметов удалён - больше не используется

      if (type != null) {
        final properties = <String, dynamic>{};
        for (final prop in obj.properties) {
          properties[prop.name] = prop.value;
        }

        final gameObject = GameObjectComponent(
          position: Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2),
          type: type,
          name: objName,
          properties: properties,
          animator: resourceManager.playerAnimator,
          gameWorld: this, // ✅ Добавляем gameWorld
          size: Vector2(64, 64),
        );

        add(gameObject);
        gameEntities.add(gameObject);
      }
    }

    debugPrint('✅ Загружено игровых объектов: ${gameEntities.length}');
  }

  // void _displaySpawnersAsGameObjects() {
  //   // УДАЛЕНО - больше не нужно
  // }

  Future<void> _loadGameEntities() async {
    final environmentLayer = tiledMap.tileMap.getLayer<ObjectGroup>('environment');
    if (environmentLayer == null) {
      debugPrint('⚠️ Слой environment не найден');
      return;
    }

    debugPrint('✅ Загрузка игровых сущностей из слоя environment...');
    debugPrint('   Найдено объектов: ${environmentLayer.objects.length}');

    for (final obj in environmentLayer.objects) {
      final objType = obj.type ?? '';
      final objName = obj.name ?? '';

      // Телепортер
      if (objType == 'teleporter') {
        await _loadTeleporter(obj);
      }
      // SpawnPoint
      else if (objType == 'SpawnPoint' || objName.contains('SpawnPoint')) {
        _loadSpawnPoint(obj);
      }
      // Spawner предметов (HealthSpawner, EnergySpawner, QuadDamageSpawner)
      else if (objType == 'Spawner' && objName.endsWith('Spawner')) {
        _loadItemSpawner(obj);
      }
    }

    // debugPrint(
    //   '✅ Загружено сущностей - SpawnPoints: ${spawnPoints.length}, Teleporters: ${teleporters.length}, ItemSpawners: ${gameEntities.where((e) => e.type == GameObjectType.healthCanister || e.type == GameObjectType.energyCanister || e.type == GameObjectType.quadDamage).length}',
    // );
  }

  /// Загрузка спавнера предметов как визуального объекта
  void _loadItemSpawner(dynamic obj) {
    // Получаем свойство SpawnItem
    String spawnItem = '';
    for (final prop in obj.properties) {
      if (prop.name == 'SpawnItem') {
        spawnItem = prop.value.toString();
        break;
      }
    }

    if (spawnItem.isEmpty) {
      debugPrint('⚠️ Spawner без SpawnItem: ${obj.name}');
      return;
    }

    // Определяем тип предмета
    GameObjectType? type;
    if (spawnItem.contains('Health')) {
      type = GameObjectType.healthCanister;
    } else if (spawnItem.contains('Energy')) {
      type = GameObjectType.energyCanister;
    } else if (spawnItem.contains('Quad')) {
      type = GameObjectType.quadDamage;
    }

    if (type == null) {
      debugPrint('⚠️ Неизвестный тип спавнера: $spawnItem');
      return;
    }

    final properties = <String, dynamic>{};
    for (final prop in obj.properties) {
      properties[prop.name] = prop.value;
    }

    final gameObject = GameObjectComponent(
      position: Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2),
      type: type,
      name: obj.name ?? 'Spawner',
      properties: properties,
      animator: resourceManager.playerAnimator,
      gameWorld: this,
      size: Vector2(64, 64),
    );

    add(gameObject);
    gameEntities.add(gameObject);
    debugPrint('📦 Загружен спавнер предмета: ${obj.name} -> $type at ${gameObject.position}');
  }

  Future<void> _loadTeleporter(dynamic obj) async {
    String destStr = '0,0';
    for (final prop in obj.properties) {
      if (prop.name == 'destination') {
        destStr = prop.value.toString();
        break;
      }
    }

    final destParts = destStr.split(',');
    final destX = double.tryParse(destParts[0].trim()) ?? 0;
    final destY = double.tryParse(destParts[1].trim()) ?? 0;

    final tileSize = 64.0;
    Vector2 destination;

    if (destX < 100 && destY < 100) {
      destination = Vector2(destX * tileSize, destY * tileSize);
    } else {
      destination = Vector2(destX, destY);
    }

    final teleporterPos = Vector2(obj.x + obj.width * 2, obj.y + obj.height * 2);

    final teleporter = Teleporter(position: teleporterPos, destination: destination, animator: resourceManager.playerAnimator, gameWorld: this);

    await teleporter.onLoad();
    add(teleporter);
    teleporters.add(teleporter);
  }

  void _loadSpawnPoint(dynamic obj) {
    // Получаем свойство team
    int team = 0;
    for (final prop in obj.properties) {
      if (prop.name == 'team') {
        final val = prop.value;
        if (val is int) {
          team = val;
        } else if (val is String) {
          team = int.tryParse(val) ?? 0;
        }
        break;
      }
    }

    // final spawnPoint = SpawnPoint(
    //   position: Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2),
    //   team: team,
    //   gameWorld: this,
    // );

    // spawnPoint.onInit();
    // add(spawnPoint);
    // spawnPoints.add(spawnPoint);
    // debugPrint('🏃 SpawnPoint for team $team at ${spawnPoint.position}');
  }

  // void _loadSpawner(dynamic obj) {
  //   // УДАЛЕНО - Spawner для предметов больше не используется
  // }

  void updateSpawners(double dt) {
    // Ничего не делаем - Spawner больше не используется
  }

  // void _displaySpawnersAsGameObjects() {
  //   // УДАЛЕНО - больше не нужно
  // }

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
          Rect.fromLTWH(block.position.x, block.position.y, block.size.x, block.size.y),
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

    final moveDirection = inputManager.moveDirection;
    player.move(moveDirection, dt);

    // Отправка ввода на сервер
    networkManager.sendLocalPlayerInput(player);

    // Обработка выстрела
    if (inputManager.isLeftMousePressed) {
      final currentWeapon = player.selectedWeapon;
      if (currentWeapon != null) {
        currentWeapon.tryFire(player);
        networkManager.sendShoot(player.position, player.faceAngleRadians, player.selectedWeaponSlot);
      }
    }

    // Смена оружия
    final slot = inputManager.getWeaponSlotKeyPress();
    if (slot != null && slot != player.selectedWeaponSlot) {
      player.selectWeapon(slot);
      networkManager.sendWeaponSwitch(slot);
    }

    updateSpawners(dt);
  }

  Future<bool> checkServerStatus(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final httpUrl = 'http://${uri.host}:${uri.port}';
      final response = await http.get(Uri.parse('$httpUrl/ping'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Server status check failed: $e');
      return false;
    }
  }

  Future<List<RoomInfo>> fetchRooms(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final httpUrl = 'http://${uri.host}:${uri.port}';
      final response = await http.get(Uri.parse('$httpUrl/rooms'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RoomInfo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch rooms: $e');
      return [];
    }
  }

  Future<void> connectToServer(String serverUrl, String playerName, String roomId) async {
    await networkManager.connect(serverUrl, playerName, roomId);
  }
}
