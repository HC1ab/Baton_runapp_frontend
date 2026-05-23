import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Token pair returned by the server on login / refresh.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

/// Wraps FlutterSecureStorage to read / write / clear auth tokens.
/// All storage access must go through this class.
class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<TokenPair?> read() async {
    final access = await _storage.read(key: StorageKeys.accessToken);
    final refresh = await _storage.read(key: StorageKeys.refreshToken);
    if (access == null || access.isEmpty) return null;
    return TokenPair(accessToken: access, refreshToken: refresh ?? '');
  }

  Future<void> write(TokenPair pair) async {
    await _storage.write(key: StorageKeys.accessToken, value: pair.accessToken);
    await _storage.write(
        key: StorageKeys.refreshToken, value: pair.refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    // [iOS 대응] kSecAttrAccessible 옵션이 필요한 경우 iOptions 추가
    aOptions: AndroidOptions(),
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(_flutterSecureStorageProvider));
});
