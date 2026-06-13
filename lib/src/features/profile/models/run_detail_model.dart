class PathPoint {
  const PathPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;

  factory PathPoint.fromJson(Map<String, dynamic> json) => PathPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

class RunDetailModel {
  const RunDetailModel({
    required this.runId,
    required this.totalDistanceKm,
    required this.totalTimeSeconds,
    required this.avgPaceSecPerKm,
    required this.path,
    this.startedAt,
  });

  final int runId;
  final double totalDistanceKm;
  final int totalTimeSeconds;

  /// 평균 페이스 (초/km)
  final int avgPaceSecPerKm;
  final List<PathPoint> path;

  /// 러닝 시작 시각 (로컬 시간)
  final DateTime? startedAt;

  String get avgPaceText {
    if (avgPaceSecPerKm <= 0) return "--'--\"";
    final m = avgPaceSecPerKm ~/ 60;
    final s = avgPaceSecPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  String get totalTimeText {
    if (totalTimeSeconds <= 0) return '0:00:00';
    final h = totalTimeSeconds ~/ 3600;
    final m = (totalTimeSeconds % 3600) ~/ 60;
    final s = totalTimeSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory RunDetailModel.fromJson(Map<String, dynamic> json) {
    // 백엔드는 평균 페이스를 "분 단위 소수"로 전송 (예: 0.97 = 0.97분/km) → 초/km로 환산
    final rawPace = (json['avgPace'] as num? ?? 0).toDouble();
    final rawStart = json['startTime'] as String?;
    return RunDetailModel(
      runId: (json['runId'] as num? ?? 0).toInt(),
      totalDistanceKm: (json['totalDistanceKm'] as num? ?? 0.0).toDouble(),
      totalTimeSeconds: (json['totalTimeSeconds'] as num? ?? 0).toInt(),
      avgPaceSecPerKm: (rawPace * 60).round(),
      path: (json['path'] as List<dynamic>? ?? [])
          .map((e) => PathPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      startedAt: rawStart == null ? null : DateTime.parse(rawStart).toLocal(),
    );
  }
}
