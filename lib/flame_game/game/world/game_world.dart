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

  // Слой коллизий
  Map<String, List<List<bool>>> collisionTiles = {};

  GameWorld({required this.resourceManager, required this.inputManager});

  @override
  Future<void> onLoad() async {
    await _loadMap();
    await _loadCollisionLayer();

    // ТЕСТОВАЯ СТЕНА - красный квадрат для проверки коллизий
    final testWall = RectangleComponent(
      position: Vector2(1000, 1000),
      size: Vector2(100, 100),
      paint: Paint()..color = Colors.red,
    );
    testWall.add(RectangleHitbox());
    add(testWall);
    debugPrint('🧱 ТЕСТОВАЯ СТЕНА добавлена в (1000, 1000) 100x100');

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

  /// Загрузка слоя коллизий из карты
  Future<void> _loadCollisionLayer() async {
    debugPrint('🔧 Загрузка слоя коллизий...');
    final collisionLayer = tiledMap.tileMap.getLayer('collision');
    if (collisionLayer == null) {
      debugPrint(
        '⚠️ Слой collision не найден, используем только границы карты',
      );
      // Создаем пустую карту (только границы будут работать)
      collisionTiles['collision'] = [];
      return;
    }

    debugPrint('✅ Слой collision найден');

    // Проверяем что это TileLayer
    if (collisionLayer is TileLayer) {
      debugPrint(
        '📊 Тип: TileLayer (${collisionLayer.width}x${collisionLayer.height})',
      );

      final tileLayer = collisionLayer;
      final width = tileLayer.width;
      final height = tileLayer.height;

      // Создаем карту коллизий (все тайлы = коллизия)
      collisionTiles['collision'] = List.generate(width, (x) {
        return List.generate(height, (y) {
          return true; // Все тайлы на этом слое = коллизия
        });
      });

      debugPrint(
        '✅ Collision tiles loaded: ${collisionTiles['collision']?.length}x${collisionTiles['collision']?.isNotEmpty == true ? collisionTiles['collision']![0].length : 0}',
      );
      debugPrint(
        '📊 Collision map size: ${collisionTiles['collision']?.length} x ${collisionTiles['collision']?.isNotEmpty == true ? collisionTiles['collision']![0].length : 0}',
      );

      // Дополнительная отладка
      debugPrint('========== DEBUG COLLISION ==========');
      debugPrint(
        'collisionTiles length: ${collisionTiles['collision']?.length}',
      );
      if (collisionTiles['collision'] != null &&
          collisionTiles['collision']!.isNotEmpty) {
        debugPrint(
          'collisionTiles[0] length: ${collisionTiles['collision']![0].length}',
        );

        int trueCount = 0;
        for (var x = 0; x < collisionTiles['collision']!.length; x++) {
          for (var y = 0; y < collisionTiles['collision']![x].length; y++) {
            if (collisionTiles['collision']![x][y]) trueCount++;
          }
        }
        debugPrint('True collisions count: $trueCount');
      }
      debugPrint('=====================================');

      return;
    }

    // Если это ObjectGroup - обрабатываем объекты
    if (collisionLayer is ObjectGroup) {
      debugPrint(
        '📊 Тип: ObjectGroup (${collisionLayer.objects.length} объектов)',
      );

      // Создаем карту 100x100 (для карты 6400x6400 с тайлом 64)
      const mapWidth = 100;
      const mapHeight = 100;
      collisionTiles['collision'] = List.generate(mapWidth, (x) {
        return List.generate(mapHeight, (y) {
          return false; // По умолчанию нет коллизии
        });
      });

      // Проходим по всем объектам и помечаем тайлы
      for (final obj in collisionLayer.objects) {
        final objX = obj.x;
        final objY = obj.y;
        final objWidth = obj.width;
        final objHeight = obj.height;

        // Вычисляем диапазон тайлов
        final startTileX = (objX / 64).floor();
        final endTileX = ((objX + objWidth) / 64).ceil();
        final startTileY = (objY / 64).floor();
        final endTileY = ((objY + objHeight) / 64).ceil();

        // Помечаем тайлы внутри объекта как коллизия
        for (var tx = startTileX; tx < endTileX; tx++) {
          for (var ty = startTileY; ty < endTileY; ty++) {
            if (tx >= 0 && tx < mapWidth && ty >= 0 && ty < mapHeight) {
              collisionTiles['collision']![tx][ty] = true;
            }
          }
        }

        debugPrint(
          '🔲 Объект: (${objX}, ${objY}) ${objWidth}x${objHeight} -> тайлы [$startTileX-$endTileX]x[$startTileY-$endTileY]',
        );
      }

      debugPrint(
        '✅ Collision tiles loaded: ${collisionTiles['collision']?.length}x${collisionTiles['collision']?.isNotEmpty == true ? collisionTiles['collision']![0].length : 0}',
      );
      debugPrint(
        '📊 Collision map size: ${collisionTiles['collision']?.length} x ${collisionTiles['collision']?.isNotEmpty == true ? collisionTiles['collision']![0].length : 0}',
      );
      debugPrint(
        '✅ Слой ObjectGroup коллизий загружен: ${collisionLayer.objects.length} объектов',
      );

      // Дополнительная отладка
      debugPrint('========== DEBUG COLLISION ==========');
      debugPrint(
        'collisionTiles length: ${collisionTiles['collision']?.length}',
      );
      if (collisionTiles['collision'] != null &&
          collisionTiles['collision']!.isNotEmpty) {
        debugPrint(
          'collisionTiles[0] length: ${collisionTiles['collision']![0].length}',
        );

        int trueCount = 0;
        for (var x = 0; x < collisionTiles['collision']!.length; x++) {
          for (var y = 0; y < collisionTiles['collision']![x].length; y++) {
            if (collisionTiles['collision']![x][y]) trueCount++;
          }
        }
        debugPrint('True collisions count: $trueCount');
      }
      debugPrint('=====================================');

      return;
    }

    // Неизвестный тип слоя
    debugPrint('⚠️ Неизвестный тип слоя: ${collisionLayer.runtimeType}');
    debugPrint('💡 Используются только границы карты');
    collisionTiles['collision'] = [];
  }

  Future<void> _createPlayer() async {
    // Получаем стартовую позицию из карты или используем центр
    final startPosition =
        _getStartPositionFromMap() ?? Vector2(mapWidth / 2, mapHeight / 2);

    player = Player(position: startPosition, resourceManager: resourceManager);

    // Добавляем хитбокс для коллизий
    player.add(
      RectangleHitbox(
        position: Vector2(0, 0),
        anchor: Anchor.center,
        size: Vector2(64, 64), // 64x64 = 32px от центра в каждую сторону
      ),
    );

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

    debugPrint('Weapons set: MachineGun, ShotGun, RocketLauncher');
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

    // Отрисовка коллизий (упрощенно для отладки)
    if (collisionTiles['collision'] != null) {
      final collisionMap = collisionTiles['collision']!;
      const tileSize = 64.0;

      for (var x = 0; x < collisionMap.length; x++) {
        for (var y = 0; y < collisionMap[x].length; y++) {
          if (collisionMap[x][y]) {
            canvas.drawRect(
              Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
              Paint()
                ..color = Colors.red.withOpacity(0.5)
                ..style = PaintingStyle.fill,
            );
          }
        }
      }
    }
  }

  /// Проверка коллизии с тайлами карты
  bool isTileCollidable(Vector2 position) {
    if (collisionTiles.isEmpty || collisionTiles['collision']!.isEmpty) {
      debugPrint(
        '⚠️ collisionTiles пуст, возвращаем false (работают только границы)',
      );
      return false;
    }

    final tileX = (position.x / 64).floor();
    final tileY = (position.y / 64).floor();

    debugPrint(
      '🗺️ Проверяем тайл: tileX=$tileX, tileY=$tileY, position=(${position.x.toInt()}, ${position.y.toInt()})',
    );

    final collisionMap = collisionTiles['collision']!;
    if (tileX < 0 || tileX >= collisionMap.length) {
      debugPrint(
        '🚫 tileX вне диапазона: $tileX (размер: ${collisionMap.length})',
      );
      return true; // За пределами карты - коллизия
    }

    if (tileY < 0 || tileY >= collisionMap[tileX].length) {
      debugPrint(
        '🚫 tileY вне диапазона: $tileY (размер: ${collisionMap[tileX].length})',
      );
      return true; // За пределами карты - коллизия
    }

    final isCollidable = collisionMap[tileX][tileY];
    debugPrint('🗺️ Результат коллизии тайла: $isCollidable');
    return isCollidable;
  }

  /// Проверка коллизии с границами карты (с учетом размера игрока 64x64)
  bool isOutOfBounds(Vector2 position) {
    final halfSize = 32.0; // Половина размера игрока (64/2)
    return position.x - halfSize < 0 ||
        position.y - halfSize < 0 ||
        position.x + halfSize > mapWidth ||
        position.y + halfSize > mapHeight;
  }

  /// Проверка коллизии (тайлы + границы) с учетом размера игрока
  bool isCollidable(Vector2 position) {
    // Проверяем границы карты с учетом размера игрока (64px)
    final halfSize = 32.0;
    if (position.x - halfSize < 0 ||
        position.y - halfSize < 0 ||
        position.x + halfSize > mapWidth ||
        position.y + halfSize > mapHeight) {
      debugPrint('🚫 Коллизия: выход за границы карты');
      return true;
    }

    // Проверяем все 4 угла игрока на коллизию с тайлами
    final corners = [
      Vector2(position.x - halfSize, position.y - halfSize),
      Vector2(position.x + halfSize, position.y - halfSize),
      Vector2(position.x - halfSize, position.y + halfSize),
      Vector2(position.x + halfSize, position.y + halfSize),
    ];

    for (final corner in corners) {
      if (isTileCollidable(corner)) {
        return true;
      }
    }

    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Обновляем движение игрока на основе ввода
    final moveDirection = inputManager.moveDirection;
    player.move(moveDirection, dt);

    // ⚠️ НЕ ПОВОРАЧИВАЙТЕ ИГРОКА ЗДЕСЬ!
    // Поворот должен управляться мышью через faceAngleRadians
    // if (moveDirection != Vector2.zero()) {
    //   final angle = moveDirection.angleToSigned(Vector2(0, -1));
    //   player.angle = angle;
    // }

    // Обновляем спавнеры
    updateSpawners(dt);
  }
}
