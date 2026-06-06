import 'package:flutter_dotenv/flutter_dotenv.dart';

/// STOMP WebSocket endpoints for group run live location.
///
/// 백엔드 변경 시 이 파일의 상수만 수정하면 전체 앱에 반영됨.
/// - [runWebSocketUrl]    : STOMP endpoint (서버 SockJS/WS handshake URL)
/// - [subscribeDestination]: 방(room)별 위치 브로드캐스트 채널 (Subscribe)
/// - [publishDestination]  : 내 GPS를 서버로 보내는 채널 (Publish)
abstract final class WsConstants {
  /// `wss://{host}/ws/run` — `API_BASE_URL` 기반 자동 변환.
  /// `.env` 의 `WS_RUN_URL` 이 있으면 그 값을 우선 사용.
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

  /// Subscribe — 서버(Redis) 가 방 참가자들의 위치를 브로드캐스트하는 채널.
  /// 예: `/topic/groups/123/location`
  static String subscribeDestination(int groupId) =>
      '/topic/group/$groupId';

  /// Publish — 내 GPS 좌표를 서버로 보내는 목적지.
  /// 예: `/app/groups/123/location`
  static String publishDestination(int groupId) =>
      '/app/group/$groupId/location';

  /// GPS publish 주기. 백엔드 요구사항: 1~2초.
  static const locationPublishInterval = Duration(seconds: 2);

  /// GPS 스트림 distance filter (m). 너무 작으면 배터리 낭비.
  static const gpsDistanceFilterMeters = 2;

  /// STOMP heartbeat / 재연결.
  static const heartbeat = Duration(seconds: 10);
  static const reconnectDelay = Duration(seconds: 5);
  static const connectTimeout = Duration(seconds: 15);
}
