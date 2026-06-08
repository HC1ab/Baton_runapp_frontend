import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/follow_member_model.dart';
import '../models/follow_request_model.dart';
import '../services/follow_service.dart';

export '../services/follow_service.dart' show followServiceProvider;

final pendingFollowRequestsProvider =
    FutureProvider<List<FollowRequestModel>>((ref) {
  return ref.watch(followServiceProvider).getRequests();
});

final followersProvider = FutureProvider<List<FollowMemberModel>>((ref) {
  return ref.watch(followServiceProvider).getFollowers();
});

final followingsProvider = FutureProvider<List<FollowMemberModel>>((ref) {
  return ref.watch(followServiceProvider).getFollowings();
});
