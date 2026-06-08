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
    this.endTime,
    required this.totalDistanceKm,
    required this.avgPace,
  });

  final int runId;
  final DateTime startTime;

  /// 러닝 종료 시각. 진행 중(미종료) 기록은 null.
  final DateTime? endTime;
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
    // 백엔드는 평균 페이스를 "분 단위 소수"로 전송 (예: 0.97 = 0.97분/km) → 초/km로 환산
    final rawPace =
        (json['avgPaceSecPerKm'] ?? json['avgPace'] as num? ?? 0).toDouble();
    final pace = (rawPace * 60).round();
    final rawEndTime = json['endTime'] as String?;
    return RunListItem(
      runId: (json['runId'] ?? json['id'] as num? ?? 0).toInt(),
      // 서버가 UTC(offset 포함)로 내려줄 수 있으므로 기기 로컬 시간으로 통일해서 표시/정렬
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: rawEndTime == null ? null : DateTime.parse(rawEndTime).toLocal(),
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
        // 종료되지 않은(진행 중) 기록은 거리가 0으로 내려오므로 목록에서 제외
        .where((run) => run.totalDistanceKm > 0)
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
