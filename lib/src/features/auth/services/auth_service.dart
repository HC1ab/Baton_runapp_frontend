import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/character/character_style.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

// ---------------------------------------------------------------------------
// Login Result
// ---------------------------------------------------------------------------

/// Full login response — token pair + initial core color + nickname + title.
class LoginResult {
  const LoginResult({
    required this.tokenPair,
    required this.coreColorCode,
    required this.nickname,
    required this.equippedTitleCode,
  });

  final TokenPair tokenPair;

  /// Backend CHAR_* code (e.g. CHAR_BLACK / CHAR_RED)
  final String coreColorCode;

  final String nickname;

  /// Backend TITLE_* code (e.g. TITLE_001_GOLD)
  final String equippedTitleCode;
}

final _logger = Logger();

/// Abstract interface for auth operations.
abstract class AuthServiceBase {
  Future<LoginResult> login({
    required String email,
    required String password,
  });

  /// Kakao login: send Kakao access token to backend -> receive our JWT.
  Future<LoginResult> loginWithKakao({required String kakaoAccessToken});

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

  Future<void> deleteAccount({required String password});
}

// ---------------------------------------------------------------------------
// Real implementation
// ---------------------------------------------------------------------------

class AuthService implements AuthServiceBase {
  const AuthService(this._dio);
  final Dio _dio;

  // ── Login ────────────────────────────────────────────────────────────────
  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = _unwrap(response.data);
      return _parseLoginResult(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('login error', error: e);
      throw const UnknownException();
    }
  }

  // ── Kakao Login ──────────────────────────────────────────────────────────
  @override
  Future<LoginResult> loginWithKakao({required String kakaoAccessToken}) async {
    try {
      final response = await _dio.post(
        ApiConstants.kakaoLogin,
        data: {'accessToken': kakaoAccessToken},
      );

      final data = _unwrap(response.data);
      return _parseLoginResult(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('kakao login error', error: e);
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

  // ── Delete Account ────────────────────────────────────────────────────────
  @override
  Future<void> deleteAccount({required String password}) async {
    try {
      await _dio.delete(
        ApiConstants.me,
        data: {'password': password},
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('deleteAccount error', error: e);
      throw const UnknownException();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  LoginResult _parseLoginResult(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ServerException(ErrorMessages.invalidResponse);
    }

    final access = (data['accessToken'] ?? '').toString();
    final refresh = (data['refreshToken'] ?? '').toString();

    // 백엔드가 coreColorCode / nickname / equippedTitleCode 내려주는 기준
    final coreColorCode =
        (data['coreColorCode'] ?? CharacterStylePresets.defaultStyle.code)
            .toString();
    final nickname = (data['nickname'] ?? '').toString();
    final equippedTitleCode = (data['equippedTitleCode'] ?? '').toString();

    if (access.isEmpty) {
      throw const ServerException(ErrorMessages.invalidResponse);
    }

    return LoginResult(
      tokenPair: TokenPair(accessToken: access, refreshToken: refresh),
      coreColorCode: coreColorCode,
      nickname: nickname,
      equippedTitleCode: equippedTitleCode,
    );
  }

  /// Unwraps { success: true, data: ... } envelope.
  /// Also handles { status: 'fail', code: ..., message: ... } format.
  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['success'] == true) return raw['data'];

      final msg =
          (raw['message'] ?? raw['error'] ?? ErrorMessages.serverError)
              .toString();
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
  return AuthService(ref.watch(dioProvider));
});

final authServiceWithTokenProvider = Provider<AuthServiceBase>((ref) {
  return AuthService(ref.watch(dioProvider));
});
