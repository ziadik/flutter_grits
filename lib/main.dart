import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' hide Animation, Image, Text;
import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';
import 'package:flutter_grits/flame_game/managers/sound_manager.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем звуковой менеджер
  await SoundManager().init();

  ResourceManager resourceManager = ResourceManager();
  await resourceManager.loadResources();
  // Запускаем игру в полноэкранном режиме
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
        body: Container(
          color: Colors.black,
          child: GameWidget(
            game: GritsGame(resourceManager: resourceManager),
            autofocus: true,
            mouseCursor: MouseCursor.uncontrolled,
            // Опционально: добавляем overlay для паузы
            // overlayBuilderMap: {
            //   'PauseMenu': (context, game) =>
            //       _PauseMenu(game: game as GritsGame),
            // },
          ),
        ),
      ),
    );
  }
}
