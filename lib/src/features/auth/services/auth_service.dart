import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

final _logger = Logger();

/// Abstract interface for auth operations.
abstract class AuthServiceBase {
  Future<TokenPair> login({
    required String email,
    required String password,
  });

  /// Returns new member id from `{ success: true, data: <id> }`.
  Future<int> join({
    required String email,
    required String password,
    required String realname,
    required String nickname,
  });

  Future<UserModel> getMe(String accessToken);

  Future<void> logout();

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

// ---------------------------------------------------------------------------
// Real implementation
// ---------------------------------------------------------------------------

class AuthService implements AuthServiceBase {
  const AuthService(this._dio);
  final Dio _dio;

  // ── Login ────────────────────────────────────────────────────────────────
  @override
  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      final access = (data['accessToken'] ?? '').toString();
      final refresh = (data['refreshToken'] ?? '').toString();
      if (access.isEmpty) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return TokenPair(accessToken: access, refreshToken: refresh);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('login error', error: e);
      throw const UnknownException();
    }
  }

  // ── Join ─────────────────────────────────────────────────────────────────
  @override
  Future<int> join({
    required String email,
    required String password,
    required String realname,
    required String nickname,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.join,
        data: {
          'email': email,
          'password': password,
          'realname': realname,
          'nickname': nickname,
        },
      );
      final data = _unwrap(response.data);
      if (data is int) return data;
      if (data is num) return data.toInt();
      throw const ServerException(ErrorMessages.invalidResponse);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('join error', error: e);
      throw const UnknownException();
    }
  }

  // ── GetMe ────────────────────────────────────────────────────────────────
  @override
  Future<UserModel> getMe(String accessToken) async {
    try {
      final response = await _dio.get(
        ApiConstants.me,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      final data = _unwrap(response.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getMe error', error: e);
      throw const UnknownException();
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('logout error', error: e);
      throw const UnknownException();
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────
  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch(
        ApiConstants.password,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('changePassword error', error: e);
      throw const UnknownException();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Unwraps { success: true, data: ... } envelope.
  /// Also handles { status: 'fail', code: ..., message: ... } format.
  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      // 성공 응답: { success: true, data: ... }
      if (raw['success'] == true) return raw['data'];

      // 실패 응답: { status: 'fail', code: ..., message: ... }
      final msg = (raw['message'] ?? raw['error'] ?? ErrorMessages.serverError).toString();
      throw ServerException(msg);
    }
    throw const ServerException(ErrorMessages.invalidResponse);
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      if (body['status'] == 'fail' || body['success'] == false) {
        final msg =
            (body['message'] ?? body['data'] ?? ErrorMessages.serverError)
                .toString();
        return ServerException(msg);
      }
    }
    if (status == 401) return const AuthException();
    if (status != null && status >= 500) return const ServerException();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return const UnknownException();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthServiceBase>((ref) {
  // dioProvider 재사용 → ApiLogInterceptor 자동 적용
  // AuthInterceptor가 붙어있지만 login/join은 토큰 없이 호출하므로 문제없음
  // [iOS 대응] iOS 인증서 문제 발생 시 dio_client.dart의 AuthInterceptor 확인 필요
  return AuthService(ref.watch(dioProvider));
});

/// changePassword는 인증된 상태에서 호출 → AuthInterceptor가 붙은 Dio 사용
final authServiceWithTokenProvider = Provider<AuthServiceBase>((ref) {
  return AuthService(ref.watch(dioProvider));
});
