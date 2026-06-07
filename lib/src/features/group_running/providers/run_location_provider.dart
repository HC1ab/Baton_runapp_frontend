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
  // memberId → {nickname, titleName} 캐시
  Map<int, ParticipantInfo> _infoCache = {};

  @override
  RunLocationState build() {
    ref.onDispose(() {
      _service?.dispose();
      _service = null;
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
      final map = await apiService.fetchParticipantInfoMap(groupId);
      // 본인 제외
      map.remove(myMemberId);
      _infoCache = map;
      // 이미 수신된 participants에 정보 주입
      if (state.participants.isNotEmpty) {
        final updated = state.participants.map((id, loc) {
          final info = _infoCache[id];
          if (info == null) return MapEntry(id, loc);
          return MapEntry(id, loc.copyWith(
            nickname: info.nickname,
            titleName: info.titleName,
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
        ? location.copyWith(nickname: info.nickname, titleName: info.titleName)
        : location;
    final updated = Map<int, ParticipantLocation>.from(state.participants)
      ..[enriched.memberId] = enriched;
    state = state.copyWith(participants: updated);
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
