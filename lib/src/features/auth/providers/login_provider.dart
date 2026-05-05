import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

final _logger = Logger();

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum LoginStatus { idle, loading, success, error }

class LoginState {
  const LoginState({
    this.status = LoginStatus.idle,
    this.errorMessage,
  });

  final LoginStatus status;
  final String? errorMessage;

  bool get isLoading => status == LoginStatus.loading;

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Client-side validation
    final validationError = _validate(email: email, password: password);
    if (validationError != null) {
      state = LoginState(
        status: LoginStatus.error,
        errorMessage: validationError,
      );
      return;
    }

    state = const LoginState(status: LoginStatus.loading);

    try {
      final service = ref.read(authServiceProvider);

      // 1. Get tokens
      final pair = await service.login(email: email, password: password);

      // 2. Fetch user profile
      final user = await service.getMe(pair.accessToken);

      // 3. Persist tokens + update global auth state
      await ref.read(authProvider.notifier).onLoginSuccess(pair, user);

      state = const LoginState(status: LoginStatus.success);
    } on AuthException {
      state = const LoginState(
        status: LoginStatus.error,
        errorMessage: ErrorMessages.loginFailed,
      );
    } on NetworkException {
      state = const LoginState(
        status: LoginStatus.error,
        errorMessage: ErrorMessages.networkError,
      );
    } on TimeoutException {
      state = const LoginState(
        status: LoginStatus.error,
        errorMessage: ErrorMessages.timeoutError,
      );
    } on AppException catch (e) {
      state = LoginState(
        status: LoginStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _logger.e('Unexpected login error', error: e);
      state = const LoginState(
        status: LoginStatus.error,
        errorMessage: ErrorMessages.unknownError,
      );
    }
  }

  void resetError() {
    if (state.status == LoginStatus.error) {
      state = const LoginState();
    }
  }

  // --- Validation ---

  String? _validate({required String email, required String password}) {
    if (email.trim().isEmpty) return ErrorMessages.emptyEmail;
    if (!_isValidEmail(email)) return ErrorMessages.invalidEmail;
    if (password.isEmpty) return ErrorMessages.emptyPassword;
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
