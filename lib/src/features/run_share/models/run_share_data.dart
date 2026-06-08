import 'package:flutter/foundation.dart';

import '../../profile/models/run_detail_model.dart';
import '../../running/models/run_record_model.dart';

/// 공유 카드에 필요한 런 결과 데이터.
/// RunRecordModel(런 종료 카드) / RunDetailModel(히스토리 상세) 양쪽에서 변환.
@immutable
class RunShareData {
  const RunShareData({
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPaceSecPerKm,
  });

  final double distanceKm;
  final int durationSeconds;

  /// 평균 페이스 (초/km)
  final int avgPaceSecPerKm;

  // ── 포맷 텍스트 ────────────────────────────────────────────────────────────

  String get distanceText => distanceKm.toStringAsFixed(2);

  String get durationText {
    if (durationSeconds <= 0) return '0:00:00';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get paceText {
    if (avgPaceSecPerKm <= 0) return "--'--\"";
    final m = avgPaceSecPerKm ~/ 60;
    final s = avgPaceSecPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  // ── 팩토리 ────────────────────────────────────────────────────────────────

  factory RunShareData.fromRecord(RunRecordModel record) {
    return RunShareData(
      distanceKm: record.distanceMeters / 1000,
      durationSeconds: record.duration.inSeconds,
      avgPaceSecPerKm: record.averagePaceSecondsPerKm.round(),
    );
  }

  factory RunShareData.fromDetail(RunDetailModel detail) {
    return RunShareData(
      distanceKm: detail.totalDistanceKm,
      durationSeconds: detail.totalTimeSeconds,
      avgPaceSecPerKm: detail.avgPaceSecPerKm,
    );
  }
}
