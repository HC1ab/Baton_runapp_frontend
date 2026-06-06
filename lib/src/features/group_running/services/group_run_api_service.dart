import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';

final _logger = Logger();

/// 참가자 닉네임·칭호 캐시 모델
class ParticipantInfo {
  const ParticipantInfo({required this.nickname, this.titleName});
  final String nickname;
  final String? titleName;
}

class GroupRunApiService {
  const GroupRunApiService(this._dio);
  final Dio _dio;

  /// POST /api/v1/groups/{groupId}/run/start — 호스트 전용
  Future<void> runStart(int groupId) async {
    _logger.d('runStart called — groupId=$groupId');
    try {
      await _dio.post('/api/v1/groups/$groupId/run/start');
    } on DioException catch (e) {
      _logger.e(
        'groupRunStart failed — status=${e.response?.statusCode} body=${e.response?.data}',
        error: e,
      );
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

  /// GET /api/v1/groups/{groupId} → participantNicknames 반환
  Future<List<String>> getParticipantNicknames(int groupId) async {
    try {
      final res = await _dio.get('/api/v1/groups/$groupId');
      final data = res.data['data'] as Map<String, dynamic>?;
      final list = data?['participantNicknames'] as List<dynamic>? ?? [];
      return list.cast<String>();
    } catch (e) {
      _logger.w('getParticipantNicknames failed', error: e);
      return [];
    }
  }

  /// GET /api/v1/profile/search?nickname=... → memberId + equippedTitleName
  Future<ParticipantInfo?> getParticipantInfoByNickname(String nickname) async {
    try {
      final res = await _dio.get(
        '/api/v1/profile/search',
        queryParameters: {'nickname': nickname},
      );
      final list = res.data['data'] as List<dynamic>? ?? [];
      // 닉네임 완전 일치 우선
      final match = list.cast<Map<String, dynamic>>().firstWhere(
        (e) => e['nickname'] == nickname,
        orElse: () => list.isNotEmpty ? list.first as Map<String, dynamic> : {},
      );
      if (match.isEmpty || match['memberId'] == null) return null;
      return ParticipantInfo(
        nickname: match['nickname'] as String? ?? nickname,
        titleName: match['equippedTitleName'] as String?,
      );
    } catch (e) {
      _logger.w('getParticipantInfoByNickname failed for $nickname', error: e);
      return null;
    }
  }

  /// 그룹 참가자 memberId → ParticipantInfo 맵 반환
  Future<Map<int, ParticipantInfo>> fetchParticipantInfoMap(int groupId) async {
    final nicknames = await getParticipantNicknames(groupId);
    final result = <int, ParticipantInfo>{};
    for (final nick in nicknames) {
      try {
        final res = await _dio.get(
          '/api/v1/profile/search',
          queryParameters: {'nickname': nick},
        );
        final list = res.data['data'] as List<dynamic>? ?? [];
        final match = list.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['nickname'] == nick,
          orElse: () => <String, dynamic>{},
        );
        if (match.isEmpty || match['memberId'] == null) continue;
        final id = match['memberId'] as int;
        result[id] = ParticipantInfo(
          nickname: nick,
          titleName: match['equippedTitleName'] as String?,
        );
      } catch (e) {
        _logger.w('fetchParticipantInfo failed for $nick', error: e);
      }
    }
    _logger.i('fetchParticipantInfoMap groupId=$groupId → ${result.length} members');
    return result;
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
  return GroupRunApiService(ref.watch(dioProvider));
});
