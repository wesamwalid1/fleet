import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_session_local_data_source.dart';
import '../datasources/mock_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const logoutAttempts = 3;
  static const logoutRetryDelay = Duration(milliseconds: 200);

  final MockAuthDataSource _dataSource;
  final AuthSessionLocalDataSource _session;

  const AuthRepositoryImpl(this._dataSource, this._session);

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final user = await _dataSource.login(email: email, password: password);
      await _session.saveEmail(user.email);
      return user.toEntity();
    } on InvalidCredentialsException {
      throw const InvalidCredentialsFailure();
    } catch (_) {
      throw const UnexpectedAuthFailure();
    }
  }

  @override
  Future<User?> restoreSession() async {
    final String? email;
    try {
      email = await _session.readEmail();
    } on InvalidAuthSessionException {
      await _session.clear();
      return null;
    }
    if (email == null) return null;
    final user = _dataSource.restore(email);
    if (user == null) {
      await _session.clear();
      return null;
    }
    return user.toEntity();
  }

  /// Throws [LogoutFailure] if the session is still not confirmed cleared
  /// after [logoutAttempts] tries.
  @override
  Future<void> logout() async {
    for (var attempt = 1; ; attempt++) {
      try {
        await _session.clear();
        return;
      } catch (_) {
        if (attempt >= logoutAttempts) throw const LogoutFailure();
        await Future<void>.delayed(logoutRetryDelay);
      }
    }
  }
}
