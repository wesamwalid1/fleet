import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/home/domain/repositories/driver_repository.dart';
import 'package:driver_portal_app/features/profile/presentation/pages/profile_page.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  _redesignStateTests();

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
      expect(_badgeField('ID', 'DR-001'), findsOneWidget);
      expect(_badgeField('Vault', 'Drivers Vault'), findsOneWidget);
      expect(_badgeBalance('2,200 EGP'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('My Balance'), findsOneWidget);
      expect(find.text('2,200 EGP'), findsNWidgets(2));
      expect(find.text('Pending Approvals'), findsOneWidget);
      expect(_pendingRowText('3'), findsOneWidget);
      expect(find.text('Transaction History'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('3,200'), findsNothing);
      expect(find.text('1,645 EGP'), findsNothing);
    },
  );

  testWidgets('rows are grouped under quick access, settings, and account', (
    tester,
  ) async {
    await _openProfile(tester);

    Rect top(String key) => tester.getRect(find.byKey(Key(key)));
    void expectIn(String group, List<String> rows) {
      for (final row in rows) {
        expect(
          find.descendant(
            of: find.byKey(Key(group)),
            matching: find.byKey(Key(row)),
          ),
          findsOneWidget,
        );
      }
    }

    expectIn('profile-quick-access', [
      'profile-my-balance',
      'profile-pending',
      'profile-history',
    ]);
    expectIn('profile-settings', ['profile-language', 'profile-dark-mode']);
    expectIn('profile-account', ['profile-logout']);

    final quick = tester.getRect(find.text('Quick access'));
    final settings = tester.getRect(find.text('Settings'));
    final account = tester.getRect(find.text('Account'));
    expect(quick.top, greaterThan(top('profile-header').bottom));
    expect(top('profile-quick-access').top, greaterThan(quick.bottom));
    expect(settings.top, greaterThan(top('profile-quick-access').bottom));
    expect(top('profile-settings').top, greaterThan(settings.bottom));
    expect(account.top, greaterThan(top('profile-settings').bottom));
    expect(top('profile-account').top, greaterThan(account.bottom));

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-my-balance')),
        matching: find.text('2,200 EGP'),
      ),
      findsOneWidget,
    );
    expect(_pendingRowText('3'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-history')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dark mode toggles and stays usable', (tester) async {
    await _openProfile(tester);

    Switch control() => tester.widget<Switch>(
      find.byKey(const Key('profile-dark-mode-switch')),
    );
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-dark-mode')),
        matching: find.byIcon(Icons.dark_mode_outlined),
      ),
      findsOneWidget,
    );
    expect(control().value, isFalse);
    expect(control().onChanged, isNotNull);

    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();
    expect(control().value, isTrue);
  });

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
    expect(find.text('Needs your decision'), findsOneWidget);
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
    expect(_badgeBalance('2,200 EGP'), findsOneWidget);
    expect(_pendingRowText('3'), findsOneWidget);
  });

  testWidgets('confirm logout returns to login and drops the session', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testPortalApp());
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('4,200 EGP'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    expect(_badgeBalance('4,200 EGP'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-my-balance')),
        matching: find.text('4,200 EGP'),
      ),
      findsOneWidget,
    );
    expect(_pendingRowText('2'), findsOneWidget);

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
    expect(find.text('2,200 EGP'), findsNWidgets(2));
    expect(find.text('4,200 EGP'), findsNothing);
    expect(find.text('3 pending'), findsOneWidget);
  });

  testWidgets('no pending approvals hides the count badge', (tester) async {
    await _openProfile(tester, seedApprovals: false);

    expect(find.byKey(const Key('profile-pending-count')), findsNothing);
    expect(_badgeBalance('2,200 EGP'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
  });

  testWidgets('arabic profile copy is localized', (tester) async {
    await _openProfile(tester, locale: const Locale('ar'));

    expect(find.text('رصيدي'), findsOneWidget);
    expect(find.text('الموافقات المعلقة'), findsOneWidget);
    expect(find.text('سجل الحركات'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('وصول سريع'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('الحساب'), findsOneWidget);
    expect(find.text('الوضع الداكن'), findsOneWidget);
    expect(_badgeField('رقم السائق', 'DR-001'), findsOneWidget);
    expect(_badgeField('الخزينة', 'خزينة السائقين'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-balance')),
        matching: find.text('الرصيد'),
      ),
      findsOneWidget,
    );
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

  testWidgets(
    'the whole profile page scrolls and its last row clears the bar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final locale in const [Locale('en'), Locale('ar')]) {
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
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              );
            },
            home: HomeScope(
              key: ValueKey(locale),
              now: () => DateTime(2026, 10, 21, 9),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('nav-profile')));
        await tester.pumpAndSettle();

        final scroll = find.byKey(const Key('profile-scroll'));
        expect(
          find.descendant(
            of: find.byType(ProfilePage),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: scroll,
            matching: find.byKey(const Key('profile-header')),
          ),
          findsOneWidget,
        );
        final position = tester
            .state<ScrollableState>(
              find.descendant(of: scroll, matching: find.byType(Scrollable)),
            )
            .position;
        expect(position.pixels, 0);
        expect(position.maxScrollExtent, greaterThan(0));

        await tester.drag(scroll, const Offset(0, -3000));
        await tester.pumpAndSettle();

        final logout = tester.getRect(find.byKey(const Key('profile-logout')));
        final bar = tester.getRect(find.byKey(const Key('portal-bottom-nav')));
        expect(logout.bottom, lessThanOrEqualTo(bar.top));
        expect(position.pixels, position.maxScrollExtent);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('profile-logout')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('logout-cancel')), findsOneWidget);
        await tester.tap(find.byKey(const Key('logout-cancel')));
        await tester.pumpAndSettle();
      }
    },
  );
}

void _redesignStateTests() {
  testWidgets('offline, the badge marks the balance unavailable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _localizedApp(
        withConnectivity(
          online: false,
          child: HomeScope(now: () => DateTime(2026, 10, 21, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(_badgeBalance('Unavailable while offline'), findsOneWidget);
    expect(find.byKey(const Key('profile-balance-amount')), findsNothing);
    expect(find.byKey(const Key('profile-pending-count')), findsNothing);
    expect(find.byKey(const Key('profile-logout')), findsOneWidget);
  });

  testWidgets('a failed load offers a retry that loads again', (tester) async {
    final repository = _FailingDriverRepository();
    await tester.pumpWidget(
      _localizedApp(
        HomeScope(now: () => DateTime(2026, 10, 21, 9), repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load your profile.'), findsOneWidget);
    final calls = repository.calls;
    await tester.tap(find.byKey(const Key('profile-retry')));
    await tester.pumpAndSettle();
    expect(repository.calls, calls + 1);
  });

  testWidgets('the Dark Mode switch is announced with its label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _openProfile(tester);

    expect(
      tester.getSemantics(find.byKey(const Key('profile-dark-mode-switch'))),
      isSemantics(label: 'Dark Mode', hasToggledState: true),
    );
    semantics.dispose();
  });

  testWidgets('the whole Dark Mode row toggles, and the switch toggles once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _openProfile(tester);
    bool value() => tester
        .widget<Switch>(find.byKey(const Key('profile-dark-mode-switch')))
        .value;

    expect(value(), isFalse);
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    expect(value(), isTrue);

    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    expect(value(), isFalse);

    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();
    expect(value(), isTrue);

    expect(
      tester.getSemantics(find.byKey(const Key('profile-dark-mode-switch'))),
      isSemantics(
        label: 'Dark Mode',
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('values swap over 180ms, and at once with reduced motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final (reduceMotion, expected) in const [
      (false, Duration(milliseconds: 180)),
      (true, Duration.zero),
    ]) {
      await tester.pumpWidget(
        _localizedApp(
          HomeScope(
            key: ValueKey(reduceMotion),
            now: () => DateTime(2026, 10, 21, 9),
          ),
          reduceMotion: reduceMotion,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-profile')));
      await tester.pumpAndSettle();

      final switchers = tester.widgetList<AnimatedSwitcher>(
        find.descendant(
          of: find.byType(ProfilePage),
          matching: find.byType(AnimatedSwitcher),
        ),
      );
      expect(switchers, isNotEmpty);
      for (final switcher in switchers) {
        expect(switcher.duration, expected);
      }
    }
  });
}

Widget _localizedApp(Widget home, {bool reduceMotion = false}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: home,
  );
}

class _FailingDriverRepository implements DriverRepository {
  int calls = 0;

  @override
  Future<Driver> getCurrentDriver() async {
    calls += 1;
    throw StateError('driver unavailable');
  }
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

/// A badge line with [label] and [value] inside the identity grid.
Finder _badgeField(String label, String value) {
  final identity = find.byKey(const Key('profile-identity'));
  return find.descendant(
    of: find.ancestor(
      of: find.descendant(of: identity, matching: find.text(label)),
      matching: find.byType(Row),
    ),
    matching: find.text(value),
  );
}

Finder _badgeBalance(String amount) {
  return find.descendant(
    of: find.byKey(const Key('profile-balance')),
    matching: find.text(amount),
  );
}

Finder _pendingRowText(String count) {
  return find.descendant(
    of: find.byKey(const Key('profile-pending')),
    matching: find.text(count),
  );
}
