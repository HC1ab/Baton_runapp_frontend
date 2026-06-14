import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/occupation_api.dart';
import '../models/occupied_spot_model.dart';

export '../models/occupied_spot_model.dart' show OccupiedSpot;

/// 점령 지도 토글 모드.
enum OccupationMode {
  /// BATON — 모든 사용자의 점령 스팟
  all,

  /// 내 점령 — 내가 점령한 스팟
  mine,
}

final occupationApiProvider = Provider<OccupationApi>((ref) {
  return OccupationApi(ref.watch(dioProvider));
});

/// 현재 선택된 점령 토글 (BATON / 내 점령)
class _OccupationModeNotifier extends Notifier<OccupationMode> {
  @override
  OccupationMode build() => OccupationMode.all;

  void set(OccupationMode mode) => state = mode;
}

final occupationModeProvider =
    NotifierProvider<_OccupationModeNotifier, OccupationMode>(
  _OccupationModeNotifier.new,
);

/// 모든 사용자의 점령 스팟
final allOccupiedSpotsProvider =
    FutureProvider.autoDispose<List<OccupiedSpot>>((ref) {
  return ref.watch(occupationApiProvider).getAllOccupied();
});

/// 내가 점령한 스팟
final myOccupiedSpotsProvider =
    FutureProvider.autoDispose<List<OccupiedSpot>>((ref) {
  return ref.watch(occupationApiProvider).getMyOccupied();
});

/// 현재 토글에 맞는 점령 스팟 목록
final occupiedSpotsProvider =
    FutureProvider.autoDispose<List<OccupiedSpot>>((ref) {
  final mode = ref.watch(occupationModeProvider);
  return switch (mode) {
    OccupationMode.all => ref.watch(allOccupiedSpotsProvider.future),
    OccupationMode.mine => ref.watch(myOccupiedSpotsProvider.future),
  };
});
