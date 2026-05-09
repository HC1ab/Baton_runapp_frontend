import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'data/group_api.dart';

final groupApiProvider = Provider<GroupApi>((ref) {
  if (useMockApis) {
    return MockGroupApi();
  }
  return GroupApi(ref.watch(socialDioProvider));
});
