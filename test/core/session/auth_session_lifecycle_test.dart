import 'dart:async';

import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_portal_app/features/auth/domain/entities/user.dart';
import 'package:driver_portal_app/features/auth/domain/failures/auth_failure.dart';
import 'package:driver_portal_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_portal_app/features/auth/domain/usecases/restore_session_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';
import '../../support/reveal_finance.dart';

const _key = SharedPreferencesAuthSessionDataSource.storageKey;
const _repository = AuthRepositoryImpl(
  MockAuthDataSource(),
  SharedPreferencesAuthSessionDataSource(),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('mock session persistence', () {
    test('no saved session restores nothing', () async {
      expect(await _repository.restoreSession(), isNull);
    });

    test('a successful login saves only the email', () async {
      await _repository.login(
        email: MockAuthDataSource.email,
        password: MockAuthDataSource.password,
      );

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), MockAuthDataSource.email);
      for (final key in preferences.getKeys()) {
        expect(
          preferences.get(key).toString(),
          isNot(contains(MockAuthDataSource.password)),
        );
      }
      expect(
        (await _repository.restoreSession())?.email,
        MockAuthDataSource.email,
      );
    });

    test('saveEmail persists the email when setString succeeds', () async {
      final preferences = _ControllablePreferences();
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () async => preferences,
      );

      await source.saveEmail(MockAuthDataSource.email);

      expect(preferences.values[_key], MockAuthDataSource.email);
    });

    test('saveEmail fails when SharedPreferences cannot initialize', () async {
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () => Future.error(Exception('storage unavailable')),
      );

      await expectLater(source.saveEmail(MockAuthDataSource.email), throwsA(anything));
    });

    test('saveEmail fails when setString returns false', () async {
      final preferences = _ControllablePreferences(setStringResult: false);
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () async => preferences,
      );

      await expectLater(
        source.saveEmail(MockAuthDataSource.email),
        throwsA(isA<AuthSessionStorageException>()),
      );
      expect(preferences.values.containsKey(_key), isFalse);
    });

    test('login maps a save failure to SessionPersistenceFailure', () async {
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        SharedPreferencesAuthSessionDataSource(
          preferences: () async =>
              _ControllablePreferences(setStringResult: false),
        ),
      );

      await expectLater(
        repository.login(
          email: MockAuthDataSource.email,
          password: MockAuthDataSource.password,
        ),
        throwsA(isA<SessionPersistenceFailure>()),
      );
      expect(await repository.restoreSession(), isNull);
    });

    test('a failed login saves nothing', () async {
      await expectLater(
        _repository.login(email: MockAuthDataSource.email, password: 'nope'),
        throwsA(anything),
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_key), isFalse);
    });

    test('an invalid saved session is rejected and cleared', () async {
      SharedPreferences.setMockInitialValues({_key: 'someone@else.com'});

      expect(await _repository.restoreSession(), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_key), isFalse);
    });

    test('logout clears the saved session', () async {
      SharedPreferences.setMockInitialValues({_key: MockAuthDataSource.email});

      await _repository.logout();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_key), isFalse);
      expect(await _repository.restoreSession(), isNull);
    });
  });

  group('cold start and lifecycle', () {
    testWidgets('first launch without a session opens Login', (tester) async {
      await _coldStart(tester);

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('home-page')), findsNothing);
    });

    testWidgets('a saved session opens Home on cold start', (tester) async {
      SharedPreferences.setMockInitialValues({_key: MockAuthDataSource.email});

      await _coldStart(tester);

      expect(find.byKey(const Key('home-page')), findsOneWidget);
      expect(find.byKey(const Key('login-email')), findsNothing);
      final popped = await tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .maybePop();
      expect(popped, isFalse);
    });

    testWidgets('login persists the session and logout clears it', (
      tester,
    ) async {
      await _coldStart(tester);
      await _login(tester);

      expect(find.byKey(const Key('home-page')), findsOneWidget);
      expect(await _savedEmail(tester), MockAuthDataSource.email);

      await tester.tap(find.byKey(const Key('nav-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(await _savedEmail(tester), isNull);

      await _terminate(tester);
      await _coldStart(tester);
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('home-page')), findsNothing);
    });

    testWidgets('an authenticated cold start opens Home, not the last tab', (
      tester,
    ) async {
      await _coldStart(tester);
      await _login(tester);
      await tester.tap(find.byKey(const Key('nav-history')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('history-title')).hitTestable(),
        findsOneWidget,
      );

      await _terminate(tester);
      await _coldStart(tester);

      expect(find.byKey(const Key('home-page')).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('history-title')).hitTestable(),
        findsNothing,
      );
      expect(find.byKey(const Key('login-email')), findsNothing);
    });

    testWidgets('background and resume keep the screen, tab, and session', (
      tester,
    ) async {
      await _coldStart(tester);
      await _login(tester);

      await tester.tap(find.byKey(const Key('nav-approvals')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('approval-action-DSB-2025-0441')),
      );
      await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-history')));
      await tester.pumpAndSettle();

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('history-title')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const Key('login-email')), findsNothing);

      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pumpAndSettle();
      await revealHomeFinance(tester);
      // The approval made before backgrounding is still in the same session.
      expect(find.text('4,200 EGP'), findsNWidgets(2));
      expect(await _savedEmail(tester), MockAuthDataSource.email);
    });
  });

  group('startup failures fall back to Login', () {
    Future<String> routeFor(AuthRepository repository, {Duration? timeout}) {
      return AppRoute.initialRouteFor(
        RestoreSessionUseCase(repository),
        timeout: timeout ?? AppRoute.sessionRestoreTimeout,
      );
    }

    test('a non-string saved value is rejected and cleared', () async {
      SharedPreferences.setMockInitialValues({_key: 42});

      expect(await routeFor(_repository), AppRoute.login);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_key), isFalse);
    });

    test('a corrupted string value is rejected and cleared', () async {
      SharedPreferences.setMockInitialValues({_key: '%%corrupted%%'});

      expect(await routeFor(_repository), AppRoute.login);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_key), isFalse);
    });

    test('unavailable storage falls back to Login', () async {
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        SharedPreferencesAuthSessionDataSource(
          preferences: () => Future.error(Exception('storage unavailable')),
        ),
      );

      expect(await routeFor(repository), AppRoute.login);
    });

    test('a restore exception falls back to Login', () async {
      final repository = _ControlledAuthRepository()
        ..restore.completeError(Exception('restore failed'));

      expect(await routeFor(repository), AppRoute.login);
    });

    test('a restore that never answers times out to Login', () async {
      final repository = _ControlledAuthRepository();
      final clock = Stopwatch()..start();

      final route = await routeFor(
        repository,
        timeout: const Duration(milliseconds: 50),
      );

      expect(route, AppRoute.login);
      expect(clock.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('a late success after the timeout changes nothing', () async {
      final repository = _ControlledAuthRepository();
      final route = await routeFor(
        repository,
        timeout: const Duration(milliseconds: 20),
      );

      repository.restore.complete(const User(email: MockAuthDataSource.email));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(route, AppRoute.login);
    });

    test('a late error after the timeout is not unhandled', () async {
      final repository = _ControlledAuthRepository();
      final route = await routeFor(
        repository,
        timeout: const Duration(milliseconds: 20),
      );

      repository.restore.completeError(Exception('late failure'));
      // An unhandled error here would fail this test.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(route, AppRoute.login);
    });

    testWidgets('a non-string saved value opens Login on cold start', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({_key: true});

      await _coldStart(tester);

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('home-page')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('logout persistence failures', () {
    test('clear succeeds when the session key is already missing', () async {
      final preferences = _ControllablePreferences();
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () async => preferences,
      );

      await source.clear();

      expect(preferences.removeCalls, 0);
    });

    test('clear removes an existing session key', () async {
      final preferences = _ControllablePreferences(
        initial: {_key: MockAuthDataSource.email},
      );
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () async => preferences,
      );

      await source.clear();

      expect(preferences.containsKey(_key), isFalse);
      expect(preferences.removeCalls, 1);
    });

    test('removal reporting false is a storage failure', () async {
      final preferences = _ControllablePreferences(
        initial: {_key: MockAuthDataSource.email},
        removeResult: false,
      );
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () async => preferences,
      );

      await expectLater(
        source.clear(),
        throwsA(isA<AuthSessionStorageException>()),
      );
      expect(preferences.containsKey(_key), isTrue);
    });

    test('a removal exception reaches the caller', () async {
      final preferences = _ControllablePreferences(
        initial: {_key: MockAuthDataSource.email},
        removeThrows: true,
      );
      final source = SharedPreferencesAuthSessionDataSource(
        preferences: () async => preferences,
      );

      await expectLater(source.clear(), throwsA(isA<StateError>()));
    });

    test('logout treats a missing key as success', () async {
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        SharedPreferencesAuthSessionDataSource(
          preferences: () async => _ControllablePreferences(),
        ),
      );

      await repository.logout();
      expect(await repository.restoreSession(), isNull);
    });

    test('logout retries a bounded number of times then succeeds', () async {
      final session = _MemorySession(email: MockAuthDataSource.email)
        ..failingClears = AuthRepositoryImpl.logoutAttempts - 1;
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        session,
      );

      await repository.logout();

      expect(session.clearCalls, AuthRepositoryImpl.logoutAttempts);
      expect(session.email, isNull);
    });

    test('logout gives up after the bounded attempts', () async {
      final session = _MemorySession(email: MockAuthDataSource.email)
        ..failingClears = 1000;
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        session,
      );

      await expectLater(repository.logout(), throwsA(isA<LogoutFailure>()));

      expect(session.clearCalls, AuthRepositoryImpl.logoutAttempts);
      expect(session.email, MockAuthDataSource.email);
    });

    testWidgets('a failed logout keeps the user signed in and says so', (
      tester,
    ) async {
      final session = _MemorySession()..failingClears = 1000;
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        session,
      );
      await _coldStart(tester, repository: repository);
      await _login(tester);
      expect(session.email, MockAuthDataSource.email);

      await _confirmLogout(tester);

      expect(
        find.text(
          "Couldn't log out. You are still signed in. Please try again.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-logout')), findsOneWidget);
      expect(find.byKey(const Key('login-email')), findsNothing);
      expect(session.email, MockAuthDataSource.email);
      expect(session.clearCalls, AuthRepositoryImpl.logoutAttempts);
      expect(tester.takeException(), isNull);

      session.failingClears = 0;
      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(session.email, isNull);
    });

    testWidgets('a logout that succeeds after a retry shows Login', (
      tester,
    ) async {
      final session = _MemorySession()..failingClears = 1;
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        session,
      );
      await _coldStart(tester, repository: repository);
      await _login(tester);

      await _confirmLogout(tester);

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('logout-failed')), findsNothing);
      expect(session.email, isNull);
      expect(session.clearCalls, 2);
    });
  });

  group('session save failures block authentication', () {
    testWidgets('a failed session save stays on Login and shows an error', (
      tester,
    ) async {
      final preferences = _ControllablePreferences(setStringResult: false);
      final repository = AuthRepositoryImpl(
        const MockAuthDataSource(),
        SharedPreferencesAuthSessionDataSource(
          preferences: () async => preferences,
        ),
      );

      await _coldStart(tester, repository: repository);
      await _login(tester);

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('home-page')), findsNothing);
      expect(
        find.text("Couldn't save your sign-in. Please try again."),
        findsOneWidget,
      );
      expect(preferences.values.containsKey(_key), isFalse);
      expect(await repository.restoreSession(), isNull);
    });

    testWidgets('save then logout then cold start opens Login', (tester) async {
      await _coldStart(tester);
      await _login(tester);
      expect(find.byKey(const Key('home-page')), findsOneWidget);

      await _confirmLogout(tester);
      expect(find.byKey(const Key('login-email')), findsOneWidget);

      await _terminate(tester);
      await _coldStart(tester);
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('home-page')), findsNothing);
    });
  });
}

Future<void> _confirmLogout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-profile')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('profile-logout')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('logout-confirm')));
  await tester.pumpAndSettle();
}

/// Restore that answers only when the test says so.
class _ControlledAuthRepository implements AuthRepository {
  final restore = Completer<User?>();

  @override
  Future<User?> restoreSession() => restore.future;

  @override
  Future<User> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

/// In-memory session whose next [failingClears] clears throw.
class _MemorySession implements AuthSessionLocalDataSource {
  String? email;
  int failingClears = 0;
  int clearCalls = 0;

  _MemorySession({this.email});

  @override
  Future<String?> readEmail() async => email;

  @override
  Future<void> saveEmail(String email) async => this.email = email;

  @override
  Future<void> clear() async {
    clearCalls += 1;
    if (failingClears > 0) {
      failingClears -= 1;
      throw const AuthSessionStorageException();
    }
    email = null;
  }
}

/// Controllable SharedPreferences stand-in for save/remove failure paths.
class _ControllablePreferences extends Fake implements SharedPreferences {
  final Map<String, Object> values;
  final bool setStringResult;
  final bool removeResult;
  final bool removeThrows;
  int removeCalls = 0;

  _ControllablePreferences({
    Map<String, Object>? initial,
    this.setStringResult = true,
    this.removeResult = true,
    this.removeThrows = false,
  }) : values = Map<String, Object>.from(initial ?? const {});

  @override
  dynamic get(String key) => values[key];

  @override
  String? getString(String key) {
    final value = values[key];
    return value is String ? value : null;
  }

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Set<String> getKeys() => values.keys.toSet();

  @override
  Future<bool> setString(String key, String value) async {
    if (!setStringResult) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    removeCalls += 1;
    if (removeThrows) throw StateError('remove failed');
    if (!removeResult) return false;
    values.remove(key);
    return true;
  }
}

/// Resolves the launch route the way [main] does, then starts the app.
Future<void> _coldStart(
  WidgetTester tester, {
  AuthRepository repository = _repository,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final route = (await tester.runAsync(
    () => AppRoute.initialRouteFor(RestoreSessionUseCase(repository)),
  ))!;
  await tester.pumpWidget(
    testPortalApp(authRepository: repository, initialRoute: route),
  );
  await tester.pumpAndSettle();
}

/// Drops the whole app tree, like the process being killed.
Future<void> _terminate(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

Future<String?> _savedEmail(WidgetTester tester) {
  return tester
      .runAsync(() async {
        final preferences = await SharedPreferences.getInstance();
        return preferences.getString(_key);
      })
      .then((value) => value);
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    MockAuthDataSource.email,
  );
  await tester.enterText(
    find.byKey(const Key('login-password')),
    MockAuthDataSource.password,
  );
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pump();
  await tester.pump(MockAuthDataSource.delay);
  await tester.pumpAndSettle();
}
