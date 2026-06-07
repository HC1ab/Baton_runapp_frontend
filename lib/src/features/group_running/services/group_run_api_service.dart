import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';

final _logger = Logger();

/// 참가자 닉네임·칭호·색상 캐시 모델
class ParticipantInfo {
  const ParticipantInfo({
    required this.nickname,
    this.titleName,
    this.coreColorCode,
  });
  final String nickname;
  final String? titleName;
  final String? coreColorCode;
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

  /// GET /api/v1/groups/{groupId}/members/colors — 그룹 전체 참가자 색상 일괄 조회
  Future<Map<int, ParticipantInfo>> fetchGroupMemberColors(int groupId) async {
    try {
      final res = await _dio.get('/api/v1/groups/$groupId/members/colors');
      final list = res.data['data'] as List<dynamic>? ?? [];
      final result = <int, ParticipantInfo>{};
      for (final item in list.cast<Map<String, dynamic>>()) {
        final id = item['memberId'];
        if (id == null) continue;
        result[id as int] = ParticipantInfo(
          nickname: item['nickname'] as String? ?? '',
          coreColorCode: item['coreColorCode'] as String?,
        );
      }
      _logger.i('fetchGroupMemberColors groupId=$groupId → ${result.length} members');
      return result;
    } catch (e) {
      _logger.w('fetchGroupMemberColors failed', error: e);
      return {};
    }
  }

  /// GET /api/v1/profile/colors?memberIds=1,2,3 — 특정 멤버 색상 배치 조회
  Future<Map<int, String>> fetchProfileColorsBatch(List<int> memberIds) async {
    if (memberIds.isEmpty) return {};
    try {
      final res = await _dio.get(
        '/api/v1/profile/colors',
        queryParameters: {'memberIds': memberIds.join(',')},
      );
      final list = res.data['data'] as List<dynamic>? ?? [];
      final result = <int, String>{};
      for (final item in list.cast<Map<String, dynamic>>()) {
        final id = item['memberId'];
        final code = item['coreColorCode'];
        if (id != null && code != null) {
          result[id as int] = code as String;
        }
      }
      return result;
    } catch (e) {
      _logger.w('fetchProfileColorsBatch failed ids=$memberIds', error: e);
      return {};
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
  return GroupRunApiService(ref.watch(dioProvider));
});
