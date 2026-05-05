/// API endpoint and timeout constants.
abstract final class ApiConstants {
  // Base URL is injected via --dart-define=API_BASE_URL=https://...
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator localhost
  );

  // Timeouts
  static const connectTimeoutMs = 5000;
  static const receiveTimeoutMs = 10000;

  // Endpoints — Auth
  static const login = '/api/v1/member/login';
  static const logout = '/api/v1/member/logout';
  static const join = '/api/v1/member/join';
  static const me = '/api/v1/member/me';
  static const refresh = '/api/v1/member/refresh';
}
