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

  Future<List<Map<String, dynamic>>> list() {
    return requestJson<List<Map<String, dynamic>>>(
      _dio,
      () => _dio.get('/api/v1/groups'),
      mapper: (json) {
        if (json is! List) {
          throw ApiException('그룹 목록 응답 형식이 올바르지 않습니다.');
        }
        return json
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

  Future<void> leave({required int groupId}) async {
    await requestJson<Object?>(
      _dio,
      () => _dio.delete('/api/v1/groups/$groupId/members/me'),
      mapper: (_) => null,
    );
  }
}

class MockGroupApi extends GroupApi {
  MockGroupApi() : super(Dio());

  @override
  Future<int> create({
    required String title,
    required String content,
    required int maxParticipants,
    required String startTimeIsoLocal,
    required String endTimeIsoLocal,
    required int distanceKm,
    required String location,
    required String address,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 1;
  }

  @override
  Future<void> join({required int groupId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> delete({required int groupId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> update({required int groupId, int? maxParticipants}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<List<Map<String, dynamic>>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [];
  }

  @override
  Future<void> leave({required int groupId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}
