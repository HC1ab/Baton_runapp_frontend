/// Spot displayed on the map during a run.
/// Immutable — no business logic inside.
class SpotSummary {
  const SpotSummary({
    required this.id,
    required this.name,
    required this.rewardAmount,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final int rewardAmount;
  final double latitude;
  final double longitude;

  factory SpotSummary.fromJson(Map<String, Object?> json) {
    return SpotSummary(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

/// Full spot detail (shown on spot detail sheet).
class SpotDetail {
  const SpotDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.rewardAmount,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String description;
  final int rewardAmount;
  final double latitude;
  final double longitude;

  factory SpotDetail.fromJson(Map<String, Object?> json) {
    return SpotDetail(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
