// lib/managers/input_manager.dart
import 'package:flutter/services.dart';
import 'package:flame/input.dart';
import 'package:vector_math/vector_math.dart';

class InputManager {
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  Vector2 get moveDirection {
    Vector2 direction = Vector2.zero();

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }

    if (direction.length2 > 0) {
      direction.normalize();
    }

    return direction;
  }

  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  void update(double dt) {
    // Дополнительная логика обновления ввода
  }

  void reset() {
    _pressedKeys.clear();
  }
}
