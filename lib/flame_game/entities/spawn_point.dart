// // lib/flame_game/entities/spawn_point.dart
// import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math.dart' hide Colors;
// import 'package:flutter_grits/flame_game/entities/game_entity.dart';
// import 'package:flutter_grits/flame_game/game/world/game_world.dart';

// class SpawnPoint extends GameEntity {
//   final int team;

//   SpawnPoint({
//     required Vector2 position,
//     required this.team,
//     required GameWorld gameWorld,
//   }) : super(position: position, gameWorld: gameWorld, size: Vector2(32, 32));

//   @override
//   void onInit() {
//     debugPrint('🏃 SpawnPoint created for team $team at $position');
//   }

//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);

//     // Визуализация для отладки
//     final color = team == 0 ? Colors.blue : Colors.red;
//     canvas.drawCircle(
//       Offset.zero,
//       size.x / 2,
//       Paint()
//         ..color = color.withOpacity(0.5)
//         ..style = PaintingStyle.fill,
//     );
//     canvas.drawCircle(
//       Offset.zero,
//       size.x / 2,
//       Paint()
//         ..color = Colors.white
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2,
//     );

//     // Текст "Spawn"
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: 'Spawn ${team == 0 ? 'Blue' : 'Red'}',
//         style: const TextStyle(color: Colors.white, fontSize: 10),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(-textPainter.width / 2, -size.y / 2 - 5));
//   }
// }
