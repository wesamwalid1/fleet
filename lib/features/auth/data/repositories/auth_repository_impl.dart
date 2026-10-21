import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockAuthDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final user = await _dataSource.login(email: email, password: password);
      return user.toEntity();
    } on InvalidCredentialsException {
      throw const InvalidCredentialsFailure();
    } catch (_) {
      throw const UnexpectedAuthFailure();
    }
  }
}
