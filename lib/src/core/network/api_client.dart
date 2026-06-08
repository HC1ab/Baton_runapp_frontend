import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: $code, message: $message)';
}

String formatApiErrorMessage(ApiException e) {
  if (e.statusCode != null) {
    return '[${e.statusCode}] ${e.message}';
  }
  return e.message;
}

/// Social 기능 전용 Dio — tokenStorageProvider에서 토큰을 비동기로 읽어 헤더에 부착.
/// 기존 session_controller 의존을 tokenStorageProvider로 교체.
final socialDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ??
          'http://api.baton-running-app.kro.kr:8080',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // [iOS 대응] FlutterSecureStorage iOS keychain 접근 확인 필요
        final storage = ref.read(tokenStorageProvider);
        final pair = await storage.read();
        final token = pair?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        handler.next(e);
      },
    ),
  );
  return dio;
});

/// useMockApis — social_providers.dart 에서 참조
/// .env.dev 에 USE_MOCK_API=true 추가 시 활성화
bool get useMockApis => dotenv.env['USE_MOCK_API'] == 'true';

dynamic unwrapApiResponse(dynamic data) {
  // Success: { success: true, message: "...", data: ... }
  // Error:   { status: "fail", code: "...", message: "..." }
  //          { success: false, message: "...", data: "..." }
  if (data is Map<String, dynamic>) {
    if (data['success'] == true) {
      return data['data'];
    }
    if (data['success'] == false) {
      final msg = (data['message'] ?? data['data'] ?? '요청에 실패했습니다.')
          .toString();
      final code = data['code']?.toString();
      throw ApiException(msg, code: code);
    }
    if (data['status'] == 'fail') {
      final msg = (data['message'] ?? '요청에 실패했습니다.').toString();
      final code = data['code']?.toString();
      throw ApiException(msg, code: code);
    }
  }
  throw ApiException('알 수 없는 응답 형식입니다.');
}

Future<T> requestJson<T>(
  Dio dio,
  Future<Response<dynamic>> Function() call, {
  T Function(dynamic json)? mapper,
}) async {
  try {
    final res = await call();
    final unwrapped = unwrapApiResponse(res.data);
    if (mapper != null) return mapper(unwrapped);
    return unwrapped as T;
  } on DioException catch (e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['status'] == 'fail' || data['success'] == false) {
        throw ApiException(
          (data['message'] ?? data['data'] ?? '요청에 실패했습니다.').toString(),
          code: data['code']?.toString(),
          statusCode: statusCode,
        );
      }
    }
    throw ApiException('네트워크 오류가 발생했습니다.', statusCode: statusCode);
  }
}
