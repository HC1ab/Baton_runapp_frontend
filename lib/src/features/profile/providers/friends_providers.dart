import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../social/models/follow_member_model.dart';
import '../../social/services/follow_service.dart';

final followersProvider = FutureProvider<List<FollowMemberModel>>((ref) {
  return ref.watch(followServiceProvider).getFollowers();
});

final followingsProvider = FutureProvider<List<FollowMemberModel>>((ref) {
  return ref.watch(followServiceProvider).getFollowings();
});
