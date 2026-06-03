import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/network/api_client.dart';

final _logger = Logger();

class GroupRunApiService {
  const GroupRunApiService(this._dio);
  final Dio _dio;

  /// POST /api/v1/groups/{groupId}/run/start — 호스트 전용
  Future<void> runStart(int groupId) async {
    try {
      await _dio.post('/api/v1/groups/$groupId/run/start');
    } catch (e) {
      _logger.e('groupRunStart failed', error: e);
      rethrow;
    }
  }

  /// POST /api/v1/groups/{groupId}/run/finish — 호스트 전용
  Future<void> runFinish(int groupId) async {
    try {
      await _dio.post('/api/v1/groups/$groupId/run/finish');
    } catch (e) {
      _logger.e('groupRunFinish failed', error: e);
      rethrow;
    }
  }

  /// DELETE /api/v1/groups/{groupId} — 방 삭제 (로그아웃/앱 종료 시)
  Future<void> deleteGroup(int groupId) async {
    try {
      await _dio.delete('/api/v1/groups/$groupId');
    } catch (e) {
      _logger.w('deleteGroup failed (best-effort)', error: e);
      // best-effort — 실패해도 무시
    }
  }
}

final groupRunApiServiceProvider = Provider<GroupRunApiService>((ref) {
  return GroupRunApiService(ref.watch(socialDioProvider));
});
