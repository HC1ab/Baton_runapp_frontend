import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../storage/token_storage.dart';

final _logger = Logger();

/// Attaches Bearer token to every request.
/// 토큰 갱신(refresh)은 미구현 — 추후 /member/refresh API 구현 후 추가 예정.
/// 401 발생 시 토큰 클리어 후 에러 전달 (재로그인 필요).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Ref ref,
    required Dio dio,
  })  : _ref = ref;

  final Ref _ref;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(tokenStorageProvider);
    final pair = await storage.read();
    if (pair != null) {
      options.headers['Authorization'] = 'Bearer ${pair.accessToken}';
      _logger.d('Token attached to ${options.method} ${options.path}');
    } else {
      _logger.w('No token found for ${options.method} ${options.path}');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // TODO: /member/refresh API 구현 후 토큰 자동 갱신 로직 추가
    // 현재는 401 발생 시 토큰 클리어 후 에러 그대로 전달
    if (err.response?.statusCode == 401) {
      _logger.w('401 received — clearing token. Re-login required.');
      await _ref.read(tokenStorageProvider).clear();
    }
    handler.next(err);
  }
}
