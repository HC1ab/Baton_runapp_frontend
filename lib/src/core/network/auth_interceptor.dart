import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

final _logger = Logger();

/// Attaches Bearer token to every request.
/// On 401 → attempts silent token refresh → retries original request.
/// On refresh failure → clears tokens (AuthNotifier watches storage change).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Ref ref,
    required Dio dio,
  })  : _ref = ref,
        _dio = dio;

  final Ref _ref;
  final Dio _dio;
  bool _isRefreshing = false;

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
    final status = err.response?.statusCode;

    // Only handle 401 and avoid infinite refresh loop.
    if (status != 401 || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final storage = _ref.read(tokenStorageProvider);
      final pair = await storage.read();

      if (pair == null || pair.refreshToken.isEmpty) {
        await _clearAndForward(handler, err);
        return;
      }

      // Attempt token refresh.
      final refreshResponse = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': pair.refreshToken},
        options: Options(headers: {'Authorization': null}), // No auth header
      );

      final data = refreshResponse.data;
      if (data is! Map<String, Object?> || data['success'] != true) {
        await _clearAndForward(handler, err);
        return;
      }

      final dataMap = data['data'];
      final newAccess = dataMap is Map<String, Object?>
          ? (dataMap['accessToken']?.toString() ?? '')
          : '';

      if (newAccess.isEmpty) {
        await _clearAndForward(handler, err);
        return;
      }

      // Persist new tokens.
      await storage.write(TokenPair(
        accessToken: newAccess,
        refreshToken: pair.refreshToken,
      ));

      // Retry original request with new token.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (e) {
      _logger.w('Token refresh failed', error: e);
      await _clearAndForward(handler, err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearAndForward(
    ErrorInterceptorHandler handler,
    DioException err,
  ) async {
    await _ref.read(tokenStorageProvider).clear();
    handler.next(err);
  }
}
