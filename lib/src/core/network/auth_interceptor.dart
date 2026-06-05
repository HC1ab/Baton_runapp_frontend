import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../storage/token_storage.dart';

final _logger = Logger();

/// A001/A002/A003 — 토큰 인증 실패 코드. 감지 시 강제 로그아웃.
const _authErrorCodes = {'A001', 'A002', 'A003'};

/// Attaches Bearer token to every request.
/// 토큰 갱신(refresh)은 미구현 — 추후 /member/refresh API 구현 후 추가 예정.
/// A001/A002/A003 수신 시 forceLogout → GoRouter가 로그인 화면으로 리다이렉션.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Ref ref,
    required Dio dio,
  }) : _ref = ref;

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
    if (err.response?.statusCode == 401) {
      final code = _extractErrorCode(err.response);
      _logger.w('401 received (code: $code) — ${err.requestOptions.method} ${err.requestOptions.path}');

      if (code != null && _authErrorCodes.contains(code)) {
        _logger.w('Auth error $code → forceLogout');
        await _ref.read(authProvider.notifier).forceLogout();
      }
    }
    handler.next(err);
  }

  String? _extractErrorCode(Response<dynamic>? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) return data['code'] as String?;
    } catch (_) {}
    return null;
  }
}
