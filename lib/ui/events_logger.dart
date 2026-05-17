import 'package:flutter/material.dart';

/// Модель события игры
class GameEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final String? roomId;
  final String? playerId;
  final String? message;
  final dynamic data;

  GameEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.roomId,
    this.playerId,
    this.message,
    this.data,
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  IconData get icon {
    if (type.contains('connect')) return Icons.wifi;
    if (type.contains('join')) return Icons.person_add;
    if (type.contains('leave')) return Icons.person_remove;
    if (type.contains('shoot')) return Icons.brightness_1;
    if (type.contains('hit')) return Icons.gavel;
    if (type.contains('kill') || type.contains('death')) return Icons.flash_on;
    if (type.contains('room')) return Icons.meeting_room;
    if (type.contains('error')) return Icons.error;
    return Icons.info;
  }

  Color get color {
    if (type.contains('error')) return Colors.red;
    if (type.contains('connect')) return Colors.green;
    if (type.contains('kill') || type.contains('death')) return Colors.orange;
    if (type.contains('join')) return Colors.blue;
    if (type.contains('leave')) return Colors.grey;
    return Colors.white70;
  }
}

/// Логгер событий игры (Singleton)
class EventsLogger extends ChangeNotifier {
  static final EventsLogger _instance = EventsLogger._internal();
  factory EventsLogger() => _instance;
  EventsLogger._internal();

  final List<GameEvent> _events = [];

  // Ссылка на GameClient для отправки событий на сервер
  Function(Map<String, dynamic>)? onSendEventToServer;

  List<GameEvent> get events => List.unmodifiable(_events);

  void addEvent(
    String type, {
    String? roomId,
    String? playerId,
    String? message,
    dynamic data,
  }) {
    final event = GameEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      roomId: roomId,
      playerId: playerId,
      message: message,
      data: data,
    );
    _events.insert(0, event);

    // Ограничиваем количество событий
    if (_events.length > 200) _events.removeLast();

    notifyListeners();

    // Логируем в консоль
    debugPrint('📡 EVENT: $type ${message != null ? '- $message' : ''}');

    // Отправляем событие на сервер если есть колбэк
    if (onSendEventToServer != null) {
      onSendEventToServer!({
        'type': type,
        'roomId': roomId,
        'playerId': playerId,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void clearEvents() {
    _events.clear();
    notifyListeners();
  }

  List<GameEvent> getEventsByRoom(String? roomId) {
    if (roomId == null) return events;
    return events.where((e) => e.roomId == roomId).toList();
  }
}
