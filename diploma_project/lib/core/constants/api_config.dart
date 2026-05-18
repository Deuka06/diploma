/// API base URL — localhost по умолчанию (локальная разработка).
/// Android-эмулятор: --dart-define=API_BASE=http://10.0.2.2:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
