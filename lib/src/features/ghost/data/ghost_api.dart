import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/ghost_ranking.dart';

final _logger = Logger();

/// 고스트 모드 데이터 소스 (백엔드 Swagger 초안 기준).
class GhostApi {
  const GhostApi(this._dio);
  final Dio _dio;

  /// GET /api/v1/ghost-rankings?lat=&lng=&category=
  /// 서버가 lat/lng를 역지오코딩해 동(dong)을 구하고 부문별 TOP3 반환.
  Future<GhostRanking> getRankings({
    required double lat,
    required double lng,
    required String category,
  }) async {
    try {
      _logger.i('ghost rankings 요청 좌표: lat=$lat, lng=$lng, category=$category');
      final res = await _dio.get(
        ApiConstants.ghostRankings,
        queryParameters: {'lat': lat, 'lng': lng, 'category': category},
      );
      final data = unwrapApiResponse(res.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return GhostRanking.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      // 실제 와이어로 전송된 URI (쿼리스트링 포함) — 파라미터 부착 증명용
      _logger.w('ghost rankings 실패 — 실제 전송 URI: ${e.requestOptions.uri} '
          '(status=${e.response?.statusCode})');
      throw _dioError(e); // 서버 메시지(예: 주소 변환 실패) 우선 노출
    } catch (e) {
      _logger.e('ghost rankings error category=$category', error: e);
      throw const UnknownException();
    }
  }

  /// GET /api/v1/ghost-rankings/{rankingId} — 코스 path 포함 상세
  Future<GhostRankingDetail> getRankingDetail(int rankingId) async {
    try {
      final res = await _dio.get(ApiConstants.ghostRankingDetail(rankingId));
      final data = unwrapApiResponse(res.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return GhostRankingDetail.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _dioError(e);
    } catch (e) {
      _logger.e('ghost ranking detail error id=$rankingId', error: e);
      throw const UnknownException();
    }
  }

  /// POST /api/v1/ghost-runs/start — 시작점 10m 이내 검증은 서버가 수행.
  /// 실패 시 서버 메시지를 [ServerException]으로 전달.
  Future<GhostRunStart> startRun({
    required int ghostRankingId,
    required double currentLat,
    required double currentLng,
    required String startTime,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.ghostRunStart,
        data: {
          'ghostRankingId': ghostRankingId,
          'currentLat': currentLat,
          'currentLng': currentLng,
          'startTime': startTime,
        },
      );
      final data = unwrapApiResponse(res.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return GhostRunStart.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      // 서버가 내려준 실패 메시지(예: 10m 이내) 우선 노출
      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['message'] != null) {
        throw ServerException(body['message'].toString());
      }
      throw _mapDio(e);
    } catch (e) {
      _logger.e('ghost run start error rankingId=$ghostRankingId', error: e);
      throw const UnknownException();
    }
  }

  /// POST /api/v1/ghost-runs/{runId}/finish — 내 경로/시각 전송 → 승패·랭킹갱신 결과.
  Future<GhostRunResult> finishRun({
    required int runId,
    required int ghostRankingId,
    required String endTime,
    required String realStartTime,
    required List<GhostPathPoint> path,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.ghostRunFinish(runId),
        data: {
          'ghostRankingId': ghostRankingId,
          'endTime': endTime,
          'realStartTime': realStartTime,
          'path': [
            for (final p in path) {'lat': p.lat, 'lng': p.lng},
          ],
        },
      );
      final data = unwrapApiResponse(res.data);
      if (data is! Map<String, dynamic>) {
        throw const ServerException(ErrorMessages.invalidResponse);
      }
      return GhostRunResult.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } catch (e) {
      _logger.e('ghost run finish error runId=$runId', error: e);
      throw const UnknownException();
    }
  }

  /// 서버가 내려준 실패 메시지(예: "주소 변환에 실패했습니다.")가 있으면 그대로 노출,
  /// 없으면 일반 매핑.
  AppException _dioError(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['message'] != null) {
      final msg = body['message'].toString().trim();
      if (msg.isNotEmpty) return ServerException(msg);
    }
    return _mapDio(e);
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
