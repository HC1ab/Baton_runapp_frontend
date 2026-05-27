import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/shared_prefs_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../services/auth_service.dart';

final _logger = Logger();

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Represents the entire authentication state of the app.
sealed class AuthState {
  const AuthState();
}

/// App is reading tokens from secure storage on startup.
final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is authenticated.
/// UserModel은 /me API 구현 후 추가 예정
final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated();
}

/// User is not authenticated (no token, token invalid, or logged out).
final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Start loading and kick off async init.
    _initialize();
    return const AuthStateLoading();
  }

  /// Called once on app startup.
  /// Reads stored token → token 존재 여부만 확인 → sets state.
  /// (getMe 검증은 /me API 구현 후 추가 예정)
  Future<void> _initialize() async {
    try {
      final storage = ref.read(tokenStorageProvider);
      final pair = await storage.read();

      if (pair == null) {
        state = const AuthStateUnauthenticated();
        return;
      }

      // 토큰이 존재하면 인증된 상태로 처리
      // TODO: /me API 구현 후 토큰 유효성 검증 추가
      state = const AuthStateAuthenticated();
    } catch (e) {
      _logger.w('Auth initialization failed', error: e);
      await ref.read(tokenStorageProvider).clear();
      state = const AuthStateUnauthenticated();
    }
  }

  /// Called from LoginNotifier after a successful login response.
  /// Saves token pair to SecureStorage and coreColorCode to SharedPreferences.
  Future<void> onLoginSuccess(LoginResult result) async {
    await ref.read(tokenStorageProvider).write(result.tokenPair);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(StorageKeys.coreColorCode, result.coreColorCode);
    _logger.i(
      'Login saved — access: ${result.tokenPair.accessToken.substring(0, 20)}... '
      'coreColor: ${result.coreColorCode}',
    );
    state = const AuthStateAuthenticated();
  }

  /// Clears token and returns to unauthenticated state.
  Future<void> logout() async {
    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      // Ignore logout API errors — clear locally regardless.
      _logger.w('Logout API call failed', error: e);
    } finally {
      await ref.read(tokenStorageProvider).clear();
      state = const AuthStateUnauthenticated();
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
