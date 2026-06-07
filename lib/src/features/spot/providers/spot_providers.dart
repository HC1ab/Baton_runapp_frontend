import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/spot_api.dart';
import '../models/spot_cooldown_model.dart';

export '../models/spot_cooldown_model.dart' show SpotCooldownModel;

final spotApiProvider = Provider<SpotApi>((ref) {
  return SpotApi(ref.watch(dioProvider));
});

final spotCooldownsProvider = FutureProvider<List<SpotCooldownModel>>((ref) {
  return ref.read(spotApiProvider).getCooldowns();
});
