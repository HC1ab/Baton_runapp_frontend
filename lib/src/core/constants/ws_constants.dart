import 'package:flutter_dotenv/flutter_dotenv.dart';

/// STOMP WebSocket endpoints for group run live location.
abstract final class WsConstants {
  /// `wss://{host}/ws/run` — derived from [API_BASE_URL] unless [WS_RUN_URL] is set.
  static String get runWebSocketUrl {
    final override = dotenv.env['WS_RUN_URL']?.trim();
    if (override != null && override.isNotEmpty) return override;

    final apiBase = dotenv.env['API_BASE_URL']?.trim() ??
        'https://equator-swimming-folic.ngrok-free.dev';
    final uri = Uri.parse(apiBase);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port/ws/run';
  }

  /// Subscribe: room location broadcast channel.
  static String subscribeDestination(int groupId) =>
      '/topic/groups/$groupId/location';

  /// Publish: send my GPS to the room.
  static String publishDestination(int groupId) =>
      '/app/groups/$groupId/location';

  /// GPS publish interval.
  static const locationPublishInterval = Duration(seconds: 3);
}
