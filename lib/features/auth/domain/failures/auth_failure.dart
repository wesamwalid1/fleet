sealed class AuthFailure implements Exception {
  const AuthFailure();
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure();
}
