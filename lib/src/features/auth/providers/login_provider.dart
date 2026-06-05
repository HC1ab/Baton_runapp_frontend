import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/error_messages.dart';
import '../../../core/error/app_exception.dart';
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
// Login Notifier
// ---------------------------------------------------------------------------

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login({
    required String email,
    required String password,
  }) async {
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
      final result = await service.login(email: email, password: password);
      await ref.read(authProvider.notifier).onLoginSuccess(result);
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
      state = LoginState(status: LoginStatus.error, errorMessage: e.message);
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
// Join Notifier
// ---------------------------------------------------------------------------

enum JoinStatus { idle, loading, success, error }

class JoinState {
  const JoinState({
    this.status = JoinStatus.idle,
    this.errorMessage,
  });

  final JoinStatus status;
  final String? errorMessage;

  bool get isLoading => status == JoinStatus.loading;

  JoinState copyWith({JoinStatus? status, String? errorMessage}) {
    return JoinState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class JoinNotifier extends Notifier<JoinState> {
  @override
  JoinState build() => const JoinState();

  Future<void> join({
    required String email,
    required String password,
    required String realname,
    required String nickname,
  }) async {
    final error = _validate(
      email: email,
      password: password,
      realname: realname,
      nickname: nickname,
    );
    if (error != null) {
      state = JoinState(status: JoinStatus.error, errorMessage: error);
      return;
    }

    state = const JoinState(status: JoinStatus.loading);

    try {
      final service = ref.read(authServiceProvider);
      await service.join(
        email: email,
        password: password,
        realname: realname,
        nickname: nickname,
      );
      state = const JoinState(status: JoinStatus.success);
    } on AuthException {
      state = const JoinState(
        status: JoinStatus.error,
        errorMessage: ErrorMessages.loginFailed,
      );
    } on NetworkException {
      state = const JoinState(
        status: JoinStatus.error,
        errorMessage: ErrorMessages.networkError,
      );
    } on TimeoutException {
      state = const JoinState(
        status: JoinStatus.error,
        errorMessage: ErrorMessages.timeoutError,
      );
    } on AppException catch (e) {
      state = JoinState(status: JoinStatus.error, errorMessage: e.message);
    } catch (e) {
      _logger.e('Unexpected join error', error: e);
      state = const JoinState(
        status: JoinStatus.error,
        errorMessage: ErrorMessages.unknownError,
      );
    }
  }

  void reset() => state = const JoinState();

  void resetError() {
    if (state.status == JoinStatus.error) state = const JoinState();
  }

  String? _validate({
    required String email,
    required String password,
    required String realname,
    required String nickname,
  }) {
    if (email.trim().isEmpty) return ErrorMessages.emptyEmail;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return ErrorMessages.invalidEmail;
    }
    if (password.isEmpty) return ErrorMessages.emptyPassword;
    if (password.length < 8) return '비밀번호는 8자 이상이어야 해요.';
    if (realname.trim().isEmpty) return '이름을 입력해주세요.';
    if (nickname.trim().isEmpty) return '닉네임을 입력해주세요.';
    return null;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

final joinProvider = NotifierProvider<JoinNotifier, JoinState>(
  JoinNotifier.new,
);
