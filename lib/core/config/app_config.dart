class AppConfig {
  static const String appName = 'InteraEdu';
  // Configure per target using:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1   (Android emulator)
  // flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1  (iOS simulator)
  // flutter run --dart-define=API_BASE_URL=http://<LAN_IP>:3000/api/v1   (physical device)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// WebSocket base URL for the messaging gateway (port 3004 = messaging-service).
  /// Override with: --dart-define=WS_BASE_URL=http://10.0.2.2:3004
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'http://localhost:3004',
  );
  static const bool devMode = true;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;
}
