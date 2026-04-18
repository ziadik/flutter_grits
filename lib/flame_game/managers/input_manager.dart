// lib/managers/input_manager.dart
import 'package:flutter/services.dart';
import 'package:flame/input.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/material.dart';

class InputManager {
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Для мыши/сенсора
  Vector2? _mousePosition;
  Vector2? _targetPosition;
  bool _mousePressed = false;
  bool _useMouseMovement = false;

  // Настройки
  bool keyboardEnabled = true;
  bool mouseMovementEnabled = true;
  double mouseSensitivity = 1.0;

  Vector2 get moveDirection {
    if (!keyboardEnabled) return Vector2.zero();

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

  // Направление к цели (для мыши)
  Vector2? get targetDirection {
    if (!mouseMovementEnabled || _targetPosition == null) return null;
    return _targetPosition;
  }

  bool get isMouseMoving => _mousePressed && _targetPosition != null;

  Vector2? get mousePosition => _mousePosition;

  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  void handleMouseMove(Vector2 position) {
    _mousePosition = position;
  }

  void handleMousePress(Vector2 position) {
    _mousePressed = true;
    _targetPosition = position;
    _useMouseMovement = true;
  }

  void handleMouseRelease() {
    _mousePressed = false;
    _targetPosition = null;
    _useMouseMovement = false;
  }

  void handleMouseDrag(Vector2 position) {
    if (_mousePressed) {
      _targetPosition = position;
    }
  }

  void setTargetPosition(Vector2? position) {
    _targetPosition = position;
    _useMouseMovement = position != null;
  }

  void toggleKeyboard() {
    keyboardEnabled = !keyboardEnabled;
  }

  void toggleMouseMovement() {
    mouseMovementEnabled = !mouseMovementEnabled;
    if (!mouseMovementEnabled) {
      _targetPosition = null;
      _useMouseMovement = false;
    }
  }

  void update(double dt) {
    // Дополнительная логика обновления ввода
  }
  Set<LogicalKeyboardKey> getPressedKeys() {
    return _pressedKeys;
  }

  void reset() {
    _pressedKeys.clear();
    _mousePressed = false;
    _targetPosition = null;
    _useMouseMovement = false;
  }
}
