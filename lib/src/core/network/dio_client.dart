import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import 'api_log_interceptor.dart';
import 'auth_interceptor.dart';

// ENV=dev 여부 확인
const _env = String.fromEnvironment('ENV', defaultValue: 'dev');
bool get _isDev => _env == 'dev';

/// Singleton Dio instance with AuthInterceptor attached.
/// Dev 환경에서는 ApiLogInterceptor 추가로 request/response 콘솔 출력.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: ApiConstants.connectTimeoutMs),
      receiveTimeout:
          const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Dev 환경에서만 로그 인터셉터 추가
  if (_isDev) {
    dio.interceptors.add(ApiLogInterceptor());
  }

  dio.interceptors.add(
    AuthInterceptor(ref: ref, dio: dio),
  );

  return dio;
});
