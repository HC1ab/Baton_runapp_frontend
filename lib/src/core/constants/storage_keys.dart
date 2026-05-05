/// Keys for local storage (SecureStorage / SharedPreferences / Hive).
/// Never hardcode key strings outside this file.
abstract final class StorageKeys {
  // --- Secure storage (flutter_secure_storage) ---
  static const accessToken = 'auth.accessToken';
  static const refreshToken = 'auth.refreshToken';
}
