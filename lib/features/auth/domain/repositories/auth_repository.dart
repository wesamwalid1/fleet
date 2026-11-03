import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Signs in and persists the session on success.
  Future<User> login({required String email, required String password});

  /// The signed-in user from a persisted session, or null if there is none
  /// or it is no longer valid.
  Future<User?> restoreSession();

  /// Clears the persisted session. Throws if the clear cannot be confirmed.
  Future<void> logout();
}
