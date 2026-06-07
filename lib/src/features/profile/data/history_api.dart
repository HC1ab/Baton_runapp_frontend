import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/monthly_summary_model.dart';
import '../models/run_detail_model.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class RunListItem {
  const RunListItem({
    required this.runId,
    required this.startTime,
    required this.totalDistanceKm,
    required this.avgPace,
  });

  final int runId;
  final DateTime startTime;
  final double totalDistanceKm;

  /// 평균 페이스 (초/km). avgPace * totalDistanceKm = 총 소요 시간(초).
  final int avgPace;

  /// "M'SS\"" 형식 페이스 텍스트 (예: "6'00\""), pace 없으면 "--'--\""
  String get avgPaceText {
    if (avgPace <= 0) return "--'--\"";
    final m = avgPace ~/ 60;
    final s = avgPace % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  /// 총 소요 시간 (초)
  int get durationSeconds => (avgPace * totalDistanceKm).round();

  factory RunListItem.fromJson(Map<String, dynamic> json) {
    final pace = (json['avgPaceSecPerKm'] ?? json['avgPace'] as num? ?? 0).toInt();
    return RunListItem(
      runId: (json['runId'] ?? json['id'] as num? ?? 0).toInt(),
      startTime: DateTime.parse(json['startTime'] as String),
      totalDistanceKm: (json['totalDistanceKm'] as num? ?? 0.0).toDouble(),
      avgPace: pace,
    );
  }
}

// ---------------------------------------------------------------------------
// API
// ---------------------------------------------------------------------------

class HistoryApi {
  const HistoryApi(this._dio);
  final Dio _dio;

  /// GET /api/v1/members/me/runs/monthly-summary
  Future<MonthlySummaryModel> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/api/v1/members/me/runs/monthly-summary',
      queryParameters: {'year': year, 'month': month},
    );
    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! Map<String, dynamic>) {
      throw ApiException('월별 요약 데이터 응답이 올바르지 않습니다.');
    }
    return MonthlySummaryModel.fromJson(unwrapped);
  }

  /// GET /api/v1/members/me/runs — 내 전체 러닝 목록.
  /// 클라이언트에서 연/월 필터링 적용.
  Future<List<RunListItem>> getMyRuns() async {
    final response = await _dio.get('/api/v1/members/me/runs');
    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! List<dynamic>) {
      throw ApiException('러닝 목록 응답이 올바르지 않습니다.');
    }
    return unwrapped
        .map((e) => RunListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/runs/{runId} — 러닝 상세 조회 (경로 포함)
  Future<RunDetailModel> getRunDetail(int runId) async {
    final response = await _dio.get('${ApiConstants.runs}/$runId');
    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! Map<String, dynamic>) {
      throw ApiException('러닝 상세 응답이 올바르지 않습니다.');
    }
    return RunDetailModel.fromJson(unwrapped);
  }
}
