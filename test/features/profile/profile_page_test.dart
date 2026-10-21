import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:driver_portal_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'profile shows the signed-in driver, balance, and pending count',
    (tester) async {
      await _openProfile(tester);

      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('profile-header'))).width,
        400,
      );
      expect(find.text('Ahmed Ali'), findsOneWidget);
      expect(find.text('AA'), findsOneWidget);
      expect(find.text('DR-001 · Drivers Vault'), findsOneWidget);
      expect(find.text('Balance: 2,200 EGP'), findsOneWidget);
      expect(find.text('My Balance'), findsOneWidget);
      expect(find.text('2,200 EGP'), findsOneWidget);
      expect(find.text('Pending Approvals'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Transaction History'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('3,200'), findsNothing);
      expect(find.text('1,645 EGP'), findsNothing);
    },
  );

  testWidgets('profile rows open the existing screens', (tester) async {
    await _openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-my-balance')));
    await tester.pumpAndSettle();
    expect(find.text('Send Cash'), findsOneWidget);
    expect(find.byKey(const Key('profile-identity')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-pending')));
    await tester.pumpAndSettle();
    expect(find.text('Action Required'), findsOneWidget);
    expect(find.byKey(const Key('profile-my-balance')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.text('2,200 EGP'), findsNothing);
  });

  testWidgets('cancel closes logout and keeps the session', (tester) async {
    await _openProfile(tester);
    await tester.tap(find.byKey(const Key('profile-logout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('logout-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsNothing);
    expect(find.text('Welcome back!'), findsNothing);
    expect(find.text('Balance: 2,200 EGP'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('confirm logout returns to login and drops the session', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const DriverPortalApp());
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();
    expect(find.text('4,200 EGP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Balance: 4,200 EGP'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-logout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsNothing);
    expect(find.text('4,200 EGP'), findsNothing);
    final popped = await tester
        .state<NavigatorState>(find.byType(Navigator))
        .maybePop();
    expect(popped, isFalse);
    expect(find.text('Welcome back!'), findsOneWidget);

    await _login(tester);
    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('4,200 EGP'), findsNothing);
    expect(find.text('3 pending'), findsOneWidget);
  });

  testWidgets('no pending approvals hides the count badge', (tester) async {
    await _openProfile(tester, seedApprovals: false);

    expect(find.byKey(const Key('profile-pending-count')), findsNothing);
    expect(find.text('Balance: 2,200 EGP'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
  });

  testWidgets('arabic profile copy is localized', (tester) async {
    await _openProfile(tester, locale: const Locale('ar'));

    expect(find.text('رصيدي'), findsOneWidget);
    expect(find.text('الموافقات المعلقة'), findsOneWidget);
    expect(find.text('سجل الحركات'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('DR-001 · خزينة السائقين'), findsOneWidget);
    expect(find.textContaining('الرصيد:'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('profile-name')))),
      TextDirection.rtl,
    );
  });

  testWidgets('a narrow profile screen does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          );
        },
        home: HomeScope(now: () => DateTime(2026, 10, 21, 9)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openProfile(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool seedApprovals = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScope(
        now: () => DateTime(2026, 10, 21, 9),
        seedApprovals: seedApprovals,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-profile')));
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
