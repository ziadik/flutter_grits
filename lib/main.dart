import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' hide Animation, Image, Text;
import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager().init();

  final resourceManager = ResourceManager();
  await resourceManager.loadResources();

  runApp(GameApp(resourceManager: resourceManager));
}

class GameApp extends StatelessWidget {
  final ResourceManager resourceManager;
  const GameApp({super.key, required this.resourceManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grits Game',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: MouseRegion(
          cursor: SystemMouseCursors.none, // Скрываем системный курсор
          child: Container(
            color: Colors.black,
            child: GameWidget(
              game: GritsGame(resourceManager: resourceManager),
              autofocus: true,
            ),
          ),
        ),
      ),
    );
  }
}
