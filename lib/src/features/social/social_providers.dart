import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dio_client.dart';
import '../dev_tools/mock_group_api.dart';
import 'data/group_api.dart';

final groupApiProvider = Provider<GroupApi>((ref) {
  if (useMockApis) {
    return MockGroupApi();
  }
  return GroupApi(ref.watch(dioProvider));
});

/// 현재 로그인 유저가 호스트로 생성한 방 ID.
/// 방 생성 시 set, 방 삭제/러닝 종료 시 null.
/// logout 전 방 삭제 트리거에 사용.
class ActiveHostGroupIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? groupId) => state = groupId;
}

final activeHostGroupIdProvider =
    NotifierProvider<ActiveHostGroupIdNotifier, int?>(
  ActiveHostGroupIdNotifier.new,
);
