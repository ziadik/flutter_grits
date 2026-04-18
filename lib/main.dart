import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Animation, Image, Text;
import 'package:flutter_grits/flame_game/game/grits_game.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';
import 'package:flutter_grits/flame_game/managers/resource_manager.dart';

// void main() {
//   runApp(GameWidget(game: TiledGame()));
// }

// class TiledGame extends FlameGame {
//   late TiledComponent mapComponent;
//   late GameWorld gameWorld;
//   TiledGame()
//     : super(
//         //camera: CameraComponent.withFixedResolution(width: 2048, height: 2048),
//       );

//   @override
//   Future<void> onLoad() async {
//     mapComponent = await TiledComponent.load('map1.tmx', Vector2.all(64));
//     mapComponent.scale = Vector2.all(1);

//     await world.add(mapComponent);

//     _centerCameraOnMap(Vector2(800.0, 800.0));
//   }

//   Future<void> _centerCameraOnMap(Vector2 gameSize) async {
//     final mapWidth = mapComponent.size.x;
//     final mapHeight = mapComponent.size.y;

//     // camera = CameraComponent.withFixedResolution(
//     //   world: world,
//     //   width: mapWidth,
//     //   height: mapHeight,
//     // );
//     // camera.viewfinder.anchor = Anchor.topLeft;

//     final viewWidth = gameSize.x;
//     final viewHeight = gameSize.y;

//     camera = CameraComponent(
//       world: world,
//       viewport: FixedSizeViewport(viewWidth, viewHeight),
//     );
//     camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
//     camera.viewfinder.anchor = Anchor.center;
//   }

//   @override
//   void onGameResize(Vector2 newSize) {
//     super.onGameResize(newSize);
//     _centerCameraOnMap(newSize); // Пересчитываем при изменении
//   }
// }

// lib/main.dart
// import 'package:flame/game.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_grits/flame_game/game/grits_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

// Компонент меню паузы
// class _PauseMenu extends StatelessWidget {
//   final GritsGame game;

//   const _PauseMenu({required this.game});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Paused', style: TextStyle(fontSize: 24)),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   game.resumeEngine();
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('Resume'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   game.reset();
//                 },
//                 child: const Text('Restart'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   SystemNavigator.pop();
//                 },
//                 child: const Text('Exit'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
