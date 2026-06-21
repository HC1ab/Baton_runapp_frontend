import 'dart:math';

import '../../running/models/spot_model.dart';
import 'spot_cooldown_model.dart';

/// 스팟 탭 통합 항목 — 체크인 가능한 주변 스팟(nearby)과
/// 내가 이전에 체크인한 스팟(cooldowns)을 하나로 합친 모델.
class SpotListItem {
  const SpotListItem({
    required this.spotId,
    required this.name,
    required this.rewardAmount,
    this.expAmount,
    this.latitude,
    this.longitude,
    this.visited = false,
    this.lastCheckinAt,
    this.cooldownEndsAt,
    this.nearbyCanCheckIn = false,
  });

  final int spotId;
  final String name;
  final int rewardAmount;

  /// EXP 보상 — nearby 응답엔 없어 미방문 스팟은 null일 수 있음.
  final int? expAmount;
  final double? latitude;
  final double? longitude;

  /// 내가 이전에 체크인한 적이 있는 스팟인지 (cooldowns에 존재)
  final bool visited;
  final DateTime? lastCheckinAt;
  final DateTime? cooldownEndsAt;

  /// nearby 응답의 서버 기준 체크인 가능 여부 (미방문 스팟 판정용)
  final bool nearbyCanCheckIn;

  bool get isAvailable {
    final ends = cooldownEndsAt;
    if (ends != null) return DateTime.now().isAfter(ends);
    return nearbyCanCheckIn;
  }

  int get totalCooldownSeconds {
    final ends = cooldownEndsAt;
    final last = lastCheckinAt;
    if (ends == null || last == null) return 0;
    return ends.difference(last).inSeconds;
  }

  int get liveRemainingSeconds {
    final ends = cooldownEndsAt;
    if (ends == null) return 0;
    return max(0, ends.difference(DateTime.now()).inSeconds);
  }

  /// 0.0 (방금 시작) → 1.0 (완료/가능)
  double get cooldownProgress {
    final total = totalCooldownSeconds;
    if (total <= 0 || isAvailable) return 1.0;
    return ((total - liveRemainingSeconds) / total).clamp(0.0, 1.0);
  }

  factory SpotListItem.fromCooldown(SpotCooldownModel c) => SpotListItem(
        spotId: c.spotId,
        name: c.spotName,
        rewardAmount: c.rewardAmount,
        expAmount: c.expAmount,
        visited: true,
        lastCheckinAt: c.lastCheckinAt,
        cooldownEndsAt: c.cooldownEndsAt,
      );

  factory SpotListItem.fromNearby(SpotSummary s) => SpotListItem(
        spotId: s.id,
        name: s.name,
        rewardAmount: s.rewardAmount,
        latitude: s.latitude,
        longitude: s.longitude,
        nearbyCanCheckIn: s.canCheckIn,
      );

  /// 이미 방문 기록이 있는 항목에 nearby 정보(좌표/보상/체크인 가능)를 덧입힘.
  SpotListItem withNearby(SpotSummary s) => SpotListItem(
        spotId: spotId,
        name: name.isNotEmpty ? name : s.name,
        rewardAmount: s.rewardAmount,
        expAmount: expAmount,
        latitude: s.latitude,
        longitude: s.longitude,
        visited: visited,
        lastCheckinAt: lastCheckinAt,
        cooldownEndsAt: cooldownEndsAt,
        nearbyCanCheckIn: s.canCheckIn,
      );
}
