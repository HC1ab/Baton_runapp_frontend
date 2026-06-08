import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class GroupApi {
  GroupApi(this._dio);
  final Dio _dio;

  Future<int> create({
    required String title,
    required String content,
    required int maxParticipants,
    required String startTimeIsoLocal,
    required String endTimeIsoLocal,
    required int distanceKm,
    required String location,
    required String address,
    double? latitude,
    double? longitude,
  }) {
    return requestJson<int>(
      _dio,
      () => _dio.post(
        '/api/v1/groups',
        data: {
          'title': title,
          'content': content,
          'maxParticipants': maxParticipants,
          'startTime': startTimeIsoLocal,
          'endTime': endTimeIsoLocal,
          'distance': distanceKm,
          'location': location,
          'address': address,
          if (latitude != null) 'lat': latitude,
          if (longitude != null) 'lon': longitude,
        },
      ),
      mapper: (json) => (json as num).toInt(),
    );
  }

  Future<void> join({required int groupId}) async {
    await requestJson<Object?>(
      _dio,
      () => _dio.post('/api/v1/groups/$groupId/join'),
      mapper: (_) => null,
    );
  }

  Future<void> delete({required int groupId}) async {
    await requestJson<Object?>(
      _dio,
      () => _dio.delete('/api/v1/groups/$groupId'),
      mapper: (_) => null,
    );
  }

  Future<void> update({
    required int groupId,
    int? maxParticipants,
  }) async {
    await requestJson<Object?>(
      _dio,
      () => _dio.patch(
        '/api/v1/groups/$groupId',
        data: {
          if (maxParticipants != null) 'maxParticipants': maxParticipants,
        },
      ),
      mapper: (_) => null,
    );
  }

  Future<List<Map<String, dynamic>>> list({int page = 0, int size = 20}) {
    return requestJson<List<Map<String, dynamic>>>(
      _dio,
      () => _dio.get(
        '/api/v1/groups',
        queryParameters: {'page': page, 'size': size, 'sort': 'startTime,desc'},
      ),
      mapper: (json) {
        final list = _extractGroupList(json);
        return list
            .whereType<Map>()
            .map(
              (e) => e.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            .toList();
      },
    );
  }

  List<dynamic> _extractGroupList(dynamic json) {
    if (json is List) return json;

    if (json is Map<String, dynamic>) {
      for (final key in const [
        'content',
        'groups',
        'items',
        'list',
        'results',
        'groupList',
      ]) {
        final value = json[key];
        if (value is List) return value;
      }
    }

    throw ApiException('그룹 목록 응답 형식이 올바르지 않습니다.');
  }

  Future<void> leave({required int groupId}) async {
    await requestJson<Object?>(
      _dio,
      () => _dio.delete('/api/v1/groups/$groupId/members/me'),
      mapper: (_) => null,
    );
  }

  /// GET /api/v1/groups/{groupId} — 상세 조회 (hostNickname, participantNicknames 포함)
  Future<Map<String, dynamic>> getDetail({required int groupId}) {
    return requestJson<Map<String, dynamic>>(
      _dio,
      () => _dio.get('/api/v1/groups/$groupId'),
      mapper: (json) => json as Map<String, dynamic>,
    );
  }
}
