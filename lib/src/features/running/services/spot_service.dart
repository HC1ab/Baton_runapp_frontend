import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/spot_model.dart';

final _logger = Logger();

abstract class SpotServiceBase {
  /// POST /api/v1/spots/nearby
  Future<List<SpotSummary>> nearby({
    required double latitude,
    required double longitude,
  });

  /// GET /api/v1/spots/{spotId}
  Future<SpotDetail> detail(int spotId);

  /// POST /api/v1/spots/{spotId}/checkin
  Future<CheckInResult> checkIn({
    required int spotId,
    required int runId,
    required double latitude,
    required double longitude,
    required String timestamp,
  });
}

/// 체크인 성공 결과 모델
class CheckInResult {
  const CheckInResult({
    required this.spotName,
    required this.earnedPoints,
    required this.currentTotalPoints,
    required this.visitLogId,
    this.earnedExp = 0,
    this.isLevelUp = false,
    this.currentLevel = 0,
    this.totalExp = 0,
    this.occupationChanged = false,
    this.occupationType,
    this.occupationBonusPoints = 0,
    this.occupierMemberId,
    this.occupierCheckinCount,
    this.isAlreadyCheckedIn = false,
  });

  final String spotName;
  final int earnedPoints;
  final int currentTotalPoints;
  final String visitLogId;
  final int earnedExp;
  final bool isLevelUp;
  final int currentLevel;
  final int totalExp;

  /// 이번 체크인으로 점령/탈환이 발생했는지
  final bool occupationChanged;
  /// "SPOT_OCCUPY"(첫 점령) | "SPOT_STEAL"(탈환) | null(변화 없음)
  final String? occupationType;
  /// 점령/탈환 보너스 포인트 (첫 점령 50, 탈환 100, 변화 없으면 0)
  final int occupationBonusPoints;
  /// 현재 점령자 memberId
  final int? occupierMemberId;
  /// 현재 점령자의 해당 스팟 누적 체크인 수
  final int? occupierCheckinCount;

  final bool isAlreadyCheckedIn;

  /// 이미 체크인한 스팟 알림용 팩토리
  factory CheckInResult.alreadyCheckedIn(String spotName) => CheckInResult(
        spotName: spotName,
        earnedPoints: 0,
        currentTotalPoints: 0,
        visitLogId: '',
        isAlreadyCheckedIn: true,
      );
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
      // GET /api/v1/spots/nearby?latitude=...&longitude=...
      // [iOS 대응] iOS에서 동일하게 동작 확인 필요
      final res = await _dio.get(
        ApiConstants.spotsNearby,
        queryParameters: {'latitude': latitude, 'longitude': longitude},
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
  Future<CheckInResult> checkIn({
    required int spotId,
    required int runId,
    required double latitude,
    required double longitude,
    required String timestamp,
  }) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.spots}/$spotId/checkin',
        data: {
          'runId': runId,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': timestamp,
        },
      );
      final data = _unwrap(res.data);
      if (data is! Map<String, Object?>) throw const ServerException();
      return CheckInResult(
        spotName: data['spotName']?.toString() ?? '',
        earnedPoints: (data['earnedPoints'] as num?)?.toInt() ?? 0,
        currentTotalPoints: (data['currentTotalPoints'] as num?)?.toInt() ?? 0,
        visitLogId: data['visitLogId']?.toString() ?? '',
        earnedExp: (data['earnedExp'] as num?)?.toInt() ?? 0,
        isLevelUp: (data['isLevelUp'] as bool?) ?? false,
        currentLevel: (data['currentLevel'] as num?)?.toInt() ?? 0,
        totalExp: (data['totalExp'] as num?)?.toInt() ?? 0,
        occupationChanged: (data['occupationChanged'] as bool?) ?? false,
        occupationType: data['occupationType']?.toString(),
        occupationBonusPoints: (data['occupationBonusPoints'] as num?)?.toInt() ?? 0,
        occupierMemberId: (data['occupierMemberId'] as num?)?.toInt(),
        occupierCheckinCount: (data['occupierCheckinCount'] as num?)?.toInt(),
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      // 에러 코드별 메시지 처리
      final data = e.response?.data;
      if (data is Map<String, Object?>) {
        final code = data['code']?.toString();
        final msg = data['message']?.toString() ?? '';
        switch (code) {
          case 'C001': throw ServerException(ErrorMessages.spotRunNotFound);
          case 'C002': throw ServerException(ErrorMessages.spotRunNotOwned);
          case 'C003': throw ServerException(ErrorMessages.spotAlreadyCheckedIn);
          case 'C004': throw ServerException(ErrorMessages.spotOutOfRange);
          case 'C005': throw ServerException(ErrorMessages.runningOnly);
          case 'S004': throw ServerException(ErrorMessages.spotNotFound);
          default: if (msg.isNotEmpty) throw ServerException(msg);
        }
      }
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
