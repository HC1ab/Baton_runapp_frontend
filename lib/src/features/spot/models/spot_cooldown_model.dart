import 'dart:math';

class SpotCooldownModel {
  const SpotCooldownModel({
    required this.spotId,
    required this.spotName,
    required this.lastCheckinAt,
    required this.cooldownEndsAt,
    required this.rewardAmount,
    required this.expAmount,
  });

  final int spotId;
  final String spotName;
  final DateTime lastCheckinAt;
  final DateTime cooldownEndsAt;
  final int rewardAmount;
  final int expAmount;

  bool get isAvailable => DateTime.now().isAfter(cooldownEndsAt);

  int get totalCooldownSeconds =>
      cooldownEndsAt.difference(lastCheckinAt).inSeconds;

  int get liveRemainingSeconds =>
      max(0, cooldownEndsAt.difference(DateTime.now()).inSeconds);

  /// 0.0 (방금 시작) → 1.0 (완료/가능)
  double get cooldownProgress {
    final total = totalCooldownSeconds;
    if (total <= 0 || isAvailable) return 1.0;
    final remaining = liveRemainingSeconds;
    return ((total - remaining) / total).clamp(0.0, 1.0);
  }

  factory SpotCooldownModel.fromJson(Map<String, dynamic> json) {
    return SpotCooldownModel(
      spotId: (json['spotId'] as num).toInt(),
      spotName: json['spotName'] as String,
      lastCheckinAt: DateTime.parse(json['lastCheckinAt'] as String),
      cooldownEndsAt: DateTime.parse(json['cooldownEndsAt'] as String),
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      expAmount: (json['expAmount'] as num).toInt(),
    );
  }
}
