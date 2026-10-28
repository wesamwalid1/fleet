import 'package:driver_portal_app/core/theme/domain/theme_repository.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  testWidgets('toggling dark mode updates MaterialApp brightness immediately', (
    tester,
  ) async {
    final themeRepository = _MemoryThemeRepository();
    await _pumpPortal(tester, themeRepository: themeRepository);
    await _login(tester);
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byKey(const Key('profile-scroll'))))
          .brightness,
      Brightness.light,
    );

    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();

    expect(themeRepository.saved, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byKey(const Key('profile-scroll'))))
          .brightness,
      Brightness.dark,
    );
    expect(find.byKey(const Key('profile-logout')), findsOneWidget);
  });

  testWidgets('a saved dark theme is restored on startup', (tester) async {
    final themeRepository = _MemoryThemeRepository(ThemeMode.dark);
    await _pumpPortal(tester, themeRepository: themeRepository);
    await _login(tester);

    expect(
      Theme.of(tester.element(find.byKey(const Key('home-page')))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('arabic profile can toggle dark mode in RTL', (tester) async {
    final themeRepository = _MemoryThemeRepository();
    await _pumpPortal(
      tester,
      themeRepository: themeRepository,
      locale: const Locale('ar'),
    );
    await _login(tester);
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.text('الوضع الداكن'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('profile-name')))),
      TextDirection.rtl,
    );
    expect(
      Theme.of(tester.element(find.byKey(const Key('profile-scroll'))))
          .brightness,
      Brightness.light,
    );

    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();

    expect(themeRepository.saved, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byKey(const Key('profile-scroll'))))
          .brightness,
      Brightness.dark,
    );
    expect(
      Directionality.of(tester.element(find.byKey(const Key('profile-name')))),
      TextDirection.rtl,
    );
  });
}

Future<void> _pumpPortal(
  WidgetTester tester, {
  required ThemeRepository themeRepository,
  Locale? locale,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    DriverPortalApp(
      locale: locale,
      themeRepository: themeRepository,
      networkMonitor: FakeNetworkInterfaceMonitor(),
      internetReachability: FakeInternetReachability(),
    ),
  );
  await tester.pumpAndSettle();
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

class _MemoryThemeRepository implements ThemeRepository {
  ThemeMode? saved;

  _MemoryThemeRepository([this.saved]);

  @override
  Future<ThemeMode?> read() async => saved;

  @override
  Future<void> save(ThemeMode mode) async {
    saved = mode;
  }
}
