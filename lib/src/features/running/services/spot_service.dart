import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/spot_model.dart';

final _logger = Logger();

abstract class SpotServiceBase {
  /// POST /api/v1/spots/nearby
  /// Body: { latitude, longitude }
  Future<List<SpotSummary>> nearby({
    required double latitude,
    required double longitude,
  });

  /// GET /api/v1/spots/{spotId}
  /// No request body
  Future<SpotDetail> detail(int spotId);

  /// POST /api/v1/spots/{spotId}/checkin
  Future<int> checkIn({required int spotId});
}

class SpotService implements SpotServiceBase {
  const SpotService(this._dio);
  final Dio _dio;

  // ── Nearby ───────────────────────────────────────────────────────────────
  @override
  Future<List<SpotSummary>> nearby({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // [iOS 대응] iOS에서 동일하게 동작 확인 필요
      final res = await _dio.post(
        ApiConstants.spotsNearby,
        data: {'latitude': latitude, 'longitude': longitude},
      );
      final data = _unwrap(res.data);
      if (data is! List) throw const ServerException();
      return data
          .whereType<Map<String, Object?>>()
          .map(SpotSummary.fromJson)
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('nearby spots error', error: e);
      throw const UnknownException();
    }
  }

  // ── Detail ───────────────────────────────────────────────────────────────
  @override
  Future<SpotDetail> detail(int spotId) async {
    try {
      // GET /api/v1/spots/{spotId} — no request body
      final res = await _dio.get('${ApiConstants.spots}/$spotId');
      final data = _unwrap(res.data);
      if (data is! Map<String, Object?>) throw const ServerException();
      return SpotDetail.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('spot detail error', error: e);
      throw const UnknownException();
    }
  }

  // ── CheckIn ──────────────────────────────────────────────────────────────
  @override
  Future<int> checkIn({required int spotId}) async {
    try {
      final res = await _dio.post('${ApiConstants.spots}/$spotId/checkin');
      final data = _unwrap(res.data);
      if (data is num) return data.toInt();
      if (data is Map<String, Object?>) {
        final v = data['rewardAmount'] ?? data['points'] ?? data['reward'];
        if (v is num) return v.toInt();
      }
      throw const ServerException();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('checkIn error', error: e);
      throw const UnknownException();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Object? _unwrap(Object? raw) {
    if (raw is Map<String, Object?>) {
      if (raw['success'] == true) return raw['data'];
      final msg = (raw['message'] ?? 'Server error').toString();
      throw ServerException(msg);
    }
    throw const ServerException();
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

final spotServiceProvider = Provider<SpotServiceBase>((ref) {
  return SpotService(ref.watch(dioProvider));
});
