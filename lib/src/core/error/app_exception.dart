import '../constants/error_messages.dart';

/// Typed exception hierarchy for the app.
/// All errors must be converted to one of these types before surfacing to UI.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException($runtimeType): $message';
}

/// No internet connection or DNS failure.
final class NetworkException extends AppException {
  const NetworkException([super.message = ErrorMessages.networkError]);
}

/// Request timed out.
final class TimeoutException extends AppException {
  const TimeoutException([super.message = ErrorMessages.timeoutError]);
}

/// 4xx client errors (excluding 401).
final class ServerException extends AppException {
  const ServerException([super.message = ErrorMessages.serverError]);
}

/// 401 Unauthorized — user must re-authenticate.
final class AuthException extends AppException {
  const AuthException([super.message = ErrorMessages.unauthorized]);
}

/// Catch-all for unexpected errors.
final class UnknownException extends AppException {
  const UnknownException([super.message = ErrorMessages.unknownError]);
}
