import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../profile/models/run_detail_model.dart';
import '../../running/models/run_record_model.dart';

/// GPS 좌표 한 점 (공유 카드 루트 페인터용).
@immutable
class SharePathPoint {
  const SharePathPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// 공유 카드에 필요한 런 결과 데이터.
/// RunRecordModel(런 종료 카드) / RunDetailModel(히스토리 상세) 양쪽에서 변환.
@immutable
class RunShareData {
  const RunShareData({
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPaceSecPerKm,
    this.path = const [],
    this.mapSnapshot,
  });

  final double distanceKm;
  final int durationSeconds;

  /// 평균 페이스 (초/km)
  final int avgPaceSecPerKm;

  /// GPS 경로 — NRC 카드 루트 페인터에 사용.
  final List<SharePathPoint> path;

  /// 러닝 상세 지도 스냅샷 — NRC 카드 배경에 사용. 없으면 다크 단색.
  final Uint8List? mapSnapshot;

  // ── 포맷 텍스트 ────────────────────────────────────────────────────────────

  String get distanceText => distanceKm.toStringAsFixed(2);

  // NRC 카드용 — 소수점 1자리
  String get distanceShortText => distanceKm.toStringAsFixed(1);

  String get durationText {
    if (durationSeconds <= 0) return '0:00:00';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // NRC 카드용 — 1시간 미만이면 mm:ss
  String get durationShortText {
    if (durationSeconds <= 0) return '0:00';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
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
      path: record.path
          .map((p) => SharePathPoint(p.lat, p.lng))
          .toList(),
    );
  }

  factory RunShareData.fromDetail(RunDetailModel detail, {Uint8List? mapSnapshot}) {
    return RunShareData(
      distanceKm: detail.totalDistanceKm,
      durationSeconds: detail.totalTimeSeconds,
      avgPaceSecPerKm: detail.avgPaceSecPerKm,
      path: detail.path
          .map((p) => SharePathPoint(p.lat, p.lng))
          .toList(),
      mapSnapshot: mapSnapshot,
    );
  }
}
