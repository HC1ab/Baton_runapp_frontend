import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/spot_cooldown_model.dart';

final _logger = Logger();

class SpotApi {
  const SpotApi(this._dio);
  final Dio _dio;

  /// GET /api/v1/spots/cooldowns — 내가 방문한 스팟 목록 + 쿨타임 정보
  Future<List<SpotCooldownModel>> getCooldowns() async {
    try {
      final response = await _dio.get(ApiConstants.spotsCooldowns);
      final unwrapped = unwrapApiResponse(response.data);
      if (unwrapped is! List<dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return unwrapped
          .map((e) => SpotCooldownModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.lastCheckinAt.compareTo(a.lastCheckinAt));
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('getCooldowns error', error: e);
      throw const UnknownException();
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return const AuthException();
    if (status != null && status >= 500) return const ServerException();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) return const NetworkException();
    return const UnknownException();
  }
}
