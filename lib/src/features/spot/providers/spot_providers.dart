import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../running/models/spot_model.dart';
import '../../running/services/spot_service.dart';
import '../data/spot_api.dart';
import '../models/spot_cooldown_model.dart';

export '../../running/models/spot_model.dart' show SpotDetail;
export '../models/spot_cooldown_model.dart' show SpotCooldownModel;

final spotApiProvider = Provider<SpotApi>((ref) {
  return SpotApi(ref.watch(dioProvider));
});

/// autoDispose: 탭 이탈 시 자동 해제 → 재진입 시 재조회 (런 후 최신 체크인 반영).
final spotCooldownsProvider =
    FutureProvider.autoDispose<List<SpotCooldownModel>>((ref) {
  return ref.watch(spotApiProvider).getCooldowns();
});

/// 스팟 상세 + 현재 점령자 정보 (GET /api/v1/spots/{spotId})
final spotDetailProvider =
    FutureProvider.autoDispose.family<SpotDetail, int>((ref, spotId) {
  return ref.watch(spotServiceProvider).detail(spotId);
});
