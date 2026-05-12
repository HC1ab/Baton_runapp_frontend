import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API endpoint and timeout constants.
abstract final class ApiConstants {
  // .env 파일에서 API_BASE_URL 읽기
  // 없으면 Android 에뮬레이터 localhost 기본값 사용
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  // Timeouts
  static const connectTimeoutMs = 5000;
  static const receiveTimeoutMs = 10000;

  // Endpoints — Auth
  static const login = '/api/v1/member/login';
  static const logout = '/api/v1/member/logout';
  static const join = '/api/v1/member/join';
  static const me = '/api/v1/member/me';
  // TODO: refresh API 구현 후 활성화
  // static const refresh = '/api/v1/member/refresh';
  static const password = '/api/v1/member/password';

  // Endpoints — Run
  static const runStart = '/api/v1/runs/start';
  static const runFinish = '/api/v1/runs'; // + /{runId}/finish

  // Endpoints — Spot
  static const spots = '/api/v1/spots';
  static const spotsNearby = '/api/v1/spots/nearby';
}
