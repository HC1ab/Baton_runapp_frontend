import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/notice_model.dart';

class NoticeApi {
  const NoticeApi(this._dio);
  final Dio _dio;

  Future<List<NoticeSummaryModel>> getNotices() async {
    final response = await _dio.get(ApiConstants.notices);
    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! List<dynamic>) {
      throw ApiException('공지사항 목록 응답이 올바르지 않습니다.');
    }
    return unwrapped
        .map((e) => NoticeSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoticeDetailModel> getNoticeDetail(int noticeId) async {
    final response =
        await _dio.get('${ApiConstants.notices}/$noticeId');
    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! Map<String, dynamic>) {
      throw ApiException('공지사항 응답이 올바르지 않습니다.');
    }
    return NoticeDetailModel.fromJson(unwrapped);
  }
}
