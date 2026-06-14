import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API endpoint and timeout constants.
abstract final class ApiConstants {
  // .env 파일에서 API_BASE_URL 읽기
  // 없으면 Android 에뮬레이터 localhost 기본값 사용
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  // Timeouts
  static const connectTimeoutMs = 5000;
  static const receiveTimeoutMs = 10000;

  // Endpoints — Auth
  static const login = '/api/v1/member/login';
  static const kakaoLogin = '/api/v1/auth/kakao/token';
  static const logout = '/api/v1/member/logout';
  static const join = '/api/v1/member/join';
  static const me = '/api/v1/member/me';
  // TODO: refresh API 구현 후 활성화
  // static const refresh = '/api/v1/member/refresh';
  static const password = '/api/v1/member/password';

  // Endpoints — Run
  static const runStart = '/api/v1/runs/start';
  static const runFinish = '/api/v1/runs'; // + /{runId}/finish
  static const runs = '/api/v1/runs'; // + /{runId}

  // Endpoints — Notice
  static const notices = '/api/v1/notices';

  // Endpoints — Spot
  static const spots = '/api/v1/spots';
  static const spotsNearby = '/api/v1/spots/nearby';
  static const spotsCooldowns = '/api/v1/spots/cooldowns';
  // 점령 지도 — 점령된 스팟 목록 (백엔드 구현 예정)
  static const spotsOccupied = '/api/v1/spots/occupied'; // 전체 점령
  static const spotsOccupiedMe = '/api/v1/spots/occupied/me'; // 내 점령

  // Endpoints — MyRoom
  static const myRoom = '/api/v1/myroom';
  static const myCoreColor = '/api/v1/myroom/core-color';

  // Endpoints — Points
  static const pointsMe = '/api/v1/points/me';

  // Endpoints — Shop
  static const shopItems = '/api/v1/shop/items';
  static const shopPurchase = '/api/v1/shop/purchases';

  // Endpoints — Title / Profile
  static const titleAll = '/api/v1/title/all';
  static const profileEquip = '/api/v1/profile/equip';
  static const profileMe = '/api/v1/profile/me';
  static const profileSearch = '/api/v1/profile/search';
  static String profileById(int memberId) => '/api/v1/profile/$memberId';

  // Endpoints — Follow
  static const followRequest = '/api/v1/follows/request';
  static const followRequests = '/api/v1/follows/requests';
  static const followFollowers = '/api/v1/follows/followers';
  static const followFollowings = '/api/v1/follows/followings';
  static String followAccept(String followId) => '/api/v1/follows/$followId/accept';
  static String followReject(String followId) => '/api/v1/follows/$followId/reject';
  static String followDelete(String followId) => '/api/v1/follows/$followId';

  // Endpoints — Colors
  static const profileColors = '/api/v1/profile/colors';
  static String groupMemberColors(int groupId) =>
      '/api/v1/groups/$groupId/members/colors';
}
