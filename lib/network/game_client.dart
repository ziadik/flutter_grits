// lib/network/game_client.dart
import 'dart:async';
import 'dart:convert';

import 'package:vector_math/vector_math.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Состояние сетевого подключения
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Информация о другом игроке в сети
class NetworkPlayer {
  final String id;
  final String name;
  final int team;
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  bool walking;
  double health;
  double energy;
  int weaponSlot;
  bool isDead;
  int kills;
  int deaths;

  NetworkPlayer({
    required this.id,
    required this.name,
    required this.team,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.walking,
    required this.health,
    required this.energy,
    required this.weaponSlot,
    required this.isDead,
    required this.kills,
    required this.deaths,
  });
}

/// Игровой клиент для WebSocket соединения
class GameClient {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  String? _currentRoomId;
  String? _playerId;
  ConnectionState _connectionState = ConnectionState.disconnected;

  // Состояние других игроков
  final Map<String, NetworkPlayer> _remotePlayers = {};

  // Колбэки для обновления игрового мира
  Function(List<NetworkPlayer> players)? onPlayersUpdate;
  Function(String playerId, double x, double y, double angle, int weaponSlot)?
  onPlayerShoot;
  Function(String playerId, double damage, bool killed)? onHitResult;
  Function(String playerId, String killerId)? onPlayerDied;
  Function(String playerId, double x, double y)? onPlayerRespawned;
  Function(String itemId, String playerId)? onItemCollected;
  Function(String playerId)? onPlayerJoined;
  Function(String playerId)? onPlayerLeft;
  Function()? onGameStart;
  Function(String reason)? onGameEnd;
  Function(String error)? onError;
  Function(ConnectionState state)? onConnectionStateChange;

  GameClient();

  // Геттеры
  ConnectionState get connectionState => _connectionState;
  String? get playerId => _playerId;
  String? get roomId => _currentRoomId;
  Map<String, NetworkPlayer> get remotePlayers =>
      Map.unmodifiable(_remotePlayers);

  // Для ожидания подтверждения подключения
  Completer<String>? _connectCompleter;

  /// Подключение к серверу
  Future<void> connect(
    String serverUrl,
    String playerName,
    String roomId,
  ) async {
    if (_connectionState == ConnectionState.connecting ||
        _connectionState == ConnectionState.connected) {
      disconnect();
    }

    _currentRoomId = roomId;
    _connectCompleter = Completer<String>();
    _setConnectionState(ConnectionState.connecting);

    debugPrint('🔗 Connecting to: $serverUrl');
    debugPrint('👤 Player: $playerName');
    debugPrint('🏠 Room: $roomId');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
          if (!_connectCompleter!.isCompleted) {
            _connectCompleter!.completeError('WebSocket error: $error');
          }
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('🔌 WebSocket closed');
          if (!_connectCompleter!.isCompleted) {
            _connectCompleter!.completeError('Connection closed');
          }
          _handleDisconnect();
        },
      );

      // Отправляем запрос на подключение
      _send({'type': 'join', 'playerName': playerName, 'roomId': roomId});

      // Запускаем пинг для поддержания соединения
      _startPing();

      // Ждём подтверждения подключения (timeout 5 секунд)
      debugPrint('⏳ Waiting for server confirmation...');
      final playerId = await _connectCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('❌ Connection timeout after 5 seconds');
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      debugPrint('✅ Successfully connected as player: $playerId');
    } catch (e) {
      debugPrint('❌ Failed to connect: $e');
      if (!_connectCompleter!.isCompleted) {
        _connectCompleter!.completeError(e);
      }
      _setConnectionState(ConnectionState.failed);
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Отключение от сервера
  void disconnect() {
    _stopPing();
    _stopReconnect();

    if (_channel != null) {
      _send({'type': 'leave'});
      _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _remotePlayers.clear();
    _setConnectionState(ConnectionState.disconnected);
  }

  /// Отправка состояния ввода игрока
  void sendInput(
    Vector2 position,
    Vector2 velocity,
    double angle,
    bool walking,
  ) {
    if (_connectionState != ConnectionState.connected) return;

    _send({
      'type': 'input',
      'position': {'x': position.x, 'y': position.y},
      'velocity': {'x': velocity.x, 'y': velocity.y},
      'angle': angle,
      'walking': walking,
    });
  }

  /// Отправка выстрела
  void sendShoot(Vector2 position, double angle, int weaponSlot) {
    if (_connectionState != ConnectionState.connected) return;

    _send({
      'type': 'shoot',
      'position': {'x': position.x, 'y': position.y},
      'angle': angle,
      'weaponSlot': weaponSlot,
    });
  }

  /// Отправка попадания
  void sendHit(String targetId, double damage) {
    if (_connectionState != ConnectionState.connected) return;

    _send({'type': 'hit', 'targetId': targetId, 'damage': damage});
  }

  /// Отправка подбора предмета
  void sendCollect(String itemId) {
    if (_connectionState != ConnectionState.connected) return;

    _send({'type': 'collect', 'itemId': itemId});
  }

  /// Смена оружия
  void sendWeaponSwitch(int slot) {
    if (_connectionState != ConnectionState.connected) return;

    _send({'type': 'weapon_switch', 'slot': slot});
  }

  /// Отправка запроса на респавн
  void sendRespawn() {
    if (_connectionState != ConnectionState.connected || _playerId == null) {
      return;
    }

    _send({'type': 'respawn', 'from': _playerId});
  }

  /// Отправка сообщения
  void _send(Map<String, dynamic> data) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Обработка входящих сообщений
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String?;

      switch (type) {
        case 'joined':
          _handleJoined(data);
          break;
        case 'player_joined':
          _handlePlayerJoined(data);
          break;
        case 'player_left':
          _handlePlayerLeft(data);
          break;
        case 'game_start':
          _handleGameStart(data);
          break;
        case 'game_state':
          _handleGameState(data);
          break;
        case 'shoot':
          _handleShoot(data);
          break;
        case 'hit_result':
          _handleHitResult(data);
          break;
        case 'player_died':
          _handlePlayerDied(data);
          break;
        case 'player_respawned':
          _handlePlayerRespawned(data);
          break;
        case 'item_collected':
          _handleItemCollected(data);
          break;
        case 'health_update':
          _handleHealthUpdate(data);
          break;
        case 'weapon_switch':
          _handleWeaponSwitch(data);
          break;
        case 'game_ended':
          _handleGameEnd(data);
          break;
        case 'pong':
          // Понг для поддержания соединения
          break;
        case 'error':
          onError?.call(data['message'] ?? 'Unknown error');
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleJoined(Map<String, dynamic> data) {
    _playerId = data['playerId'];
    _setConnectionState(ConnectionState.connected);

    debugPrint('✅ Joined room as $_playerId, team: ${data['team']}');

    // Завершаем ожидание подключения
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(_playerId);
    }

    // Загружаем начальное состояние
    if (data['gameState'] != null) {
      _updateGameState(data['gameState']);
    }
  }

  void _handlePlayerJoined(Map<String, dynamic> data) {
    final player = data['player'] as Map<String, dynamic>;
    final netPlayer = NetworkPlayer(
      id: player['id'],
      name: player['name'],
      team: player['team'],
      x: (player['position']['x'] as num).toDouble(),
      y: (player['position']['y'] as num).toDouble(),
      vx: 0,
      vy: 0,
      angle: 0,
      walking: false,
      health: 100,
      energy: 100,
      weaponSlot: 0,
      isDead: false,
      kills: 0,
      deaths: 0,
    );

    _remotePlayers[netPlayer.id] = netPlayer;
    onPlayerJoined?.call(netPlayer.id);
    onPlayersUpdate?.call(_remotePlayers.values.toList());
  }

  void _handlePlayerLeft(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String;
    _remotePlayers.remove(playerId);
    onPlayerLeft?.call(playerId);
    onPlayersUpdate?.call(_remotePlayers.values.toList());
  }

  void _handleGameStart(Map<String, dynamic> data) {
    debugPrint('🎮 Game started!');
    if (data['gameState'] != null) {
      _updateGameState(data['gameState']);
    }
    onGameStart?.call();
  }

  void _handleGameState(Map<String, dynamic> data) {
    _updateGameState(data['state']);
  }

  void _updateGameState(Map<String, dynamic> state) {
    // Обновляем игроков
    if (state['players'] != null) {
      for (final playerData in state['players']) {
        final id = playerData['id'] as String;
        if (id == _playerId) continue; // Пропускаем себя

        final existing = _remotePlayers[id];
        if (existing != null) {
          // Обновляем существующего игрока
          existing.x = (playerData['position']['x'] as num).toDouble();
          existing.y = (playerData['position']['y'] as num).toDouble();
          existing.vx = (playerData['velocity']?['x'] as num?)?.toDouble() ?? 0;
          existing.vy = (playerData['velocity']?['y'] as num?)?.toDouble() ?? 0;
          existing.angle = (playerData['angle'] as num?)?.toDouble() ?? 0;
          existing.walking = playerData['walking'] ?? false;
          existing.health = (playerData['health'] as num?)?.toDouble() ?? 100;
          existing.energy = (playerData['energy'] as num?)?.toDouble() ?? 100;
          existing.weaponSlot = playerData['weaponSlot'] ?? 0;
          existing.isDead = playerData['isDead'] ?? false;
          existing.kills = playerData['kills'] ?? 0;
          existing.deaths = playerData['deaths'] ?? 0;
        } else {
          // Новый игрок
          final netPlayer = NetworkPlayer(
            id: id,
            name: playerData['name'] ?? 'Player',
            team: playerData['team'] ?? 0,
            x: (playerData['position']['x'] as num).toDouble(),
            y: (playerData['position']['y'] as num).toDouble(),
            vx: 0,
            vy: 0,
            angle: playerData['angle'] ?? 0,
            walking: playerData['walking'] ?? false,
            health: 100,
            energy: 100,
            weaponSlot: playerData['weaponSlot'] ?? 0,
            isDead: false,
            kills: 0,
            deaths: 0,
          );
          _remotePlayers[id] = netPlayer;
        }
      }

      onPlayersUpdate?.call(_remotePlayers.values.toList());
    }

    // Предметы можно обработать при необходимости
  }

  void _handleShoot(Map<String, dynamic> data) {
    final shooterId = data['playerId'] as String;
    final position = data['position'] as Map<String, dynamic>;
    final x = (position['x'] as num).toDouble();
    final y = (position['y'] as num).toDouble();
    final angle = (data['angle'] as num).toDouble();
    final weaponSlot = data['weaponSlot'] as int;

    onPlayerShoot?.call(shooterId, x, y, angle, weaponSlot);
  }

  void _handleHitResult(Map<String, dynamic> data) {
    final targetId = data['targetId'] as String;
    final damage = (data['damage'] as num).toDouble();
    final killed = data['killed'] as bool;

    onHitResult?.call(targetId, damage, killed);
  }

  void _handlePlayerDied(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String;
    final killerId = data['killerId'] as String;

    onPlayerDied?.call(playerId, killerId);
  }

  void _handlePlayerRespawned(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String;
    final x = (data['x'] as num).toDouble();
    final y = (data['y'] as num).toDouble();

    onPlayerRespawned?.call(playerId, x, y);
  }

  void _handleItemCollected(Map<String, dynamic> data) {
    final itemId = data['itemId'] as String;
    final playerId = data['playerId'] as String;

    onItemCollected?.call(itemId, playerId);
  }

  void _handleHealthUpdate(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String;
    final health = (data['health'] as num).toDouble();

    final player = _remotePlayers[playerId];
    if (player != null) {
      player.health = health;
      onPlayersUpdate?.call(_remotePlayers.values.toList());
    }
  }

  void _handleWeaponSwitch(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String;
    final slot = data['slot'] as int;

    final player = _remotePlayers[playerId];
    if (player != null) {
      player.weaponSlot = slot;
      onPlayersUpdate?.call(_remotePlayers.values.toList());
    }
  }

  void _handleGameEnd(Map<String, dynamic> data) {
    final reason = data['reason'] as String? ?? 'Game ended';
    onGameEnd?.call(reason);
  }

  void _handleDisconnect() {
    _stopPing();
    _channel = null;

    if (_connectionState == ConnectionState.connected) {
      _setConnectionState(ConnectionState.reconnecting);
      _startReconnect();
    } else {
      _setConnectionState(ConnectionState.disconnected);
    }
  }

  void _startReconnect() {
    _stopReconnect();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_connectionState == ConnectionState.reconnecting &&
          _currentRoomId != null) {
        debugPrint('🔄 Attempting to reconnect...');
        // Переподключение нужно инициировать извне с сохранёнными данными
        onError?.call('Connection lost. Please reconnect.');
      }
    });
  }

  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startPing() {
    _stopPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_connectionState == ConnectionState.connected) {
        _send({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    onConnectionStateChange?.call(state);
  }

  void dispose() {
    _stopPing();
    _stopReconnect();
    disconnect();
  }
}

/// Расширение Player для синхронизации с сетью
extension NetworkPlayerSync on Player {
  void updateFromNetwork(NetworkPlayer netPlayer) {
    position = Vector2(netPlayer.x, netPlayer.y);
    faceAngleRadians = netPlayer.angle;
    walking = netPlayer.walking;
    health = netPlayer.health;
    energy = netPlayer.energy;
    if (selectedWeaponSlot != netPlayer.weaponSlot) {
      selectWeapon(netPlayer.weaponSlot);
    }
    if (netPlayer.isDead && !isDead) {
      die();
    }
  }

  NetworkPlayer toNetworkPlayer(String id, String name, int team) {
    return NetworkPlayer(
      id: id,
      name: name,
      team: team,
      x: position.x,
      y: position.y,
      vx: 0,
      vy: 0,
      angle: faceAngleRadians,
      walking: walking,
      health: health,
      energy: energy,
      weaponSlot: selectedWeaponSlot,
      isDead: isDead,
      kills: 0,
      deaths: 0,
    );
  }
}
