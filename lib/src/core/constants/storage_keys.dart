/// Keys for local storage (SecureStorage / SharedPreferences / Hive).
/// Never hardcode key strings outside this file.
abstract final class StorageKeys {
  // --- Secure storage (flutter_secure_storage) ---
  static const accessToken = 'auth.accessToken';
  static const refreshToken = 'auth.refreshToken';

  // --- SharedPreferences ---
  /// Current core color code (e.g. CORE_ORANGE).
  /// Set on login from LoginResponse.coreColorCode.
  /// Updated on successful PATCH /api/v1/myroom/core-color.
  static const coreColorCode = 'character.coreColorCode';

  /// Current user's nickname. Set on login.
  // TODO: 서버 GET /api/v1/groups 응답에 hostMemberId 추가되면 이 workaround 제거하고
  //       memberId 직접 비교로 교체할 것.
  static const myNickname = 'auth.myNickname';
}
