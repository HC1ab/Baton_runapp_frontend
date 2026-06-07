import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/models/user_model.dart';
import '../data/notice_api.dart';
import '../models/notice_model.dart';

export '../models/notice_model.dart';

final noticeApiProvider = Provider<NoticeApi>(
  (ref) => NoticeApi(ref.watch(dioProvider)),
);

final noticeListProvider = FutureProvider<List<NoticeSummaryModel>>((ref) {
  return ref.read(noticeApiProvider).getNotices();
});

final noticeDetailProvider =
    FutureProvider.family<NoticeDetailModel, int>((ref, noticeId) {
  return ref.read(noticeApiProvider).getNoticeDetail(noticeId);
});

/// GET /api/v1/member/me — 계정 정보 조회
/// AuthInterceptor가 토큰을 자동으로 붙여줌
final memberMeProvider = FutureProvider<UserModel>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.me);
  final unwrapped = unwrapApiResponse(response.data);
  if (unwrapped is! Map<String, dynamic>) {
    throw ApiException('계정 정보 응답이 올바르지 않습니다.');
  }
  return UserModel.fromJson(unwrapped);
});
