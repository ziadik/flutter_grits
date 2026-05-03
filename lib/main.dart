import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' hide Animation, Image, Text;
import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';

/// Глобальный ключ для доступа к Navigator из Flame кода
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем SoundManager
  await SoundManager().init();

  // Загружаем ресурсы с обработкой ошибок
  final resourceManager = ResourceManager();
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
      home: Scaffold(
        body: GestureDetector(
          onTapDown: (_) => SoundManager().onUserInteraction(),
          child: MouseRegion(
            cursor: SystemMouseCursors.none,
            child: Container(
              color: Colors.black,
              child: GameWidget(
                game: GritsGame(resourceManager: resourceManager),
                autofocus: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
