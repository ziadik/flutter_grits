import 'dart:math';
import 'dart:convert';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_grits/ui/events_logger.dart';
import 'package:flutter_grits/ui/events_panel.dart';

import 'package:http/http.dart' as http;

/// Глобальный ключ для доступа к Navigator из Flame кода
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late GritsGame game;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем SoundManager
  await SoundManager().init();

  // Загружаем ресурсы с обработкой ошибок
  final resourceManager = ResourceManager();

  // Сначала создаем игру без gameWorld
  game = GritsGame(resourceManager: resourceManager);

  try {
    await resourceManager.loadResources();
    debugPrint('✅ Resources loaded successfully');

    // После загрузки ресурсов инициализируем gameWorld
    // Но не вызываем game.onLoad() здесь, так как это может вызвать проблемы с контекстом
  } catch (e) {
    debugPrint('❌ Error loading resources: $e');
    if (kDebugMode) {
      runApp(ErrorApp(error: e.toString()));
      return;
    }
  }

  runApp(GritsApp(resourceManager: resourceManager));
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '❌ Error loading game',
                style: TextStyle(color: Colors.red, fontSize: 24),
              ),
              const SizedBox(height: 20),
              Text(error, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Перезапуск
                  final resourceManager = ResourceManager();
                  game = GritsGame(resourceManager: resourceManager);
                  runApp(GritsApp(resourceManager: resourceManager));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GritsApp extends StatelessWidget {
  final ResourceManager resourceManager;
  const GritsApp({super.key, required this.resourceManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Grits Game',
      theme: ThemeData.dark(),
      home: const ConnectionScreen(),
    );
  }
}

// ==================== ЭКРАН ПОДКЛЮЧЕНИЯ ====================

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _serverUrlController = TextEditingController(
    text: 'ws://localhost:8080',
  );
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();

  String _connectionStatus = 'Not connected';
  bool _isConnecting = false;
  List<RoomInfo> _availableRooms = [];
  bool _isLoadingRooms = false;
  String? _selectedRoomId;

  // Логгер событий
  final EventsLogger _eventLogger = EventsLogger();
  bool _showEventsPanel = true; // По умолчанию показываем панель событий

  // Флаг готовности игры - ИЗМЕНЕНО: по умолчанию true
  bool _isGameInitialized = true;

  @override
  void initState() {
    super.initState();
    _playerNameController.text = 'Player${Random().nextInt(1000)}';

    // Инициализируем игру асинхронно
    _initializeGameAsync();

    // Загружаем комнаты
    _loadRooms();

    // Автообновление списка комнат каждые 5 секунд
    _startAutoRefresh();
  }

  Future<void> _initializeGameAsync() async {
    try {
      debugPrint('🎮 Initializing game asynchronously...');

      // Даем время на инициализацию
      await Future.delayed(const Duration(milliseconds: 500));

      // Вызываем onLoad для инициализации игры (создаёт inputManager)
      debugPrint('  Calling game.onLoad()...');
      await game.onLoad();
      debugPrint('  ✅ Game.onLoad() completed');

      // Ждем инициализации NetworkManager
      debugPrint('  Waiting for NetworkManager initialization...');
      int attempts = 0;
      while (game.gameWorld?.networkManager == null && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (game.gameWorld?.networkManager != null) {
        debugPrint('  ✅ NetworkManager initialized');
        // Настраиваем связь между логгером и клиентом
        final networkManager = game.gameWorld!.networkManager!;
        _eventLogger.onSendEventToServer = (eventData) {
          networkManager.client.sendEventToServer(
            type: eventData['type'] as String,
            roomId: eventData['roomId'] as String?,
            playerId: eventData['playerId'] as String?,
            message: eventData['message'] as String?,
            data: eventData['data'],
          );
        };

        if (mounted) {
          setState(() {
            _isGameInitialized = true;
            _connectionStatus = 'Game ready';
          });
        }
      } else {
        debugPrint('  ⚠️ NetworkManager not initialized yet');
        if (mounted) {
          setState(() {
            _isGameInitialized = true; // Все равно разрешаем подключение
            _connectionStatus = 'Game ready (limited)';
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Game initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isGameInitialized = true; // Разрешаем подключение даже при ошибке
          _connectionStatus = 'Game ready (some features limited)';
        });
      }
    }
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isConnecting) {
        _loadRooms();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadRooms() async {
    if (_isLoadingRooms) return;

    setState(() {
      _isLoadingRooms = true;
    });

    try {
      final serverUrl = _serverUrlController.text;
      // Извлекаем хост и порт из ws:// URL
      final uri = Uri.parse(serverUrl);
      final httpUrl = 'http://${uri.host}:${uri.port}';

      debugPrint('🔍 Loading rooms from: $httpUrl/rooms');

      final response = await http.get(Uri.parse('$httpUrl/rooms'));
      if (response.statusCode == 200) {
        debugPrint('✅ Rooms loaded successfully!');
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _availableRooms = data
              .map((json) => RoomInfo.fromJson(json))
              .toList();
        });
        _connectionStatus =
            'Connected to server (${_availableRooms.length} rooms)';

        // Логируем событие
        _eventLogger.addEvent(
          'rooms_loaded',
          message: 'Found ${_availableRooms.length} rooms',
        );
      } else {
        debugPrint('❌ Server responded with status: ${response.statusCode}');
        _connectionStatus = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ Failed to load rooms: $e');
      _connectionStatus = 'Cannot connect to server';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = 'Testing...';
    });

    try {
      final uri = Uri.parse(_serverUrlController.text);
      final httpUrl = 'http://${uri.host}:${uri.port}';

      debugPrint('🔍 Testing: $httpUrl');

      // Тестируем ping
      final pingResponse = await http.get(Uri.parse('$httpUrl/ping'));

      if (pingResponse.statusCode == 200) {
        final data = jsonDecode(pingResponse.body);
        debugPrint('✅ Ping successful: $data');

        setState(() {
          _connectionStatus = '✅ Server OK! Games: ${data['games'] ?? 0}';
        });
        _showSnackBar('✅ Server is running!');

        _eventLogger.addEvent(
          'connection_test',
          message: 'Server ping successful',
          data: data,
        );

        // Также загрузим комнаты
        await _loadRooms();
      } else {
        debugPrint('❌ Ping failed with status: ${pingResponse.statusCode}');
        setState(() {
          _connectionStatus = '❌ Ping failed: ${pingResponse.statusCode}';
        });
        _showSnackBar('❌ Server error: ${pingResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Test connection error: $e');
      setState(() {
        _connectionStatus = '❌ Cannot connect to server';
      });
      _showSnackBar('❌ Cannot connect to server: $e');
    }
  }

  Future<void> _connectToRoom(
    String serverUrl,
    String playerName,
    String roomId,
  ) async {
    _eventLogger.addEvent(
      'connect_attempt',
      message: 'Connecting to room: $roomId',
      roomId: roomId,
    );

    setState(() {
      _connectionStatus = 'Connecting to room...';
      _isConnecting = true;
    });

    debugPrint('🎮 Connecting to room...');
    debugPrint('  Server: $serverUrl');
    debugPrint('  Player: $playerName');
    debugPrint('  Room: $roomId');

    try {
      // Проверяем сервер
      final uri = Uri.parse(serverUrl);
      final httpUrl = 'http://${uri.host}:${uri.port}';

      debugPrint('🔍 Checking server...');
      final pingResponse = await http.get(Uri.parse('$httpUrl/ping'));

      if (pingResponse.statusCode != 200) {
        throw Exception('Server not responding (${pingResponse.statusCode})');
      }

      debugPrint('✅ Server OK');

      // Ждем networkManager если ещё не готов
      if (game.gameWorld?.networkManager == null) {
        debugPrint('⚠️ NetworkManager is null, waiting...');
        int attempts = 0;
        while (game.gameWorld?.networkManager == null && attempts < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
        if (game.gameWorld?.networkManager == null) {
          throw Exception('NetworkManager initialization timeout');
        }
      }

      debugPrint('✅ NetworkManager ready!');

      // Настраиваем связь логгера с клиентом
      final networkManager = game.gameWorld!.networkManager!;
      _eventLogger.onSendEventToServer = (eventData) {
        networkManager.client.sendEventToServer(
          type: eventData['type'] as String,
          roomId: eventData['roomId'] as String?,
          playerId: eventData['playerId'] as String?,
          message: eventData['message'] as String?,
          data: eventData['data'],
        );
      };

      // Подключаемся
      await game.connectToGame(serverUrl, playerName, roomId);
      debugPrint('✅ Game connected successfully');

      _eventLogger.addEvent(
        'connected',
        message: 'Successfully connected to room: $roomId',
        roomId: roomId,
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        debugPrint('🚀 Navigating to game screen...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Connection error: $e');
      debugPrint('Stack trace: $stackTrace');

      _eventLogger.addEvent(
        'error',
        message: 'Connection error: $e',
        roomId: roomId,
      );

      if (mounted) {
        setState(() {
          _connectionStatus = 'Connection failed';
          _isConnecting = false;
        });
        _showSnackBar('Connection failed: $e');
      }
    }
  }

  Future<void> _connectToSelectedRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (_selectedRoomId == null && _roomIdController.text.trim().isEmpty) {
      _showSnackBar('Please select or enter a room ID');
      return;
    }

    final roomId = _selectedRoomId ?? _roomIdController.text.trim();
    final serverUrl = _serverUrlController.text;
    final playerName = _playerNameController.text.trim();

    setState(() {
      _isConnecting = true;
    });

    await _connectToRoom(serverUrl, playerName, roomId);
  }

  Future<void> _startGameInRoom() async {
    if (_selectedRoomId == null && _roomIdController.text.trim().isEmpty) {
      _showSnackBar('Please select or enter a room ID first');
      return;
    }

    final roomId = _selectedRoomId ?? _roomIdController.text.trim();
    final uri = Uri.parse(_serverUrlController.text);
    final httpUrl = 'http://${uri.host}:${uri.port}';

    try {
      debugPrint('🎮 Starting game in room: $roomId');

      final response = await http.post(
        Uri.parse('$httpUrl/api/admin/room/$roomId/start'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _showSnackBar('✅ Game started!');
        debugPrint('✅ Game start command sent');
      } else {
        _showSnackBar('Failed to start game: ${response.statusCode}');
        debugPrint('❌ Failed to start game: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Start game error: $e');
      _showSnackBar('Error starting game: $e');
    }
  }

  Future<void> _sendTestMessage() async {
    if (_selectedRoomId == null && _roomIdController.text.trim().isEmpty) {
      _showSnackBar('Please select or enter a room ID first');
      return;
    }

    final roomId = _selectedRoomId ?? _roomIdController.text.trim();
    final uri = Uri.parse(_serverUrlController.text);
    final httpUrl = 'http://${uri.host}:${uri.port}';

    try {
      debugPrint('📨 Sending test message to room: $roomId');

      final response = await http.post(
        Uri.parse('$httpUrl/api/admin/room/$roomId/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'Test message from Flutter client',
          'sender': _playerNameController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('✅ Test message sent!');
        debugPrint('✅ Test message sent');
      } else {
        _showSnackBar('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Send message error: $e');
      _showSnackBar('Error sending message: $e');
    }
  }

  Future<void> _createAndConnectToRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Creating room...';
    });

    final newRoomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
    final serverUrl = _serverUrlController.text;
    final playerName = _playerNameController.text.trim();

    try {
      final uri = Uri.parse(serverUrl);
      final httpUrl = 'http://${uri.host}:${uri.port}';

      debugPrint('🏠 Creating room: $newRoomId');
      _eventLogger.addEvent(
        'creating_room',
        message: 'Creating room: $newRoomId',
      );

      final response = await http.post(
        Uri.parse('$httpUrl/api/admin/room/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roomId': newRoomId, 'maxPlayers': 4}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Room created successfully: $newRoomId');
        _showSnackBar('✅ Room created: $newRoomId');

        // Подключаемся к созданной комнате
        await _connectToRoom(serverUrl, playerName, newRoomId);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        debugPrint('❌ Failed to create room: $error');
        _showSnackBar('Failed to create room: $error');
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'Failed to create room';
        });
      }
    } catch (e) {
      debugPrint('❌ Create room error: $e');
      _showSnackBar('Error creating room: $e');
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Create room failed: $e';
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _exportEvents() {
    // Экспорт событий в JSON
    final eventsJson = _eventLogger.events
        .map(
          (e) => {
            'type': e.type,
            'timestamp': e.timestamp.toIso8601String(),
            'roomId': e.roomId,
            'playerId': e.playerId,
            'message': e.message,
          },
        )
        .toList();

    // Показать или сохранить
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Events'),
        content: Text('${eventsJson.length} events exported to console'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    debugPrint('📊 EXPORTED EVENTS: ${jsonEncode(eventsJson)}');
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _playerNameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Widget _buildConnectionForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок
        const Icon(Icons.games, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 16),
        const Text(
          'GRITS GAME',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Multiplayer Arena Shooter',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        const SizedBox(height: 48),

        // Статус подключения
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _connectionStatus.contains('Connected') ||
                        _connectionStatus.contains('ready')
                    ? Icons.check_circle
                    : _connectionStatus.contains('failed')
                    ? Icons.error
                    : Icons.wifi,
                color:
                    _connectionStatus.contains('Connected') ||
                        _connectionStatus.contains('ready')
                    ? Colors.green
                    : _connectionStatus.contains('failed')
                    ? Colors.red
                    : Colors.yellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _connectionStatus,
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Поле Server URL
        TextField(
          controller: _serverUrlController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Server URL',
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.dns, color: Colors.blueAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            filled: true,
            fillColor: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 16),

        // Поле Player Name
        TextField(
          controller: _playerNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Player Name',
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            filled: true,
            fillColor: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 24),

        // Кнопка создания комнаты и подключения
        ElevatedButton(
          onPressed: _isConnecting ? null : _createAndConnectToRoom,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isConnecting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '🎮 CREATE & JOIN NEW ROOM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),

        const SizedBox(height: 16),

        // Разделитель
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[700])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR JOIN EXISTING ROOM',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 16),

        // Список комнат
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingRooms
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _availableRooms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No rooms available\nCreate a new one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = _availableRooms[index];
                    final isSelected = _selectedRoomId == room.id;
                    return ListTile(
                      leading: Icon(
                        Icons.meeting_room,
                        color: room.players >= room.maxPlayers
                            ? Colors.red
                            : Colors.green,
                      ),
                      title: Text(
                        room.id,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Players: ${room.players}/${room.maxPlayers} • ${room.state}',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      selected: isSelected,
                      selectedTileColor: Colors.blueAccent.withOpacity(0.2),
                      onTap: room.players < room.maxPlayers
                          ? () {
                              setState(() {
                                _selectedRoomId = room.id;
                                _roomIdController.clear();
                              });
                            }
                          : null,
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),

        // Поле Room ID (ручной ввод)
        TextField(
          controller: _roomIdController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Room ID',
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.key, color: Colors.blueAccent),
            hintText: 'Or enter room ID manually',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _selectedRoomId = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Кнопка подключения к выбранной комнате
        ElevatedButton(
          onPressed: _isConnecting ? null : _connectToSelectedRoom,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isConnecting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '🔌 JOIN SELECTED ROOM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),

        const SizedBox(height: 16),

        // Строка дополнительных кнопок
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isConnecting ? null : _testConnection,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.orange[700]!),
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isConnecting ? null : _loadRooms,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[600]!),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Кнопки управления комнатой (только если выбрана комната)
        if (_selectedRoomId != null || _roomIdController.text.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startGameInRoom,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.green[700]!),
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sendTestMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('Test Msg'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.blue[700]!),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Информация о сервере
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Server Info',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Default server: ws://localhost:8080',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              Text(
                'Use "Create & Join" to start a new game',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Верхняя панель с заголовком и переключателем
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.games, color: Colors.blueAccent, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'GRITS GAME',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showEventsPanel
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _showEventsPanel = !_showEventsPanel;
                            });
                          },
                          tooltip: 'Toggle events panel',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Основное содержимое
              Expanded(
                child: Row(
                  children: [
                    // Левая панель с формой подключения
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildConnectionForm(),
                      ),
                    ),

                    // Правая панель с событиями (если видна)
                    if (_showEventsPanel)
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey[800]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📡 Events Log',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          size: 20,
                                          color: Colors.grey[500],
                                        ),
                                        onPressed: () =>
                                            _eventLogger.clearEvents(),
                                        tooltip: 'Clear events',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.download,
                                          size: 20,
                                          color: Colors.grey[500],
                                        ),
                                        onPressed: _exportEvents,
                                        tooltip: 'Export events',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: EventsPanel(
                                logger: _eventLogger,
                                roomFilter: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ЭКРАН ИГРЫ ====================

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isGameReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    try {
      await game.onLoad();
      setState(() {
        _isGameReady = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isGameReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading game...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: MouseRegion(
        cursor: SystemMouseCursors.none,
        child: GestureDetector(
          onTapDown: (_) => SoundManager().onUserInteraction(),
          child: Container(
            color: Colors.black,
            child: GameWidget(game: game, autofocus: true),
          ),
        ),
      ),
    );
  }
}

// ==================== DATA MODELS ====================

class RoomInfo {
  final String id;
  final int players;
  final int maxPlayers;
  final String state;

  RoomInfo({
    required this.id,
    required this.players,
    required this.maxPlayers,
    required this.state,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'] ?? '',
      players: json['players'] ?? 0,
      maxPlayers: json['maxPlayers'] ?? 4,
      state: json['state'] ?? 'waiting',
    );
  }
}
