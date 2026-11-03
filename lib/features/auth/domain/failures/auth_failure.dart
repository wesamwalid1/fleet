sealed class AuthFailure implements Exception {
  const AuthFailure();
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure();
}

/// The persisted session could not be confirmed as cleared.
final class LogoutFailure extends AuthFailure {
  const LogoutFailure();
}
