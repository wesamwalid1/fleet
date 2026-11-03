import 'package:driver_portal_app/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_portal_app/features/auth/domain/failures/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const dataSource = MockAuthDataSource();
  const repository = AuthRepositoryImpl(
    dataSource,
    SharedPreferencesAuthSessionDataSource(),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('accepts the mock driver account', () async {
    final user = await repository.login(
      email: MockAuthDataSource.email,
      password: MockAuthDataSource.password,
    );

    expect(user.email, MockAuthDataSource.email);
  });

  test('rejects an unknown email and a wrong password the same way', () async {
    expect(
      () => repository.login(email: 'missing@test.com', password: '123456'),
      throwsA(isA<InvalidCredentialsFailure>()),
    );
    expect(
      () => repository.login(email: MockAuthDataSource.email, password: 'nope'),
      throwsA(isA<InvalidCredentialsFailure>()),
    );
  });
}
