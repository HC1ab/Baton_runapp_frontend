import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/run_path_point_model.dart';

final _logger = Logger();

abstract class RunServiceBase {
  Future<int> startRun({required String startTimeIsoLocal});
  Future<void> finishRun({
    required int runId,
    required String endTimeIsoLocal,
    required List<RunPathPoint> path,
  });
}

class RunService implements RunServiceBase {
  const RunService(this._dio);
  final Dio _dio;

  @override
  Future<int> startRun({required String startTimeIsoLocal}) async {
    try {
      final res = await _dio.post(
        ApiConstants.runStart,
        data: {'startTime': startTimeIsoLocal},
      );
      final data = _unwrap(res.data);
      // 서버 응답: data: {runId: 1, memberId: 1}
      if (data is Map<String, dynamic>) {
        return (data['runId'] as num).toInt();
      }
      return (data as num).toInt();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('startRun error', error: e);
      throw const UnknownException();
    }
  }

  @override
  Future<void> finishRun({
    required int runId,
    required String endTimeIsoLocal,
    required List<RunPathPoint> path,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.runFinish}/$runId/finish',
        data: {
          'endTime': endTimeIsoLocal,
          'path': path.map((p) => p.toJson()).toList(),
        },
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('finishRun error', error: e);
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

final runServiceProvider = Provider<RunServiceBase>((ref) {
  return RunService(ref.watch(dioProvider));
});
