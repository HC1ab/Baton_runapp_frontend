import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../running/models/spot_model.dart';
import '../running/services/spot_service.dart';

/// Mock implementation of SpotServiceBase.
/// Generates spots within 200m of the given position deterministically.
class MockSpotService implements SpotServiceBase {
  const MockSpotService();

  static const _count = 10;
  static const _radiusMeters = 200.0;

  @override
  Future<List<SpotSummary>> nearby({
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Deterministic seed so spots stay stable for same position
    final rand = math.Random(
      (latitude * 1e6).round() ^ (longitude * 1e6).round(),
    );

    final mLat = 111320.0;
    final mLng = 111320.0 * math.cos(latitude * math.pi / 180.0).abs();

    final spots = <SpotSummary>[];
    for (var i = 0; i < _count; i++) {
      // Uniform distribution inside circle: r = sqrt(u) * R
      final r = math.sqrt(rand.nextDouble()) * _radiusMeters;
      final theta = rand.nextDouble() * 2 * math.pi;

      final dLat = (r * math.sin(theta)) / mLat;
      final dLng = (r * math.cos(theta)) / (mLng == 0 ? 1 : mLng);

      spots.add(SpotSummary(
        id: i + 1,
        name: 'Spot ${i + 1}',
        rewardAmount: 50 + (i * 10),
        latitude: latitude + dLat,
        longitude: longitude + dLng,
      ));
    }
    return spots;
  }

  @override
  Future<SpotDetail> detail(int spotId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final reward = 50 + ((spotId - 1).clamp(0, 9) * 10);
    return SpotDetail(
      id: spotId,
      name: 'Spot $spotId',
      description: '체크인 테스트용 스팟입니다. (반경 200m 내 자동 생성)',
      rewardAmount: reward,
      latitude: 0,
      longitude: 0,
    );
  }

  @override
  Future<int> checkIn({required int spotId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return 50 + ((spotId - 1).clamp(0, 9) * 10);
  }
}

final mockSpotServiceProvider = Provider<SpotServiceBase>((ref) {
  return const MockSpotService();
});
