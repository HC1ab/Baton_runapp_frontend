import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/spot_model.dart';

final _logger = Logger();

abstract class SpotServiceBase {
  Future<List<SpotSummary>> nearby({
    required double latitude,
    required double longitude,
  });

  Future<SpotDetail> detail(int spotId);

  Future<int> checkIn({required int spotId});
}

class SpotService implements SpotServiceBase {
  const SpotService(this._dio);
  final Dio _dio;

  @override
  Future<List<SpotSummary>> nearby({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.spotsNearby,
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      final data = _unwrap(res.data);
      if (data is! List) {
        throw const ServerException();
      }
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

  @override
  Future<SpotDetail> detail(int spotId) async {
    try {
      final res = await _dio.get('${ApiConstants.spots}/$spotId');
      final data = _unwrap(res.data);
      if (data is! Map<String, Object?>) {
        throw const ServerException();
      }
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

  @override
  Future<int> checkIn({required int spotId}) async {
    try {
      final res = await _dio.post('${ApiConstants.spots}/$spotId/checkin');
      final data = _unwrap(res.data);
      if (data is num) {
        return data.toInt();
      }
      if (data is Map<String, Object?>) {
        final v = data['points'] ?? data['rewardAmount'] ?? data['reward'];
        if (v is num) {
          return v.toInt();
        }
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

  Object? _unwrap(Object? raw) {
    if (raw is Map<String, Object?>) {
      if (raw['success'] == true) {
        return raw['data'];
      }
      final msg = (raw['message'] ?? 'Server error').toString();
      throw ServerException(msg);
    }
    throw const ServerException();
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      return const AuthException();
    }
    if (status != null && status >= 500) {
      return const ServerException();
    }
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
