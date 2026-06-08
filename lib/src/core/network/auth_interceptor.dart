import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../storage/token_storage.dart';
final _logger = Logger();

/// 토큰 인증 실패 코드 (A001/A002/A003) → forceLogout.
/// code 없는 401은 forceLogout 대상 아님 — 정원 초과·권한 부족 등
/// 비즈니스 로직 401도 code 없이 올 수 있으므로 명시적 코드만 처리.
const _tokenAuthCodes = {'A001', 'A002', 'A003'};

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

      // A001/A002/A003만 forceLogout — code 없는 401은 비즈니스 로직 에러일 수 있음
      if (_tokenAuthCodes.contains(code)) {
        if (_ref.read(authProvider) is AuthStateUnauthenticated) {
          _logger.d('forceLogout skipped — already unauthenticated');
        } else {
          _logger.w('Auth token failure (code: $code) → forceLogout');
          await _ref.read(authProvider.notifier).forceLogout();
        }
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
