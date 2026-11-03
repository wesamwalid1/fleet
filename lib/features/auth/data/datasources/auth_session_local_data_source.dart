import 'package:shared_preferences/shared_preferences.dart';

/// The stored session value is present but is not a usable session.
class InvalidAuthSessionException implements Exception {
  const InvalidAuthSessionException();
}

/// Session storage could not complete the requested change.
class AuthSessionStorageException implements Exception {
  const AuthSessionStorageException();
}

/// Remembers which mock driver is signed in between app launches.
///
/// Mock-authentication only: the stored value is the signed-in email, not a
/// credential, and proves nothing on its own. A real API must store its own
/// token (for example in secure storage) and validate it with the server.
abstract interface class AuthSessionLocalDataSource {
  /// The stored email, or null if none is saved.
  ///
  /// Throws [InvalidAuthSessionException] when the stored value is not a
  /// string, and lets storage errors propagate.
  Future<String?> readEmail();

  Future<void> saveEmail(String email);

  /// Throws [AuthSessionStorageException] when storage reports the removal
  /// failed, and lets storage errors propagate.
  Future<void> clear();
}

class SharedPreferencesAuthSessionDataSource
    implements AuthSessionLocalDataSource {
  static const storageKey = 'auth_mock_session_email';

  final Future<SharedPreferences> Function() _getPreferences;

  const SharedPreferencesAuthSessionDataSource({
    Future<SharedPreferences> Function() preferences =
        SharedPreferences.getInstance,
  }) : _getPreferences = preferences;

  @override
  Future<String?> readEmail() async {
    final value = (await _getPreferences()).get(storageKey);
    if (value == null || value is String) return value as String?;
    throw const InvalidAuthSessionException();
  }

  @override
  Future<void> saveEmail(String email) async {
    final preferences = await _preferencesOrNull();
    await preferences?.setString(storageKey, email);
  }

  @override
  Future<void> clear() async {
    final removed = await (await _getPreferences()).remove(storageKey);
    if (!removed) throw const AuthSessionStorageException();
  }

  Future<SharedPreferences?> _preferencesOrNull() async {
    try {
      return await _getPreferences();
    } catch (_) {
      return null;
    }
  }
}
