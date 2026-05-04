import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

/// Глобальный ключ для доступа к Navigator из Flame кода
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late GritsGame game;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем SoundManager
  await SoundManager().init();

  // Загружаем ресурсы с обработкой ошибок
  final resourceManager = ResourceManager();
  game = GritsGame(resourceManager: resourceManager);

  try {
    await resourceManager.loadResources();
    debugPrint('✅ Resources loaded successfully');
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
              const Text('❌ Error loading game', style: TextStyle(color: Colors.red, fontSize: 24)),
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
    return MaterialApp(navigatorKey: navigatorKey, debugShowCheckedModeBanner: false, title: 'Grits Game', theme: ThemeData.dark(), home: const ConnectionScreen());
  }
}

// ==================== ЭКРАН ПОДКЛЮЧЕНИЯ ====================

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _serverUrlController = TextEditingController(text: 'ws://localhost:8080');
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();

  String _connectionStatus = 'Not connected';
  bool _isConnecting = false;
  List<RoomInfo> _availableRooms = [];
  bool _isLoadingRooms = false;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _playerNameController.text = 'Player${Random().nextInt(1000)}';
    _loadRooms();

    // Автообновление списка комнат каждые 5 секунд
    Future.delayed(Duration.zero, () {
      _startAutoRefresh();
    });
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

      final response = await http.get(Uri.parse('$httpUrl/rooms'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _availableRooms = data.map((json) => RoomInfo.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load rooms: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
      }
    }
  }

  Future<void> _connectToGame() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (_roomIdController.text.trim().isEmpty && _selectedRoomId == null) {
      _showSnackBar('Please enter room ID or select a room');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    final roomId = _selectedRoomId ?? _roomIdController.text.trim();

    try {
      // Проверяем соединение с сервером
      final uri = Uri.parse(_serverUrlController.text);
      final httpUrl = 'http://${uri.host}:${uri.port}';

      final pingResponse = await http.get(Uri.parse('$httpUrl/ping'));
      if (pingResponse.statusCode != 200) {
        throw Exception('Server not responding');
      }

      // Подключаемся к игре
      await game.connectToGame(_serverUrlController.text, _playerNameController.text.trim(), roomId);

      // Ждём подтверждения подключения
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Переходим в игру
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameScreen()));
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
        _isConnecting = false;
      });
      _showSnackBar('Connection failed: $e');
    }
  }

  void _createNewRoom() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name first');
      return;
    }

    // Генерируем уникальный ID комнаты
    final newRoomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
    _roomIdController.text = newRoomId;
    _selectedRoomId = newRoomId;

    // Создаём комнату через API (опционально)
    try {
      final uri = Uri.parse(_serverUrlController.text);
      final httpUrl = 'http://${uri.host}:${uri.port}';

      await http.post(Uri.parse('$httpUrl/create-room'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'roomId': newRoomId, 'maxPlayers': 4}));
    } catch (e) {
      debugPrint('Create room API error: $e');
    }

    _showSnackBar('Created new room: $newRoomId');
    await _loadRooms();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _playerNameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey[900]!, Colors.black]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок
                  const Icon(Icons.games, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'GRITS GAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4),
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
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(
                          _connectionStatus.contains('Connected')
                              ? Icons.check_circle
                              : _connectionStatus.contains('failed')
                              ? Icons.error
                              : Icons.wifi,
                          color: _connectionStatus.contains('Connected')
                              ? Colors.green
                              : _connectionStatus.contains('failed')
                              ? Colors.red
                              : Colors.yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_connectionStatus, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
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

                  // Разделитель
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[700])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR SELECT ROOM', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Список комнат
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoadingRooms
                        ? const Center(
                            child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
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
                                leading: Icon(Icons.meeting_room, color: room.players >= room.maxPlayers ? Colors.red : Colors.green),
                                title: Text(room.id, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Players: ${room.players}/${room.maxPlayers} • ${room.state}', style: TextStyle(color: Colors.grey[500])),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
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
                  const SizedBox(height: 24),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isConnecting ? null : _loadRooms,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Rooms'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[600]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isConnecting ? null : _createNewRoom,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Room'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.green[700]!),
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Кнопка Connect (главная)
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isConnecting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('CONNECT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 24),

                  // Информация о сервере
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Text('Server Info', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Default server: ws://localhost:8080', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        Text('Make sure the server is running', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              Text('Error: $_errorMessage', style: const TextStyle(color: Colors.white)),
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

  RoomInfo({required this.id, required this.players, required this.maxPlayers, required this.state});

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(id: json['id'] ?? '', players: json['players'] ?? 0, maxPlayers: json['maxPlayers'] ?? 4, state: json['state'] ?? 'waiting');
  }
}
