import 'dart:async';

import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a new session hides both finance groups', (tester) async {
    await _pump(tester);

    expect(_text(tester, 'home-total-balance'), '•••• EGP');
    expect(_text(tester, 'home-balance'), '•••• EGP');
    expect(_text(tester, 'home-frozen-balance'), '•••• EGP');
    expect(_text(tester, 'home-remaining'), '•••• EGP');
    expect(_text(tester, 'home-max-limit'), '•••• EGP');
    expect(_text(tester, 'home-charge'), '•••• EGP');
    expect(_text(tester, 'home-limit-used'), '••••');
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Remaining Limit'), findsOneWidget);
    expect(find.text('Charge'), findsOneWidget);
    expect(_tooltip(tester, 'home-balance-visibility'), 'Show balance');
    expect(_tooltip(tester, 'home-limit-visibility'), 'Show limit');
    expect(find.byKey(const Key('home-charge-progress')), findsOneWidget);
  });

  testWidgets('balance toggle reveals only the balance group and Profile', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('home-balance-visibility')));
    await tester.pumpAndSettle();

    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(_text(tester, 'home-frozen-balance'), isNot('•••• EGP'));
    expect(_text(tester, 'home-total-balance'), isNot('•••• EGP'));
    expect(_text(tester, 'home-charge'), '•••• EGP');
    expect(_text(tester, 'home-remaining'), '•••• EGP');
    expect(_text(tester, 'home-max-limit'), '•••• EGP');
    expect(_text(tester, 'home-limit-used'), '••••');

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'profile-balance-amount'), '2,200 EGP');
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-balance')),
        matching: find.text('2,200 EGP'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-balance-visibility')), findsNothing);
  });

  testWidgets('limit toggle reveals only the limit figures', (tester) async {
    await _pump(tester);
    final before = _meter(tester);

    await tester.tap(find.byKey(const Key('home-limit-visibility')));
    await tester.pump();

    expect(_meter(tester), before);
    expect(_text(tester, 'home-remaining'), '1,800 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-limit-used'), contains('64'));
    expect(_text(tester, 'home-balance'), '•••• EGP');
    expect(_text(tester, 'home-total-balance'), '•••• EGP');
  });

  testWidgets('tab changes keep both visibility choices', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('home-balance-visibility')));
    await tester.tap(find.byKey(const Key('home-limit-visibility')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();

    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_meter(tester), closeTo(0.64, 0.02));

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'profile-balance-amount'), '2,200 EGP');
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(_tooltip(tester, 'home-balance-visibility'), 'Hide balance');
    expect(_tooltip(tester, 'home-limit-visibility'), 'Hide limit');
  });

  testWidgets('a pull keeps the choice and the 800ms skeleton', (tester) async {
    await _pump(tester, clock: true);
    await tester.tap(find.byKey(const Key('home-balance-visibility')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'home-balance'), '2,200 EGP');

    final pull = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    var sawSkeleton = false;
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byKey(const Key('balance-loading')).evaluate().isNotEmpty) {
        sawSkeleton = true;
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 400));
    final stillLoading =
        find.byKey(const Key('balance-loading')).evaluate().isNotEmpty;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await pull;
    await tester.pumpAndSettle();
    expect(sawSkeleton, isTrue);
    expect(stillLoading, isTrue);

    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(_tooltip(tester, 'home-balance-visibility'), 'Hide balance');
    expect(_text(tester, 'home-charge'), '•••• EGP');
  });

  testWidgets('signing in again starts both groups hidden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testPortalApp());
    await tester.pumpAndSettle();
    await _login(tester);
    await tester.tap(find.byKey(const Key('home-balance-visibility')));
    await tester.tap(find.byKey(const Key('home-limit-visibility')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'home-balance'), isNot('•••• EGP'));

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-logout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    await _login(tester);
    expect(_text(tester, 'home-balance'), '•••• EGP');
    expect(_text(tester, 'home-charge'), '•••• EGP');
    expect(_tooltip(tester, 'home-balance-visibility'), 'Show balance');
    expect(_tooltip(tester, 'home-limit-visibility'), 'Show limit');
  });

  testWidgets('the controls sit at the end and announce in both languages', (
    tester,
  ) async {
    await _pump(tester);
    _expectEndAligned(tester, 'home-finance-card', 'home-balance-visibility');
    _expectEndAligned(tester, 'home-charge-progress', 'home-limit-visibility');
    expect(_tooltip(tester, 'home-balance-visibility'), 'Show balance');
    expect(_tooltip(tester, 'home-limit-visibility'), 'Show limit');

    await _pump(tester, locale: const Locale('ar'));
    expect(_tooltip(tester, 'home-balance-visibility'), 'إظهار الرصيد');
    expect(_tooltip(tester, 'home-limit-visibility'), 'إظهار الحد');
    _expectEndAligned(
      tester,
      'home-finance-card',
      'home-balance-visibility',
      rtl: true,
    );
  });

  testWidgets('a loading card has no visibility control', (tester) async {
    await _pump(tester, finance: _PendingFinance());
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-balance-visibility')), findsNothing);
    expect(find.byKey(const Key('home-limit-visibility')), findsNothing);
  });

  testWidgets('an error card has no visibility control', (tester) async {
    await _pump(tester, finance: _FailingFinance());
    expect(find.byKey(const Key('balance-error')), findsOneWidget);
    expect(find.byKey(const Key('home-balance-visibility')), findsNothing);
    expect(find.byKey(const Key('home-limit-visibility')), findsNothing);
  });

  testWidgets('an offline card has no visibility control', (tester) async {
    await _pump(tester, online: false);
    expect(find.byKey(const Key('home-offline-finance')), findsWidgets);
    expect(find.byKey(const Key('home-balance-visibility')), findsNothing);
    expect(find.byKey(const Key('home-limit-visibility')), findsNothing);
  });

  testWidgets('a hidden limit bar does not expose its percentage', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _pump(tester);
      expect(find.bySemanticsLabel(RegExp(r'64')), findsNothing);
      expect(_text(tester, 'home-limit-used'), '••••');
      expect(find.byKey(const Key('home-charge-progress')), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  FinanceRepository? finance,
  bool clock = false,
  bool online = true,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    withConnectivity(
      online: online,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScope(
          now: () => DateTime(2026, 10, 20, 9),
          loadingNow: clock ? () => tester.binding.clock.now() : null,
          financeRepository: finance,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
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

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

String _tooltip(WidgetTester tester, String key) {
  return tester.widget<IconButton>(find.byKey(Key(key))).tooltip!;
}

double _meter(WidgetTester tester) {
  return tester
      .widget<LinearProgressIndicator>(
        find.byKey(const Key('home-charge-progress')),
      )
      .value!;
}

void _expectEndAligned(
  WidgetTester tester,
  String cardKey,
  String buttonKey, {
  bool rtl = false,
}) {
  final button = tester.getCenter(find.byKey(Key(buttonKey)));
  final card = tester.getRect(find.byKey(Key(cardKey)));
  if (rtl) {
    expect(button.dx, lessThan(card.center.dx));
  } else {
    expect(button.dx, greaterThan(card.center.dx));
  }
}

class _PendingFinance implements FinanceRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() =>
      Completer<FinancialSummary>().future;
}

class _FailingFinance implements FinanceRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    throw StateError('unavailable');
  }
}
