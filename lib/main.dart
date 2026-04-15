import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/game/grits_game.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(game: GritsGame()),
    ),
  );
}
