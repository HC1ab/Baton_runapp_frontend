import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/occupied_spot_model.dart';

final _logger = Logger();

/// 점령 지도 데이터 소스.
///
/// 백엔드 API가 아직 없으므로 아래 두 엔드포인트를 가정하고 호출한다.
/// 엔드포인트/응답 스키마 확정 시 [OccupiedSpot] 및 [ApiConstants] 갱신.
class OccupationApi {
  const OccupationApi(this._dio);
  final Dio _dio;

  /// GET /api/v1/spots/occupied — 모든 사용자의 점령 스팟
  Future<List<OccupiedSpot>> getAllOccupied() =>
      _fetch(ApiConstants.spotsOccupied);

  /// GET /api/v1/spots/occupied/me — 내가 점령한 스팟
  Future<List<OccupiedSpot>> getMyOccupied() =>
      _fetch(ApiConstants.spotsOccupiedMe);

  Future<List<OccupiedSpot>> _fetch(String path) async {
    try {
      final response = await _dio.get(path);
      final unwrapped = unwrapApiResponse(response.data);
      if (unwrapped is! List<dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return unwrapped
          .whereType<Map<String, dynamic>>()
          .map(OccupiedSpot.fromJson)
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('occupied spots fetch error path=$path', error: e);
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
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return const UnknownException();
  }
}
