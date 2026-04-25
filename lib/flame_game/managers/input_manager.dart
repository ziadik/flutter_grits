// lib/managers/input_manager.dart
import 'package:flutter/services.dart';
import 'package:flame/input.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/material.dart';
import 'sound_manager.dart';

class InputManager {
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final Set<LogicalKeyboardKey> _justPressedKeys =
      {}; // Ключи, нажатые в этом кадре

  // Для мыши/сенсора
  Vector2? _mousePosition;
  Vector2? _targetPosition;
  bool _mousePressed = false;
  bool _useMouseMovement = false;

  // Для стрельбы
  bool _isLeftMousePressed = false;
  bool _isRightMousePressed = false;
  bool _isMiddleMousePressed = false;

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

  // Геттеры для состояния кнопок мыши
  bool get isLeftMousePressed => _isLeftMousePressed;
  bool get isRightMousePressed => _isRightMousePressed;
  bool get isMiddleMousePressed => _isMiddleMousePressed;

  // Геттер для пробела
  bool get isSpacePressed => _pressedKeys.contains(LogicalKeyboardKey.space);

  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      _justPressedKeys.add(event.logicalKey);
      _notifyUserInteraction(); // Веб: разрешаем звук
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  void handleMouseMove(Vector2 position) {
    _mousePosition = position;
    _notifyUserInteraction(); // Веб: разрешаем звук
  }

  void handleMousePress(Vector2 position) {
    _mousePressed = true;
    _targetPosition = position;
    _useMouseMovement = true;
    _isLeftMousePressed = true;
    _notifyUserInteraction(); // Веб: разрешаем звук
  }

  void handleMouseButtonPress(int button) {
    _notifyUserInteraction(); // Веб: разрешаем звук
    if (button == 1) {
      _isLeftMousePressed = true;
    } else if (button == 2) {
      _isRightMousePressed = true;
    } else if (button == 3) {
      _isMiddleMousePressed = true;
    }
  }

  void handleKeyboardAction() {
    _notifyUserInteraction(); // Веб: разрешаем звук
  }

  void _notifyUserInteraction() {
    // Уведомляем SoundManager о взаимодействии пользователя
    SoundManager().onUserInteraction();
  }

  void handleMouseRelease() {
    _mousePressed = false;
    _targetPosition = null;
    _useMouseMovement = false;
    _isLeftMousePressed = false;
    _isRightMousePressed = false;
    _isMiddleMousePressed = false;
  }

  void handleMouseButtonRelease(int button) {
    if (button == 1) {
      _isLeftMousePressed = false;
    } else if (button == 2) {
      _isRightMousePressed = false;
    } else if (button == 3) {
      _isMiddleMousePressed = false;
    }
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
    // Очистка justPressedKeys в конце кадра
    _justPressedKeys.clear();
  }

  Set<LogicalKeyboardKey> getPressedKeys() {
    return _pressedKeys;
  }

  /// Получить клавиши, нажатые только в этом кадре (для переключения оружия)
  Set<LogicalKeyboardKey> getJustPressedKeys() {
    return _justPressedKeys;
  }

  /// Проверить, была ли нажата цифра для смены оружия (1, 2, 3)
  int? getWeaponSlotKeyPress() {
    final justPressed = getJustPressedKeys();

    if (justPressed.contains(LogicalKeyboardKey.digit1) ||
        justPressed.contains(LogicalKeyboardKey.numpad1)) {
      return 0;
    } else if (justPressed.contains(LogicalKeyboardKey.digit2) ||
        justPressed.contains(LogicalKeyboardKey.numpad2)) {
      return 1;
    } else if (justPressed.contains(LogicalKeyboardKey.digit3) ||
        justPressed.contains(LogicalKeyboardKey.numpad3)) {
      return 2;
    }

    return null;
  }

  void reset() {
    _pressedKeys.clear();
    _justPressedKeys.clear();
    _mousePressed = false;
    _targetPosition = null;
    _useMouseMovement = false;
  }
}
