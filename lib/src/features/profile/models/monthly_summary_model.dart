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
    return MonthlySummaryModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalRuns: json['totalRuns'] as int? ?? 0,
      totalDistanceKm: (json['totalDistanceKm'] as num? ?? 0.0).toDouble(),
      avgDistanceKm: (json['avgDistanceKm'] as num? ?? 0.0).toDouble(),
      bestDistanceKm: (json['bestDistanceKm'] as num? ?? 0.0).toDouble(),
      avgPaceSecPerKm: json['avgPaceSecPerKm'] as int? ?? 0,
      avgPaceText: json['avgPaceText'] as String? ?? '00:00',
      earnedPoints: json['earnedPoints'] as int? ?? 0,
    );
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
