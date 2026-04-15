// lib/systems/spawn_system.dart
import 'package:flame/components.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/components/environment_component.dart';

class SpawnSystem {
  final List<EnvironmentComponent> spawnPoints = [];
  final List<EnvironmentComponent> spawners = [];
  final Map<EnvironmentComponent, double> spawnTimers = {};

  void registerEnvironmentComponent(EnvironmentComponent component) {
    switch (component.type) {
      case EnvironmentType.spawnPoint:
        spawnPoints.add(component);
        break;
      case EnvironmentType.spawner:
        spawners.add(component);
        spawnTimers[component] = 0.0;
        break;
      default:
        break;
    }
  }

  Vector2? getRandomSpawnPoint() {
    if (spawnPoints.isEmpty) return null;
    final randomPoint =
        spawnPoints[DateTime.now().millisecondsSinceEpoch % spawnPoints.length];
    return randomPoint.position;
  }

  void update(double dt, Function(Vector2, String) spawnItem) {
    for (final spawner in spawners) {
      final timer = spawnTimers[spawner]!;
      final newTimer = timer + dt;

      final spawnInterval = (spawner.properties['SpawnInterval'] ?? 5.0)
          .toDouble();

      if (newTimer >= spawnInterval) {
        // Спавн предмета
        final spawnItemName =
            spawner.properties['SpawnItem']?.toString() ?? 'Unknown';
        spawnItem(spawner.position, spawnItemName);
        spawnTimers[spawner] = 0.0;
      } else {
        spawnTimers[spawner] = newTimer;
      }
    }
  }
}
