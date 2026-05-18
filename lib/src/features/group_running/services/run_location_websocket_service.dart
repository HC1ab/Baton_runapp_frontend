import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/ws_constants.dart';
import '../models/participant_location.dart';

final _logger = Logger();

typedef LocationMessageHandler = void Function(ParticipantLocation location);

/// STOMP client for group run live location (connect / subscribe / publish).
class RunLocationWebSocketService {
  StompClient? _client;
  int? _activeGroupId;
  int? _myMemberId;
  Timer? _publishTimer;
  LocationMessageHandler? _onLocation;

  bool get isConnected => _client?.connected ?? false;
  int? get activeGroupId => _activeGroupId;

  /// Connects to `/ws/run`, subscribes to the room channel, starts GPS publish loop.
  Future<void> connect({
    required int groupId,
    required int memberId,
    required String accessToken,
    required LocationMessageHandler onLocation,
  }) async {
    if (_activeGroupId == groupId && isConnected) return;

    await disconnect();

    _activeGroupId = groupId;
    _myMemberId = memberId;
    _onLocation = onLocation;

    final completer = Completer<void>();

    _client = StompClient(
      config: StompConfig(
        url: WsConstants.runWebSocketUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        stompConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
        },
        webSocketConnectHeaders: const {
          'ngrok-skip-browser-warning': 'true',
        },
        onConnect: (frame) {
          _logger.i('STOMP connected (groupId=$groupId)');
          _subscribe(groupId);
          _startPublishing(groupId, memberId);
          if (!completer.isCompleted) completer.complete();
        },
        onWebSocketError: (dynamic error) {
          _logger.e('WebSocket error', error: error);
          if (!completer.isCompleted) {
            completer.completeError(error ?? 'WebSocket connection failed');
          }
        },
        onStompError: (frame) {
          _logger.e('STOMP error: ${frame.body}');
          if (!completer.isCompleted) {
            completer.completeError(frame.body ?? 'STOMP error');
          }
        },
        onDisconnect: (frame) {
          _logger.i('STOMP disconnected');
        },
      ),
    );

    _client!.activate();

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('웹소켓 연결 시간이 초과됐습니다.'),
    );
  }

  void _subscribe(int groupId) {
    final client = _client;
    if (client == null || !client.connected) return;

    final destination = WsConstants.subscribeDestination(groupId);
    _logger.i('STOMP subscribe → $destination');

    client.subscribe(
      destination: destination,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            _handleLocationPayload(decoded);
          } else if (decoded is List) {
            for (final item in decoded) {
              if (item is Map<String, dynamic>) _handleLocationPayload(item);
            }
          }
        } catch (e) {
          _logger.w('Failed to parse location message: $body', error: e);
        }
      },
    );
  }

  void _handleLocationPayload(Map<String, dynamic> json) {
    try {
      final location = ParticipantLocation.fromJson(json);
      if (location.memberId == _myMemberId) return;
      _onLocation?.call(location);
    } catch (e) {
      _logger.w('Skip invalid location payload', error: e);
    }
  }

  void _startPublishing(int groupId, int memberId) {
    _publishTimer?.cancel();
    _publishTimer = Timer.periodic(
      WsConstants.locationPublishInterval,
      (_) => unawaited(_publishCurrentLocation(groupId, memberId)),
    );
    unawaited(_publishCurrentLocation(groupId, memberId));
  }

  Future<void> _publishCurrentLocation(int groupId, int memberId) async {
    final client = _client;
    if (client == null || !client.connected) return;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final payload = ParticipantLocation(
        memberId: memberId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        updatedAt: DateTime.now(),
      ).toPublishJson(groupId: groupId, memberId: memberId);

      client.send(
        destination: WsConstants.publishDestination(groupId),
        body: jsonEncode(payload),
      );
    } catch (e) {
      _logger.w('Location publish failed', error: e);
    }
  }

  Future<void> disconnect() async {
    _publishTimer?.cancel();
    _publishTimer = null;
    _onLocation = null;
    _activeGroupId = null;
    _myMemberId = null;

    final client = _client;
    _client = null;
    if (client != null) {
      client.deactivate();
    }
  }

  void dispose() {
    unawaited(disconnect());
  }
}
