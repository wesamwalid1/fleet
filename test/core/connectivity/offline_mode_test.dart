import 'package:driver_portal_app/core/connectivity/domain/network_status.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/domain/theme_repository.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_bloc.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_event.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home hides financial figures and blocks actions offline', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      networkMonitor: FakeNetworkInterfaceMonitor(hasInterface: false),
      internetReachability: FakeInternetReachability(reachable: false),
    );

    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.byKey(const Key('home-offline-finance')), findsWidgets);
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(find.byKey(const Key('home-pending-count')), findsNothing);
    expect(find.byKey(const Key('home-offline-actions-hint')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('send-cash')));
    await tester.tap(find.byKey(const Key('send-cash')));
    await tester.pump();
    expect(
      find.text('An Internet connection is required for this action.'),
      findsAtLeastNWidgets(1),
    );
    expect(find.byKey(const Key('send-cash-submit')), findsNothing);
  });

  testWidgets('approvals and history show unavailable offline', (tester) async {
    await _pumpShell(
      tester,
      networkMonitor: FakeNetworkInterfaceMonitor(hasInterface: false),
      internetReachability: FakeInternetReachability(reachable: false),
    );

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline-unavailable')), findsOneWidget);
    expect(find.byKey(const Key('approvals-empty')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline-unavailable')), findsOneWidget);
    expect(find.byKey(const Key('history-empty')), findsNothing);
  });

  testWidgets('login requires Internet and does not authenticate offline', (
    tester,
  ) async {
    await tester.pumpWidget(testPortalApp(online: false));
    await tester.pumpAndSettle();

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

    expect(find.byKey(const Key('login-offline-notice')), findsOneWidget);
    expect(find.text('Connect to the Internet to sign in.'), findsOneWidget);
    expect(find.byKey(const Key('home-page')), findsNothing);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets('profile dark mode works offline and persists', (tester) async {
    final themeRepository = _MemoryThemeRepository();
    await _pumpShell(
      tester,
      networkMonitor: FakeNetworkInterfaceMonitor(hasInterface: false),
      internetReachability: FakeInternetReachability(reachable: false),
      themeRepository: themeRepository,
    );
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.byKey(const Key('profile-balance-amount')), findsNothing);
    expect(find.text('Ahmed Ali'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();
    expect(themeRepository.saved, ThemeMode.dark);
    expect(find.byKey(const Key('profile-logout')), findsOneWidget);
  });

  testWidgets('retry and reconnection clear the banner and restore data', (
    tester,
  ) async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: false);
    final reachability = FakeInternetReachability(reachable: false);
    await _pumpShell(
      tester,
      networkMonitor: monitor,
      internetReachability: reachability,
    );

    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.byKey(const Key('home-balance')), findsNothing);

    monitor.setHasInterface(true);
    reachability.reachable = true;
    await tester.tap(find.byKey(const Key('offline-banner-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline-banner')), findsNothing);
    expect(find.byKey(const Key('home-balance')), findsOneWidget);
    expect(find.textContaining('2,200'), findsWidgets);
  });

  testWidgets('no financial operations are queued while offline', (
    tester,
  ) async {
    MockCashLedger? ledger;
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: false);
    final reachability = FakeInternetReachability(reachable: false);

    await tester.pumpWidget(
      withConnectivity(
        networkMonitor: monitor,
        internetReachability: reachability,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(
            now: _fixedNow,
            configureLedger: (value) => ledger ??= value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = ledger!.balanceOf(MockCashLedger.senderId);
    await tester.ensureVisible(find.byKey(const Key('send-cash')));
    await tester.tap(find.byKey(const Key('send-cash')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('record-expense')));
    await tester.tap(find.byKey(const Key('record-expense')));
    await tester.pumpAndSettle();

    expect(ledger!.balanceOf(MockCashLedger.senderId), before);
    expect(find.byKey(const Key('send-cash-submit')), findsNothing);
    expect(find.byKey(const Key('expense-submit')), findsNothing);

    monitor.setHasInterface(true);
    reachability.reachable = true;
    await tester.tap(find.byKey(const Key('offline-banner-retry')));
    await tester.pumpAndSettle();

    expect(ledger!.balanceOf(MockCashLedger.senderId), before);
  });

  test('network status helpers distinguish offline and unreachable', () {
    expect(NetworkStatus.offline.isUnavailable, isTrue);
    expect(NetworkStatus.unreachable.isUnavailable, isTrue);
    expect(NetworkStatus.offline.blocksOnlineWork, isTrue);
    expect(NetworkStatus.checking.blocksOnlineWork, isTrue);
    expect(NetworkStatus.online.isOnline, isTrue);
    expect(NetworkStatus.checking.isOnline, isFalse);
  });

  testWidgets(
    'approvals stay listed while checking but approval actions are locked',
    (tester) async {
      final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
      final reachability = GateInternetReachability();
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        withConnectivity(
          networkMonitor: monitor,
          internetReachability: reachability,
          child: BlocProvider(
            create: (_) =>
                ThemeBloc(_MemoryThemeRepository())..add(const ThemeStarted()),
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: HomeScope(now: _fixedNow),
            ),
          ),
        ),
      );
      // Avoid pumpAndSettle: checking keeps the banner retry spinner animating.
      await _pumpUntil(tester, find.byKey(const Key('nav-approvals')));

      expect(find.byKey(const Key('offline-unavailable')), findsNothing);
      expect(find.byKey(const Key('offline-banner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-approvals')));
      await _pumpUntil(
        tester,
        find.byKey(const Key('approval-action-DSB-2025-0441')),
      );

      expect(find.byKey(const Key('offline-unavailable')), findsNothing);
      expect(find.text('Action Required'), findsOneWidget);
      final action = find.byKey(const Key('approval-action-DSB-2025-0441'));
      expect(tester.widget<FilledButton>(action).onPressed, isNull);

      await tester.tap(action);
      await tester.pump();
      expect(find.text('Approve Cash Receipt'), findsNothing);

      reachability.complete(reachable: true);
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

DateTime _fixedNow() => DateTime(2026, 10, 20, 9);

Future<void> _pumpShell(
  WidgetTester tester, {
  required FakeNetworkInterfaceMonitor networkMonitor,
  required FakeInternetReachability internetReachability,
  ThemeRepository? themeRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    withConnectivity(
      networkMonitor: networkMonitor,
      internetReachability: internetReachability,
      child: BlocProvider(
        create: (_) =>
            ThemeBloc(themeRepository ?? _MemoryThemeRepository())
              ..add(const ThemeStarted()),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(now: _fixedNow),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MemoryThemeRepository implements ThemeRepository {
  ThemeMode? saved;

  @override
  Future<ThemeMode?> read() async => saved;

  @override
  Future<void> save(ThemeMode mode) async {
    saved = mode;
  }
}
