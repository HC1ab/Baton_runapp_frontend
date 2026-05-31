import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/monthly_summary_model.dart';

class HistoryApi {
  const HistoryApi(this._dio);
  final Dio _dio;

  /// GET /api/v1/members/me/runs/monthly-summary
  Future<MonthlySummaryModel> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/api/v1/members/me/runs/monthly-summary',
      queryParameters: {
        'year': year,
        'month': month,
      },
    );

    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! Map<String, dynamic>) {
      throw ApiException('월별 요약 데이터 응답이 올바르지 않습니다.');
    }
    return MonthlySummaryModel.fromJson(unwrapped);
  }
}
