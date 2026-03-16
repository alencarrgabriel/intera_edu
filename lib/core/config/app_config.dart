class AppConfig {
  static const String appName = 'InteraEdu';
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const bool devMode = true;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;
}
