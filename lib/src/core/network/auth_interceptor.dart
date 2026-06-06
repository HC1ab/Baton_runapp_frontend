import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../storage/token_storage.dart';
final _logger = Logger();

/// 토큰 인증 실패 코드 (A001/A002/A003) → forceLogout.
/// code 없는 401 (Spring Security 레벨 거부)도 forceLogout.
/// C002/G002/G003 등 권한 부족 401은 forceLogout 대상 아님.
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
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // TODO: /member/refresh API 구현 후 토큰 자동 갱신 로직 추가
    if (err.response?.statusCode == 401) {
      final code = _extractErrorCode(err.response);
      _logger.w('401 received (code: $code) — ${err.requestOptions.method} ${err.requestOptions.path}');

      // A001/A002/A003 또는 code 없는 401(Spring Security 필터 레벨 거부) → forceLogout
      // C002/G002/G003 등 권한 부족 코드는 해당 없음 → handler.next로 에러 전파
      final isTokenAuthFailure = code == null || _tokenAuthCodes.contains(code);
      if (isTokenAuthFailure) {
        // 이미 로그아웃 상태면 중복 호출 방지
        if (_ref.read(authProvider) is AuthStateUnauthenticated) {
          _logger.d('forceLogout skipped — already unauthenticated');
        } else {
          _logger.w('Auth token failure (code: $code) → forceLogout (deferred)');
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _ref.read(authProvider.notifier).forceLogout();
          });
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
