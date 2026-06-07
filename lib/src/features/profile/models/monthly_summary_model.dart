/// Model representing monthly running summary from GET /api/v1/members/me/runs/monthly-summary.
class MonthlySummaryModel {
  const MonthlySummaryModel({
    required this.year,
    required this.month,
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.avgDistanceKm,
    required this.bestDistanceKm,
    required this.avgPaceSecPerKm,
    required this.avgPaceText,
    required this.earnedPoints,
  });

  final int year;
  final int month;
  final int totalRuns;
  final double totalDistanceKm;
  final double avgDistanceKm;
  final double bestDistanceKm;
  final int avgPaceSecPerKm;
  final String avgPaceText;
  final int earnedPoints;

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    // 백엔드는 'avgPace'로 전송 (avgPaceSecPerKm 필드 없음)
    final paceSec = (json['avgPaceSecPerKm'] ?? json['avgPace'] as num? ?? 0).toInt();
    final paceText = json['avgPaceText'] as String? ?? _formatPace(paceSec);
    return MonthlySummaryModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalRuns: json['totalRuns'] as int? ?? 0,
      totalDistanceKm: (json['totalDistanceKm'] as num? ?? 0.0).toDouble(),
      avgDistanceKm: (json['avgDistanceKm'] as num? ?? 0.0).toDouble(),
      bestDistanceKm: (json['bestDistanceKm'] as num? ?? 0.0).toDouble(),
      avgPaceSecPerKm: paceSec,
      avgPaceText: paceText,
      earnedPoints: json['earnedPoints'] as int? ?? 0,
    );
  }

  static String _formatPace(int secPerKm) {
    if (secPerKm <= 0) return "--'--\"";
    final m = secPerKm ~/ 60;
    final s = secPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'totalRuns': totalRuns,
        'totalDistanceKm': totalDistanceKm,
        'avgDistanceKm': avgDistanceKm,
        'bestDistanceKm': bestDistanceKm,
        'avgPaceSecPerKm': avgPaceSecPerKm,
        'avgPaceText': avgPaceText,
        'earnedPoints': earnedPoints,
      };
}
