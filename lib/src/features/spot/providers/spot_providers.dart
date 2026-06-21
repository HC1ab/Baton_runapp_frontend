import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/dio_client.dart';
import '../../running/models/spot_model.dart';
import '../../running/services/spot_service.dart';
import '../data/spot_api.dart';
import '../models/spot_cooldown_model.dart';
import '../models/spot_list_item.dart';

export '../../running/models/spot_model.dart' show SpotDetail;
export '../models/spot_cooldown_model.dart' show SpotCooldownModel;
export '../models/spot_list_item.dart' show SpotListItem;

final spotApiProvider = Provider<SpotApi>((ref) {
  return SpotApi(ref.watch(dioProvider));
});

/// autoDispose: 탭 이탈 시 자동 해제 → 재진입 시 재조회 (런 후 최신 체크인 반영).
final spotCooldownsProvider =
    FutureProvider.autoDispose<List<SpotCooldownModel>>((ref) {
  return ref.watch(spotApiProvider).getCooldowns();
});

/// 스팟 탭 목록 — 체크인 가능한 주변 스팟(nearby) + 내가 체크인했던 스팟(cooldowns)을 병합.
final spotListProvider =
    FutureProvider.autoDispose<List<SpotListItem>>((ref) async {
  final service = ref.watch(spotServiceProvider);
  final api = ref.watch(spotApiProvider);

  // cooldowns(방문 기록)는 위치가 필요 없으므로 위치 측정과 병렬로 즉시 시작.
  final cooldownsFuture = api.getCooldowns().then<List<SpotCooldownModel>>(
        (v) => v,
        onError: (_) => const <SpotCooldownModel>[],
      );

  // 현재 위치 (권한 거부 → 예외 / 측정 실패 → 기본 좌표 폴백)
  final (lat, lng) = await _currentLatLng();

  // nearby는 위치가 필요 → 위치 확보 후 시작, cooldowns와 함께 대기 (best-effort)
  final nearbyFuture =
      service.nearby(latitude: lat, longitude: lng).then<List<SpotSummary>>(
            (v) => v,
            onError: (_) => const <SpotSummary>[],
          );

  final results = await Future.wait([nearbyFuture, cooldownsFuture]);
  final nearby = results[0] as List<SpotSummary>;
  final cooldowns = results[1] as List<SpotCooldownModel>;

  final byId = <int, SpotListItem>{};
  // ① 내가 체크인했던 스팟 (쿨타임 정보 포함)
  for (final c in cooldowns) {
    byId[c.spotId] = SpotListItem.fromCooldown(c);
  }
  // ② 체크인 가능한 주변 스팟 — 미방문 & 체크인 불가 스팟은 제외
  for (final s in nearby) {
    final existing = byId[s.id];
    if (existing != null) {
      byId[s.id] = existing.withNearby(s); // 방문 기록 + 위치/체크인 가능 병합
    } else if (s.canCheckIn) {
      byId[s.id] = SpotListItem.fromNearby(s);
    }
  }

  final list = byId.values.toList()
    ..sort((a, b) {
      // 체크인 가능한 스팟 먼저, 그다음 최근 방문 순, 마지막으로 이름순
      if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
      final at = a.lastCheckinAt, bt = b.lastCheckinAt;
      if (at != null && bt != null) return bt.compareTo(at);
      if (at != null) return -1;
      if (bt != null) return 1;
      return a.name.compareTo(b.name);
    });
  return list;
});

/// 위치 권한이 없을 때 던지는 예외 — 스팟 화면에서 "권한 켜주세요" 안내 분기용.
class LocationPermissionException implements Exception {
  const LocationPermissionException();
}

/// 현재 위치 조회.
/// - 권한 거부/영구거부: [LocationPermissionException] 던짐 → 화면에서 안내 표시
/// - 권한은 있으나 측정 실패(타임아웃 등): 부산 일대 기본 좌표로 폴백
Future<(double, double)> _currentLatLng() async {
  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    throw const LocationPermissionException();
  }

  try {
    // 캐시된 위치 우선 (즉시) — 목록 화면엔 약간 오래된 좌표도 충분
    Position? pos = await Geolocator.getLastKnownPosition();
    // 캐시가 없을 때만 실시간 측정 (타임아웃 짧게 → 느린 GPS에서 빨리 폴백)
    pos ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 3),
      ),
    );
    return (pos.latitude, pos.longitude);
  } catch (_) {
    // 권한은 있는데 측정만 실패 → 기본 좌표
    return (35.2475, 129.0914);
  }
}

/// 스팟 상세 + 현재 점령자 정보 (GET /api/v1/spots/{spotId})
final spotDetailProvider =
    FutureProvider.autoDispose.family<SpotDetail, int>((ref, spotId) {
  return ref.watch(spotServiceProvider).detail(spotId);
});
