import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/spot_cooldown_model.dart';

class SpotApi {
  const SpotApi(this._dio);
  final Dio _dio;

  /// GET /api/v1/spots/cooldowns — 내가 방문한 스팟 목록 + 쿨타임 정보
  Future<List<SpotCooldownModel>> getCooldowns() async {
    final response = await _dio.get(ApiConstants.spotsCooldowns);
    final unwrapped = unwrapApiResponse(response.data);
    if (unwrapped is! List<dynamic>) {
      throw ApiException('스팟 쿨타임 목록 응답이 올바르지 않습니다.');
    }
    return unwrapped
        .map((e) => SpotCooldownModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.lastCheckinAt.compareTo(a.lastCheckinAt));
  }
}
