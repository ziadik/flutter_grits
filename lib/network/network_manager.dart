import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/network/game_client.dart'
    show GameClient, ConnectionState, NetworkPlayer;

/// Менеджер сети для синхронизации игрового мира
class NetworkManager {
  final GameClient _client = GameClient();
  final GameWorld gameWorld;

  String? _localPlayerId;
  final Map<String, RemotePlayerComponent> _remotePlayers = {};

  NetworkManager({required this.gameWorld}) {
    _setupCallbacks();
  }

  GameClient get client => _client;

  void _setupCallbacks() {
    _client.onPlayersUpdate = (players) {
      for (final netPlayer in players) {
        _updateRemotePlayer(netPlayer);
      }
    };

    _client.onPlayerShoot = (playerId, x, y, angle, weaponSlot) {
      if (playerId == _localPlayerId) return;
      // Воспроизводим выстрел удалённого игрока
      _showRemoteShoot(playerId, x, y, angle, weaponSlot);
    };

    _client.onPlayerDied = (playerId, killerId) {
      final remote = _remotePlayers[playerId];
      remote?.onDeath();
    };

    _client.onPlayerRespawned = (playerId, x, y) {
      final remote = _remotePlayers[playerId];
      remote?.respawn(Vector2(x, y));
    };

    _client.onPlayerJoined = (playerId) {
      debugPrint('🎮 New player joined: $playerId');
    };

    _client.onPlayerLeft = (playerId) {
      final remote = _remotePlayers.remove(playerId);
      remote?.removeFromParent();
    };

    _client.onConnectionStateChange = (state) {
      debugPrint('🔌 Connection state: $state');
      if (state == ConnectionState.disconnected) {
        _showDisconnectedDialog();
      }
    };
  }

  void _updateRemotePlayer(NetworkPlayer netPlayer) {
    var remote = _remotePlayers[netPlayer.id];

    if (remote == null) {
      // Создаём нового удалённого игрока
      remote = RemotePlayerComponent(
        playerId: netPlayer.id,
        playerName: netPlayer.name,
        team: netPlayer.team,
        resourceManager: gameWorld.resourceManager,
        gameWorld: gameWorld,
      );
      _remotePlayers[netPlayer.id] = remote;
      gameWorld.add(remote);
    }

    remote.updateFromNetwork(netPlayer);
  }

  void _showRemoteShoot(
    String playerId,
    double x,
    double y,
    double angle,
    int weaponSlot,
  ) {
    final remote = _remotePlayers[playerId];
    remote?.shoot(Vector2(x, y), angle, weaponSlot);
  }

  void _showDisconnectedDialog() {
    // Показываем диалог о потере соединения
    // Можно реализовать через глобальный контекст
  }

  /// Подключение к серверу
  Future<void> connect(
    String serverUrl,
    String playerName,
    String roomId,
  ) async {
    debugPrint('🔌 NetworkManager.connect called');
    debugPrint('  Server: $serverUrl');
    debugPrint('  Player: $playerName');
    debugPrint('  Room: $roomId');

    try {
      // Ждём подтверждения подключения от клиента
      await _client.connect(serverUrl, playerName, roomId);

      _localPlayerId = _client.playerId;

      debugPrint('✅ NetworkManager connected successfully');
      debugPrint('  Local player ID: $_localPlayerId');
    } catch (e) {
      debugPrint('❌ NetworkManager connection failed: $e');
      rethrow;
    }
  }

  /// Отправка ввода локального игрока
  void sendLocalPlayerInput(Player player) {
    if (_client.connectionState != ConnectionState.connected) return;

    _client.sendInput(
      player.position,
      Vector2.zero(), // velocity
      player.faceAngleRadians,
      player.walking,
    );
  }

  /// Отправка выстрела
  void sendShoot(Vector2 position, double angle, int weaponSlot) {
    _client.sendShoot(position, angle, weaponSlot);
  }

  /// Отправка попадания
  void sendHit(String targetId, double damage) {
    _client.sendHit(targetId, damage);
  }

  /// Отправка смены оружия
  void sendWeaponSwitch(int slot) {
    _client.sendWeaponSwitch(slot);
  }

  /// Отправка респавна
  void sendRespawn() {
    _client.sendRespawn();
  }

  void dispose() {
    _client.dispose();
    for (final remote in _remotePlayers.values) {
      remote.removeFromParent();
    }
    _remotePlayers.clear();
  }
}

/// Компонент удалённого игрока (для отображения других игроков)
class RemotePlayerComponent extends PositionComponent {
  final String playerId;
  final String playerName;
  final int team;
  final ResourceManager resourceManager;
  final GameWorld gameWorld;

  // Состояние
  Vector2 _targetPosition = Vector2.zero();
  double _targetAngle = 0;
  double _health = 100;
  bool _isDead = false;

  // Компоненты для отрисовки
  late SpriteComponent _turretComponent;

  RemotePlayerComponent({
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.resourceManager,
    required this.gameWorld,
  }) {
    size = Vector2(128, 128);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadTurret();
    priority = 10;
  }

  Future<void> _loadTurret() async {
    final animator = resourceManager.playerAnimator;
    final turretSprite = animator.getTurretSprite();

    if (turretSprite != null) {
      _turretComponent = SpriteComponent(size: size, anchor: Anchor.center);
      // Загрузка спрайта...
      add(_turretComponent);
    }
  }

  void updateFromNetwork(NetworkPlayer netPlayer) {
    _targetPosition = Vector2(netPlayer.x, netPlayer.y);
    _targetAngle = netPlayer.angle;
    _health = netPlayer.health;
    _isDead = netPlayer.isDead;

    _turretComponent.angle = _targetAngle;
  }

  void shoot(Vector2 position, double angle, int weaponSlot) {
    // Воспроизводим эффект выстрела удалённого игрока
  }

  void onDeath() {
    // Эффект смерти
  }

  void respawn(Vector2 position) {
    this.position = position;
    _isDead = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Плавная интерполяция позиции
    if (!_isDead) {
      position.lerp(_targetPosition, 0.3);
      _turretComponent.angle = _targetAngle;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isDead) return;

    // Базовая отрисовка круга для удалённых игроков
    final color = team == 0 ? Colors.blue : Colors.orange;

    canvas.drawCircle(
      Offset.zero,
      32,
      Paint()..color = color.withValues(alpha: 0.5),
    );

    // Индикатор здоровья
    final healthPercent = _health / 100;
    canvas.drawRect(
      Rect.fromLTWH(-32, -40, 64 * healthPercent, 6),
      Paint()..color = Colors.red,
    );

    // Имя игрока
    final textPainter = TextPainter(
      text: TextSpan(
        text: playerName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -50));
  }
}
