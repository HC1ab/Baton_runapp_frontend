// 고스트 모드 모델 — 백엔드 Swagger 초안 기준.
//
// 랭킹:  GET /api/v1/ghost-rankings?lat=&lng=&category={1K|3K|5K|10K}
// 상세:  GET /api/v1/ghost-rankings/{rankingId}   (지도에 코스 path 그릴 때)
// 시작:  POST /api/v1/ghost-runs/start
// 종료:  POST /api/v1/ghost-runs/{runId}/finish

/// 분 단위 소수 페이스(예: 4.52 = 4.52분/km) → "M'SS\""
String formatPace(double avgPace) {
  if (avgPace <= 0) return "0'00\"";
  final totalSec = (avgPace * 60).round();
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  return "$m'${s.toString().padLeft(2, '0')}\"";
}

/// 랭킹 한 줄 (TOP3 항목)
class GhostRankingEntry {
  const GhostRankingEntry({
    required this.rankingId,
    required this.recordId,
    required this.rankNo,
    required this.nickname,
    required this.avgPace,
    required this.distanceKm,
    required this.startLat,
    required this.startLng,
  });

  final int rankingId;
  final int recordId;
  final int rankNo;
  final String nickname;
  final double avgPace;
  final double distanceKm;
  final double startLat;
  final double startLng;

  String get paceText => formatPace(avgPace);

  factory GhostRankingEntry.fromJson(Map<String, dynamic> json) {
    return GhostRankingEntry(
      rankingId: (json['rankingId'] as num? ?? 0).toInt(),
      recordId: (json['recordId'] as num? ?? 0).toInt(),
      rankNo: (json['rankNo'] as num? ?? 0).toInt(),
      nickname: (json['nickname'] ?? '') as String,
      avgPace: (json['avgPace'] as num? ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      startLat: (json['startLat'] as num? ?? 0).toDouble(),
      startLng: (json['startLng'] as num? ?? 0).toDouble(),
    );
  }
}

/// 한 동네의 한 부문 랭킹 묶음 (GET /api/v1/ghost-rankings 응답)
class GhostRanking {
  const GhostRanking({
    required this.dong,
    required this.category,
    required this.entries,
  });

  final String dong;
  final String category;
  final List<GhostRankingEntry> entries;

  factory GhostRanking.fromJson(Map<String, dynamic> json) {
    final list = (json['rankings'] ?? json['entries']) as List<dynamic>?;
    final entries = (list ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GhostRankingEntry.fromJson)
        .toList()
      ..sort((a, b) => a.rankNo.compareTo(b.rankNo));
    return GhostRanking(
      dong: (json['dong'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      entries: entries,
    );
  }
}

/// 경로 좌표 한 점
class GhostPathPoint {
  const GhostPathPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  factory GhostPathPoint.fromJson(Map<String, dynamic> json) =>
      GhostPathPoint(
        (json['lat'] as num? ?? 0).toDouble(),
        (json['lng'] as num? ?? 0).toDouble(),
      );
}

/// 고스트 기록 상세 (GET /api/v1/ghost-rankings/{rankingId}) — 코스 path 포함
class GhostRankingDetail {
  const GhostRankingDetail({
    required this.rankingId,
    required this.recordId,
    required this.rankNo,
    required this.nickname,
    required this.dong,
    required this.category,
    required this.avgPace,
    required this.distanceKm,
    required this.startLat,
    required this.startLng,
    required this.path,
  });

  final int rankingId;
  final int recordId;
  final int rankNo;
  final String nickname;
  final String dong;
  final String category;
  final double avgPace;
  final double distanceKm;
  final double startLat;
  final double startLng;
  final List<GhostPathPoint> path;

  String get paceText => formatPace(avgPace);

  factory GhostRankingDetail.fromJson(Map<String, dynamic> json) {
    final rawPath = (json['path'] as List<dynamic>?) ?? const [];
    return GhostRankingDetail(
      rankingId: (json['rankingId'] as num? ?? 0).toInt(),
      recordId: (json['recordId'] as num? ?? 0).toInt(),
      rankNo: (json['rankNo'] as num? ?? 0).toInt(),
      nickname: (json['nickname'] ?? '') as String,
      dong: (json['dong'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      avgPace: (json['avgPace'] as num? ?? 0).toDouble(),
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      startLat: (json['startLat'] as num? ?? 0).toDouble(),
      startLng: (json['startLng'] as num? ?? 0).toDouble(),
      path: rawPath
          .whereType<Map<String, dynamic>>()
          .map(GhostPathPoint.fromJson)
          .toList(),
    );
  }
}

/// 고스트런 시작 결과 (POST /api/v1/ghost-runs/start)
class GhostRunStart {
  const GhostRunStart({
    required this.runId,
    required this.ghostRankingId,
    required this.targetRecordId,
    required this.targetNickname,
    required this.targetAvgPace,
  });

  final int runId;
  final int ghostRankingId;
  final int targetRecordId;
  final String targetNickname;
  final double targetAvgPace;

  factory GhostRunStart.fromJson(Map<String, dynamic> json) {
    return GhostRunStart(
      runId: (json['runId'] as num? ?? 0).toInt(),
      ghostRankingId: (json['ghostRankingId'] as num? ?? 0).toInt(),
      targetRecordId: (json['targetRecordId'] as num? ?? 0).toInt(),
      targetNickname: (json['targetNickname'] ?? '') as String,
      targetAvgPace: (json['targetAvgPace'] as num? ?? 0).toDouble(),
    );
  }
}

enum GhostRunResultType { win, lose, unknown }

/// 고스트런 종료 결과 (POST /api/v1/ghost-runs/{runId}/finish)
class GhostRunResult {
  const GhostRunResult({
    required this.runId,
    required this.result,
    required this.myAvgPace,
    required this.targetAvgPace,
    required this.paceDiff,
    required this.rankingUpdated,
  });

  final int runId;
  final GhostRunResultType result;
  final double myAvgPace;
  final double targetAvgPace;
  final double paceDiff;
  final bool rankingUpdated;

  bool get isWin => result == GhostRunResultType.win;

  factory GhostRunResult.fromJson(Map<String, dynamic> json) {
    return GhostRunResult(
      runId: (json['runId'] as num? ?? 0).toInt(),
      result: switch ((json['result'] ?? '').toString().toUpperCase()) {
        'WIN' => GhostRunResultType.win,
        'LOSE' => GhostRunResultType.lose,
        _ => GhostRunResultType.unknown,
      },
      myAvgPace: (json['myAvgPace'] as num? ?? 0).toDouble(),
      targetAvgPace: (json['targetAvgPace'] as num? ?? 0).toDouble(),
      paceDiff: (json['paceDiff'] as num? ?? 0).toDouble(),
      rankingUpdated: (json['rankingUpdated'] as bool?) ?? false,
    );
  }
}
