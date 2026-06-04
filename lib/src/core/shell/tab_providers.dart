import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_routes.dart';

// ---------------------------------------------------------------------------
// currentTabProvider — HomeScreen 탭 전환용
// ---------------------------------------------------------------------------

class _TabNotifier extends Notifier<int> {
  @override
  int build() => AppTabs.running;

  void switchTo(int index) => state = index;
}

final currentTabProvider = NotifierProvider<_TabNotifier, int>(
  _TabNotifier.new,
);

// ---------------------------------------------------------------------------
// pendingGroupJoinProvider — SocialFeedScreen → RunningScreen 그룹 진입 전달
// ---------------------------------------------------------------------------

typedef GroupJoinRequest = ({int groupId, bool isHost});

class _PendingGroupJoinNotifier extends Notifier<GroupJoinRequest?> {
  @override
  GroupJoinRequest? build() => null;

  void request(GroupJoinRequest req) => state = req;
  void clear() => state = null;
}

final pendingGroupJoinProvider =
    NotifierProvider<_PendingGroupJoinNotifier, GroupJoinRequest?>(
  _PendingGroupJoinNotifier.new,
);
