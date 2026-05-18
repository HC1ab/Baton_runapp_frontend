import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/utils/jwt_utils.dart';
import '../models/participant_location.dart';
import '../services/run_location_websocket_service.dart';

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

  @override
  RunLocationState build() {
    ref.onDispose(() {
      _service?.dispose();
      _service = null;
    });
    return const RunLocationState();
  }

  /// Join a group room: connect STOMP, subscribe, start GPS publish.
  Future<void> joinRoom(int groupId) async {
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
        throw StateError('로그인이 필요합니다.');
      }

      final memberId = memberIdFromAccessToken(token);
      if (memberId == null) {
        throw StateError('회원 정보를 확인할 수 없습니다.');
      }

      _service ??= RunLocationWebSocketService();

      await _service!.connect(
        groupId: groupId,
        memberId: memberId,
        accessToken: token,
        onLocation: _onRemoteLocation,
      );

      state = state.copyWith(
        connectionState: RunLocationConnectionState.connected,
        myMemberId: memberId,
        clearError: true,
      );
    } catch (e) {
      _logger.e('joinRoom failed', error: e);
      state = state.copyWith(
        connectionState: RunLocationConnectionState.error,
        errorMessage: e.toString().replaceFirst('StateError: ', ''),
      );
    }
  }

  void _onRemoteLocation(ParticipantLocation location) {
    final updated = Map<int, ParticipantLocation>.from(state.participants)
      ..[location.memberId] = location;
    state = state.copyWith(participants: updated);
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

final runLocationWebSocketServiceProvider =
    Provider<RunLocationWebSocketService>((ref) {
  final service = RunLocationWebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final runLocationProvider =
    NotifierProvider<RunLocationNotifier, RunLocationState>(
  RunLocationNotifier.new,
);
