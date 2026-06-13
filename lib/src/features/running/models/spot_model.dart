/// Spot displayed on the map during a run.
/// Immutable — no business logic inside.
class SpotSummary {
  const SpotSummary({
    required this.id,
    required this.name,
    required this.rewardAmount,
    required this.latitude,
    required this.longitude,
    this.canCheckIn = true,
  });

  final int id;
  final String name;
  final int rewardAmount;
  final double latitude;
  final double longitude;
  /// 서버 기준 체크인 가능 여부 (false = 24시간 이내 이미 체크인)
  final bool canCheckIn;

  factory SpotSummary.fromJson(Map<String, Object?> json) {
    return SpotSummary(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      canCheckIn: (json['canCheckIn'] as bool?) ?? true,
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
    this.occupierMemberId,
    this.occupierCheckinCount,
  });

  final int id;
  final String name;
  final String description;
  final int rewardAmount;
  final double latitude;
  final double longitude;
  /// 현재 점령자 memberId (점령자 없으면 null)
  final int? occupierMemberId;
  /// 현재 점령자의 해당 스팟 누적 체크인 수
  final int? occupierCheckinCount;

  factory SpotDetail.fromJson(Map<String, Object?> json) {
    return SpotDetail(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      occupierMemberId: (json['occupierMemberId'] as num?)?.toInt(),
      occupierCheckinCount: (json['occupierCheckinCount'] as num?)?.toInt(),
    );
  }
}
