import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/error_messages.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/jwt_utils.dart';
import '../models/participant_location.dart';
import '../services/group_run_api_service.dart';
import '../services/run_location_websocket_service.dart';

export '../services/run_location_websocket_service.dart'
    show SessionEndedHandler;

final _logger = Logger();

enum RunLocationConnectionState {
  idle,
  connecting,
  connected,
  error,
}

class RunLocationState {
  const RunLocationState({
    this.connectionState = RunLocationConnectionState.idle,
    this.groupId,
    this.myMemberId,
    this.participants = const {},
    this.myLocation,
    this.errorMessage,
  });

  final RunLocationConnectionState connectionState;
  final int? groupId;
  final int? myMemberId;
  final Map<int, ParticipantLocation> participants;
  final ParticipantLocation? myLocation;
  final String? errorMessage;

  bool get isConnected =>
      connectionState == RunLocationConnectionState.connected;

  RunLocationState copyWith({
    RunLocationConnectionState? connectionState,
    int? groupId,
    int? myMemberId,
    Map<int, ParticipantLocation>? participants,
    ParticipantLocation? myLocation,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RunLocationState(
      connectionState: connectionState ?? this.connectionState,
      groupId: groupId ?? this.groupId,
      myMemberId: myMemberId ?? this.myMemberId,
      participants: participants ?? this.participants,
      myLocation: myLocation ?? this.myLocation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RunLocationNotifier extends Notifier<RunLocationState> {
  RunLocationWebSocketService? _service;
  // memberId → {nickname, titleName, coreColorCode} 캐시
  Map<int, ParticipantInfo> _infoCache = {};
  // 색상 미조회 멤버 ID 모아두고 debounce 후 배치 조회
  final Set<int> _pendingColorFetch = {};
  Timer? _colorFetchDebounce;

  @override
  RunLocationState build() {
    ref.onDispose(() {
      _service?.dispose();
      _service = null;
      _colorFetchDebounce?.cancel();
    });
    return const RunLocationState();
  }

  /// Join a group room: connect STOMP, subscribe, start GPS publish.
  /// [onSessionEnded] — 호스트가 그룹 러닝 종료 시 서버 브로드캐스트 수신 콜백.
  Future<void> joinRoom(int groupId, {SessionEndedHandler? onSessionEnded}) async {
    if (state.connectionState == RunLocationConnectionState.connecting) return;
    if (state.groupId == groupId && state.isConnected) return;

    state = state.copyWith(
      connectionState: RunLocationConnectionState.connecting,
      groupId: groupId,
      participants: {},
      clearError: true,
    );

    try {
      final pair = await ref.read(tokenStorageProvider).read();
      final token = pair?.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError(ErrorMessages.unauthorized);
      }

      final memberId = memberIdFromAccessToken(token);
      if (memberId == null) {
        throw StateError(ErrorMessages.wsMemberInfoUnavailable);
      }

      _service ??= RunLocationWebSocketService();

      await _service!.connect(
        groupId: groupId,
        memberId: memberId,
        accessToken: token,
        onLocation: _onRemoteLocation,
        onSessionEnded: onSessionEnded,
      );

      state = state.copyWith(
        connectionState: RunLocationConnectionState.connected,
        myMemberId: memberId,
        clearError: true,
      );

      // 참가자 닉네임·칭호 비동기 fetch (연결 완료 후)
      _fetchParticipantInfoCache(groupId, memberId);
    } catch (e) {
      _logger.e('joinRoom failed', error: e);
      state = state.copyWith(
        connectionState: RunLocationConnectionState.error,
        errorMessage: e.toString().replaceFirst('StateError: ', ''),
      );
    }
  }

  Future<void> _fetchParticipantInfoCache(int groupId, int myMemberId) async {
    try {
      final apiService = ref.read(groupRunApiServiceProvider);
      final map = await apiService.fetchGroupMemberColors(groupId);
      map.remove(myMemberId);

      // nickname → profile search로 titleName 보완 (그룹 최대 5명이라 N+1 허용)
      for (final entry in map.entries) {
        final nickname = entry.value.nickname;
        if (nickname.isEmpty) continue;
        try {
          final info = await apiService.getParticipantInfoByNickname(nickname);
          if (info?.titleName != null) {
            map[entry.key] = ParticipantInfo(
              nickname: entry.value.nickname,
              titleName: info!.titleName,
              coreColorCode: entry.value.coreColorCode,
            );
          }
        } catch (e) {
          _logger.w('titleName fetch failed for $nickname', error: e);
        }
      }

      _infoCache = map;
      // 이미 수신된 participants에 정보 주입
      if (state.participants.isNotEmpty) {
        final updated = state.participants.map((id, loc) {
          final info = _infoCache[id];
          if (info == null) return MapEntry(id, loc);
          return MapEntry(id, loc.copyWith(
            nickname: info.nickname,
            titleName: info.titleName,
            coreColorCode: info.coreColorCode,
          ));
        });
        state = state.copyWith(participants: updated);
      }
    } catch (e) {
      _logger.w('_fetchParticipantInfoCache failed', error: e);
    }
  }

  void _onRemoteLocation(ParticipantLocation location) {
    final info = _infoCache[location.memberId];
    final enriched = info != null
        ? location.copyWith(
            nickname: info.nickname,
            titleName: info.titleName,
            coreColorCode: info.coreColorCode,
          )
        : location;

    // cache miss → 배치 조회 예약
    if (info == null) {
      _pendingColorFetch.add(location.memberId);
      _colorFetchDebounce?.cancel();
      _colorFetchDebounce = Timer(
        const Duration(milliseconds: 500),
        _flushPendingColorFetch,
      );
    }

    final updated = Map<int, ParticipantLocation>.from(state.participants)
      ..[enriched.memberId] = enriched;
    state = state.copyWith(participants: updated);
  }

  Future<void> _flushPendingColorFetch() async {
    if (_pendingColorFetch.isEmpty) return;
    final ids = List<int>.from(_pendingColorFetch);
    _pendingColorFetch.clear();

    final groupId = state.groupId;
    if (groupId == null) return;

    try {
      final apiService = ref.read(groupRunApiServiceProvider);

      // fetchGroupMemberColors: color + nickname 한 번에 (fetchProfileColorsBatch는 color만)
      final memberMap = await apiService.fetchGroupMemberColors(groupId);
      final filtered = Map<int, ParticipantInfo>.fromEntries(
        memberMap.entries.where((e) => ids.contains(e.key)),
      );
      if (filtered.isEmpty) return;

      // titleName N+1 — 그룹 최대 5명이라 허용
      for (final entry in List<MapEntry<int, ParticipantInfo>>.from(filtered.entries)) {
        final nickname = entry.value.nickname;
        if (nickname.isEmpty) continue;
        try {
          final info = await apiService.getParticipantInfoByNickname(nickname);
          if (info?.titleName != null) {
            filtered[entry.key] = ParticipantInfo(
              nickname: nickname,
              titleName: info!.titleName,
              coreColorCode: entry.value.coreColorCode,
            );
          }
        } catch (e) {
          _logger.w('titleName fetch failed for $nickname in flush', error: e);
        }
      }

      // cache 머지 (기존 정보 유지하며 덮어쓰기)
      _infoCache.addAll(filtered);

      // participants 갱신 (nickname/titleName/color 모두 반영)
      final updated = state.participants.map((id, loc) {
        final info = filtered[id];
        if (info == null) return MapEntry(id, loc);
        return MapEntry(
          id,
          loc.copyWith(
            nickname: info.nickname.isEmpty ? null : info.nickname,
            titleName: info.titleName,
            coreColorCode: info.coreColorCode,
          ),
        );
      });
      state = state.copyWith(participants: updated);
    } catch (e) {
      _logger.w('_flushPendingColorFetch failed', error: e);
    }
  }

  /// 목 GPS 모드에서 호출 — WS publish 좌표를 가상 좌표로 고정.
  void updateMockPosition(double lat, double lng) {
    _service?.setMockPosition(lat, lng);
  }

  void updateMyLocation(double latitude, double longitude) {
    final memberId = state.myMemberId;
    if (memberId == null) return;
    state = state.copyWith(
      myLocation: ParticipantLocation(
        memberId: memberId,
        latitude: latitude,
        longitude: longitude,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> leaveRoom() async {
    await _service?.disconnect();
    state = const RunLocationState();
  }
}

final runLocationProvider =
    NotifierProvider<RunLocationNotifier, RunLocationState>(
  RunLocationNotifier.new,
);
