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
}
