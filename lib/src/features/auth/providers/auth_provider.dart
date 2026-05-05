import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';
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

/// User is authenticated and profile is loaded.
final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated(this.user);
  final UserModel user;
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
  /// Reads stored token → validates with server → sets state.
  Future<void> _initialize() async {
    try {
      final storage = ref.read(tokenStorageProvider);
      final pair = await storage.read();

      if (pair == null) {
        state = const AuthStateUnauthenticated();
        return;
      }

      // Validate token by fetching user profile.
      final service = ref.read(authServiceProvider);
      final user = await service.getMe(pair.accessToken);
      state = AuthStateAuthenticated(user);
    } catch (e) {
      _logger.w('Auth initialization failed', error: e);
      // Clear potentially invalid token.
      await ref.read(tokenStorageProvider).clear();
      state = const AuthStateUnauthenticated();
    }
  }

  /// Called from LoginNotifier after a successful login response.
  Future<void> onLoginSuccess(TokenPair pair, UserModel user) async {
    await ref.read(tokenStorageProvider).write(pair);
    state = AuthStateAuthenticated(user);
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
