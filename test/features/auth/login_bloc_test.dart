import 'dart:async';

import 'package:driver_portal_app/features/auth/domain/entities/user.dart';
import 'package:driver_portal_app/features/auth/domain/failures/auth_failure.dart';
import 'package:driver_portal_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_portal_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:driver_portal_app/features/auth/presentation/bloc/login_bloc.dart';
import 'package:driver_portal_app/features/auth/presentation/bloc/login_event.dart';
import 'package:driver_portal_app/features/auth/presentation/bloc/login_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(email: 'driver@test.com');

  test('empty fields fail locally and do not call the repository', () async {
    final repository = _FakeAuthRepository();
    final bloc = LoginBloc(LoginUseCase(repository));

    bloc.add(const LoginSubmitted(email: '  ', password: ''));
    await expectLater(
      bloc.stream,
      emits(
        const LoginFailure(
          emailError: EmailError.empty,
          passwordError: PasswordError.empty,
        ),
      ),
    );

    expect(repository.calls, 0);
    await bloc.close();
  });

  test(
    'invalid email fails locally and does not call the repository',
    () async {
      final repository = _FakeAuthRepository();
      final bloc = LoginBloc(LoginUseCase(repository));

      bloc.add(const LoginSubmitted(email: 'DR-001', password: '123456'));
      await expectLater(
        bloc.stream,
        emits(const LoginFailure(emailError: EmailError.invalidFormat)),
      );

      expect(repository.calls, 0);
      await bloc.close();
    },
  );

  test(
    'empty password fails locally and does not call the repository',
    () async {
      final repository = _FakeAuthRepository();
      final bloc = LoginBloc(LoginUseCase(repository));

      bloc.add(const LoginSubmitted(email: 'driver@test.com', password: ''));
      await expectLater(
        bloc.stream,
        emits(const LoginFailure(passwordError: PasswordError.empty)),
      );

      expect(repository.calls, 0);
      await bloc.close();
    },
  );

  test('wrong credentials emit login failure', () async {
    final repository = _FakeAuthRepository(
      onLogin: (_, _) async => throw const InvalidCredentialsFailure(),
    );
    final bloc = LoginBloc(LoginUseCase(repository));

    bloc.add(const LoginSubmitted(email: 'driver@test.com', password: 'wrong'));
    await expectLater(
      bloc.stream,
      emitsInOrder([
        const LoginLoading(),
        const LoginFailure(authError: AuthError.invalidCredentials),
      ]),
    );
    await bloc.close();
  });

  test('valid credentials emit login success', () async {
    final repository = _FakeAuthRepository(onLogin: (_, _) async => user);
    final bloc = LoginBloc(LoginUseCase(repository));

    bloc.add(
      const LoginSubmitted(email: ' driver@test.com ', password: '123456'),
    );
    await expectLater(
      bloc.stream,
      emitsInOrder([const LoginLoading(), const LoginSuccess(user)]),
    );
    expect(repository.lastEmail, 'driver@test.com');
    await bloc.close();
  });

  test('a second submit is ignored while login is in progress', () async {
    final completer = Completer<User>();
    final repository = _FakeAuthRepository(onLogin: (_, _) => completer.future);
    final bloc = LoginBloc(LoginUseCase(repository));

    bloc.add(
      const LoginSubmitted(email: 'driver@test.com', password: '123456'),
    );
    await expectLater(bloc.stream, emits(const LoginLoading()));

    bloc.add(
      const LoginSubmitted(email: 'driver@test.com', password: '123456'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, 1);
    completer.complete(user);
    await expectLater(bloc.stream, emits(const LoginSuccess(user)));
    expect(repository.calls, 1);
    await bloc.close();
  });
}

class _FakeAuthRepository implements AuthRepository {
  final Future<User> Function(String email, String password) onLogin;
  int calls = 0;
  String? lastEmail;

  _FakeAuthRepository({this.onLogin = _defaultLogin});

  static Future<User> _defaultLogin(String email, String password) async {
    return const User(email: 'driver@test.com');
  }

  @override
  Future<User> login({required String email, required String password}) {
    calls++;
    lastEmail = email;
    return onLogin(email, password);
  }
}
