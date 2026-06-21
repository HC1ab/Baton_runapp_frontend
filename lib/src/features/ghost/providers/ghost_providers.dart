import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/dio_client.dart';
import '../data/ghost_api.dart';
import '../models/ghost_ranking.dart';

export '../models/ghost_ranking.dart';

/// 고스트 랭킹 거리 부문 (백엔드 enum: 1K/3K/5K/10K)
const ghostCategories = ['1K', '3K', '5K', '10K'];

final ghostApiProvider = Provider<GhostApi>((ref) {
  return GhostApi(ref.watch(dioProvider));
});

/// 부문(category)별 동네 랭킹 — 현재 위치 기준.
final ghostRankingProvider =
    FutureProvider.autoDispose.family<GhostRanking, String>((ref, category) async {
  final (lat, lng) = await currentLatLng();
  return ref.watch(ghostApiProvider).getRankings(
        lat: lat,
        lng: lng,
        category: category,
      );
});

/// 고스트 기록 상세 (코스 path 포함) — rankingId 기준.
final ghostRankingDetailProvider =
    FutureProvider.autoDispose.family<GhostRankingDetail, int>((ref, rankingId) {
  return ref.watch(ghostApiProvider).getRankingDetail(rankingId);
});

/// 현재 위치 — 캐시 우선, 실패 시 부산 일대 기본 좌표.
Future<(double, double)> currentLatLng() async {
  try {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return (35.2475, 129.0914);
    }
    Position? pos = await Geolocator.getLastKnownPosition();
    pos ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 3),
      ),
    );
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return (35.2475, 129.0914);
  }
}
