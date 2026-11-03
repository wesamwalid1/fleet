import '../models/user_model.dart';

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}

class MockAuthDataSource {
  static const email = 'driver@test.com';
  static const password = '123456';
  static const delay = Duration(milliseconds: 500);

  const MockAuthDataSource();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);

    final isValid =
        email == MockAuthDataSource.email &&
        password == MockAuthDataSource.password;
    if (!isValid) {
      throw const InvalidCredentialsException();
    }

    return const UserModel(email: MockAuthDataSource.email);
  }

  /// The mock account for a stored session, or null if it is not a known one.
  UserModel? restore(String email) {
    if (email != MockAuthDataSource.email) return null;
    return const UserModel(email: MockAuthDataSource.email);
  }
}
