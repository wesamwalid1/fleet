sealed class AuthFailure implements Exception {
  const AuthFailure();
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure();
}

/// The signed-in session could not be persisted after authentication.
final class SessionPersistenceFailure extends AuthFailure {
  const SessionPersistenceFailure();
}

/// The persisted session could not be confirmed as cleared.
final class LogoutFailure extends AuthFailure {
  const LogoutFailure();
}
