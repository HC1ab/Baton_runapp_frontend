import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

final _logger = Logger();

/// Abstract interface — allows MockAuthService to substitute in dev mode.
abstract class AuthServiceBase {
  Future<TokenPair> login({
    required String email,
    required String password,
  });

  Future<UserModel> getMe(String accessToken);

  Future<void> logout();
}

// ---------------------------------------------------------------------------

/// Real implementation using Dio.
/// All API calls live here — never call Dio outside service files.
class AuthService implements AuthServiceBase {
  const AuthService(this._dio);

  final Dio _dio;

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
      if (access.isEmpty) throw const ServerException(ErrorMessages.invalidResponse);
      return TokenPair(accessToken: access, refreshToken: refresh);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      _logger.e('login error', error: e);
      throw const UnknownException();
    }
  }

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
      throw _mapDioError(e);
    } catch (e) {
      _logger.e('getMe error', error: e);
      throw const UnknownException();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      _logger.e('logout error', error: e);
      throw const UnknownException();
    }
  }

  // --- Helpers ---

  /// Unwraps { success: true, data: ... } envelope.
  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['success'] == true) return raw['data'];
      final msg = (raw['message'] ?? ErrorMessages.serverError).toString();
      throw ServerException(msg);
    }
    throw const ServerException(ErrorMessages.invalidResponse);
  }

  AppException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
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

/// Swap to mockAuthServiceProvider in dev mode via override in main.dart.
final authServiceProvider = Provider<AuthServiceBase>((ref) {
  // Dio instance here is a plain one — token attachment is handled by
  // AuthInterceptor in dio_client.dart (used for other requests).
  // Login/getMe use their own header logic inside the service.
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
  return AuthService(dio);
});
