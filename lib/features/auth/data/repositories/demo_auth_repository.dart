import 'auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    // Demo only: authentication API is not connected.
    throw Exception('Authentication API is not connected yet.');
  }
}