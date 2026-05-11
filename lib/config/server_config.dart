/// Конфигурация сервера для сетевого подключения
class ServerConfig {
  // URL сервера для локальной разработки (iOS симулятор/устройство)
  // Замените на ваш IP-адрес (найдите через: ipconfig getifaddr en0)
  static const String host = '192.168.3.15';
  static const int port = 8080;

  // Для локального запуска на том же устройстве (только Android/веб)
  static const String localhost = 'localhost';

  // WebSocket URL
  static String get wsUrl => 'ws://$host:$port';
  static String get httpUrl => 'http://$host:$port';

  // Для отладки: использовать localhost или IP
  static bool useLocalhost = false;

  static String get effectiveHost => useLocalhost ? localhost : host;
  static String get effectiveWsUrl => 'ws://$effectiveHost:$port';
  static String get effectiveHttpUrl => 'http://$effectiveHost:$port';
}
