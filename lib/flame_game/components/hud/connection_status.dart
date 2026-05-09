// Компонент отображения статуса подключения

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_grits/network/game_client.dart'
    show ConnectionState, GameClient;

class ConnectionStatusComponent extends PositionComponent {
  final GameClient gameClient;
  late TextComponent _statusText;
  late TextComponent _pingText;

  double _pingValue = 0;
  double _pingTime = 0;

  ConnectionStatusComponent({required this.gameClient, Vector2? position})
    : super(position: position ?? Vector2(10, 10)) {
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _statusText = TextComponent(
      text: '● Disconnected',
      position: Vector2(0, 0),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
        ),
      ),
    );

    _pingText = TextComponent(
      text: 'Ping: --- ms',
      position: Vector2(0, 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
        ),
      ),
    );

    await add(_statusText);
    await add(_pingText);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Обновляем статус
    final state = gameClient.connectionState;
    String statusText;
    Color statusColor;

    switch (state) {
      case ConnectionState.connected:
        statusText = '● Connected';
        statusColor = Colors.green;
        break;
      case ConnectionState.connecting:
        statusText = '● Connecting...';
        statusColor = Colors.yellow;
        break;
      case ConnectionState.reconnecting:
        statusText = '● Reconnecting...';
        statusColor = Colors.orange;
        break;
      case ConnectionState.failed:
        statusText = '● Connection Failed';
        statusColor = Colors.red;
        break;
      case ConnectionState.disconnected:
        statusText = '● Disconnected';
        statusColor = Colors.red;
        break;
    }

    _statusText.text = statusText;
    _statusText.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: statusColor,
        shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
      ),
    );

    // Симуляция пинга (можно заменить на реальный из WebSocket)
    _pingTime += dt;
    if (_pingTime >= 1.0) {
      _pingTime = 0;
      _pingValue =
          _pingValue * 0.7 +
          (20 + DateTime.now().millisecondsSinceEpoch % 50) * 0.3;
      _pingText.text = 'Ping: ${_pingValue.toInt()} ms';
    }
  }
}
