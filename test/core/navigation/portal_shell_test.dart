import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/app_colors.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('swiping between tabs updates the page and the bottom nav', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('send-cash')), findsOneWidget);
    expect(find.byKey(const Key('pending-count')), findsNothing);
    expect(find.byKey(const Key('history-title')), findsNothing);
    expect(find.byKey(const Key('profile-header')), findsNothing);
    _expectSelected(tester, const Key('nav-home'));

    await _swipeTabs(tester, forward: true);

    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    expect(find.byKey(const Key('send-cash')), findsNothing);
    _expectSelected(tester, const Key('nav-approvals'));
    _expectUnselected(tester, const Key('nav-home'));

    await _swipeTabs(tester, forward: true);

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    _expectSelected(tester, const Key('nav-history'));

    await _swipeTabs(tester, forward: true);

    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    _expectSelected(tester, const Key('nav-profile'));

    await _swipeTabs(tester, forward: true);

    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    _expectSelected(tester, const Key('nav-profile'));

    await _swipeTabs(tester, forward: false);

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    _expectSelected(tester, const Key('nav-history'));
  });

  testWidgets('a swipe settles through a horizontal transition', (
    tester,
  ) async {
    await _pump(tester);
    final viewport = _tabScrollable(tester).position.viewportDimension;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('portal-tabs'))),
    );
    await gesture.moveBy(Offset(-viewport * 0.6, 0));
    await gesture.up();
    await tester.pump();

    final position = _tabScrollable(tester).position;
    expect(position.activity?.isScrolling, isTrue);
    expect(position.pixels, greaterThan(0));
    expect(position.pixels, lessThan(viewport));

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    expect(position.activity?.isScrolling, isFalse);
    _expectSelected(tester, const Key('nav-approvals'));
  });

  testWidgets('a bottom nav tap jumps without passing through other tabs', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pump();

    final position = _tabScrollable(tester).position;
    expect(position.pixels, closeTo(position.maxScrollExtent, 0.5));
    expect(position.activity?.isScrolling, isFalse);
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    expect(find.byKey(const Key('history-title')), findsNothing);
    expect(find.byKey(const Key('pending-count')), findsNothing);
    expect(find.byKey(const Key('send-cash')), findsNothing);
    _expectSelected(tester, const Key('nav-profile'));
    _expectUnselected(tester, const Key('nav-home'));
  });

  testWidgets('tapping a tab stays synchronized with swipe navigation', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    _expectSelected(tester, const Key('nav-history'));
    _expectUnselected(tester, const Key('nav-home'));

    await _swipeTabs(tester, forward: false);

    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    _expectSelected(tester, const Key('nav-approvals'));

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('send-cash')), findsOneWidget);
    _expectSelected(tester, const Key('nav-home'));
    _expectUnselected(tester, const Key('nav-approvals'));
  });

  testWidgets('arabic swipe direction follows the tab order', (tester) async {
    await _pump(tester, const Locale('ar'));
    expect(
      Directionality.of(tester.element(find.byKey(const Key('portal-tabs')))),
      TextDirection.rtl,
    );
    _expectSelected(tester, const Key('nav-home'));

    await _swipeTabs(tester, forward: true);

    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    _expectSelected(tester, const Key('nav-approvals'));

    await _swipeTabs(tester, forward: false);

    expect(find.byKey(const Key('send-cash')), findsOneWidget);
    _expectSelected(tester, const Key('nav-home'));

    await _swipeTabs(tester, forward: false);

    expect(find.byKey(const Key('send-cash')), findsOneWidget);
    _expectSelected(tester, const Key('nav-home'));
  });

  testWidgets('opening the approvals filter sheet does not change the tab', (
    tester,
  ) async {
    await _pump(tester, const Locale('en'), const Size(320, 700));
    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approvals-search')), findsOneWidget);
    await tester.tap(find.byKey(const Key('approvals-filter-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approval-filter-vault')), findsOneWidget);
    await tester.tap(find.byKey(const Key('approvals-filter-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approvals-search')), findsOneWidget);
    expect(find.byKey(const Key('history-title')), findsNothing);
    _expectSelected(tester, const Key('nav-approvals'));
  });

  testWidgets('send cash blocks tab swipes until the sheet closes', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('send-cash')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.drag(
      find.byKey(const Key('send-cash-amount')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('send-cash-amount')), findsOneWidget);
    expect(find.byKey(const Key('pending-count')), findsNothing);
    _expectSelected(tester, const Key('nav-home'));

    await tester.ensureVisible(find.byKey(const Key('send-cash-cancel')));
    await tester.tap(find.byKey(const Key('send-cash-cancel')));
    await tester.pumpAndSettle();

    await _swipeTabs(tester, forward: true);
    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    _expectSelected(tester, const Key('nav-approvals'));
  });

  testWidgets('record expense blocks tab swipes through confirmation', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('record-expense')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Confirm Expense'), findsNothing);

    await _selectTrip(tester, 'trip-2026-0927');

    await _selectSettlement(tester, 'fuel');
    await tester.ensureVisible(find.byKey(const Key('expense-amount')));
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pump();

    expect(find.text('Confirm Expense'), findsOneWidget);
    await tester.drag(find.text('Confirm Expense'), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Expense'), findsOneWidget);
    expect(find.byKey(const Key('history-title')), findsNothing);
    _expectSelected(tester, const Key('nav-home'));

    await tester.ensureVisible(find.byKey(const Key('expense-back')));
    await tester.tap(find.byKey(const Key('expense-back')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('expense-close')));
    await tester.tap(find.byKey(const Key('expense-close')));
    await tester.pumpAndSettle();

    await _swipeTabs(tester, forward: true);
    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    _expectSelected(tester, const Key('nav-approvals'));
  });

  testWidgets('every tab tap moves the pill to that tab only', (tester) async {
    await _pump(tester);
    const keys = [
      Key('nav-home'),
      Key('nav-approvals'),
      Key('nav-history'),
      Key('nav-profile'),
    ];
    for (final target in [3, 1, 2, 0]) {
      await tester.tap(find.byKey(keys[target]));
      await tester.pumpAndSettle();
      for (var i = 0; i < keys.length; i++) {
        if (i == target) {
          _expectSelected(tester, keys[i]);
        } else {
          _expectUnselected(tester, keys[i]);
        }
      }
    }
    expect(find.byKey(const Key('send-cash')), findsOneWidget);
  });

  testWidgets('the approvals badge follows the pending count', (tester) async {
    await _pump(tester, const Locale('en'), const Size(400, 1400));
    expect(_badgeText(tester), '3');
    final icon = tester.getRect(
      find.descendant(
        of: find.byKey(const Key('nav-approvals')),
        matching: find.byType(Icon),
      ),
    );
    final badge = tester.getRect(find.byKey(const Key('nav-approvals-dot')));
    expect(badge.center.dy, lessThan(icon.center.dy));
    expect(badge.center.dx, greaterThan(icon.center.dx));

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(const Key('nav-approvals')));
    final iconBefore = tester.getRect(
      find.descendant(
        of: find.byKey(const Key('nav-approvals')),
        matching: find.byType(Icon),
      ),
    );

    var remaining = 3;
    for (final (id, action) in const [
      ('DSB-2025-0441', 'approval-approve'),
      ('TRF-2025-0123', 'approval-approve'),
      ('RE-2026-1041', 'approval-confirm'),
    ]) {
      await tester.ensureVisible(find.byKey(Key('approval-action-$id')));
      await tester.tap(find.byKey(Key('approval-action-$id')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(Key(action)));
      await tester.pumpAndSettle();
      remaining -= 1;
      if (remaining > 0) expect(_badgeText(tester), '$remaining');
    }

    expect(find.byKey(const Key('nav-approvals-dot')), findsNothing);
    expect(tester.getRect(find.byKey(const Key('nav-approvals'))), before);
    expect(
      tester.getRect(
        find.descendant(
          of: find.byKey(const Key('nav-approvals')),
          matching: find.byType(Icon),
        ),
      ),
      iconBefore,
    );
  });

  testWidgets('content runs under the bar and still clears it at the end', (
    tester,
  ) async {
    await _pump(tester, const Locale('en'), const Size(400, 800));
    final tabs = tester.getRect(find.byKey(const Key('portal-tabs')));
    final bar = tester.getRect(find.byKey(const Key('portal-bottom-nav')));
    expect(tabs.bottom, 800);
    expect(bar.top, lessThan(tabs.bottom));

    for (final (tab, last) in const [
      ('nav-approvals', 'approval-card-TRF-2025-0090'),
      ('nav-history', 'history-entry-DSB-2025-0301'),
      ('nav-profile', 'profile-logout'),
    ]) {
      await tester.tap(find.byKey(Key(tab)));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      final row = tester.getRect(find.byKey(Key(last)));
      expect(row.bottom, lessThanOrEqualTo(bar.top), reason: tab);
    }
  });

  testWidgets('no pending approvals means no dot', (tester) async {
    await _pump(tester, const Locale('en'), const Size(400, 900), false);
    expect(find.byKey(const Key('nav-approvals-dot')), findsNothing);
  });

  testWidgets('arabic mirrors the tab order', (tester) async {
    await _pump(tester, const Locale('ar'));
    final home = tester.getRect(find.byKey(const Key('nav-home')));
    final profile = tester.getRect(find.byKey(const Key('nav-profile')));
    expect(home.left, greaterThan(profile.right));
    expect(find.byTooltip('الرئيسية'), findsOneWidget);
    expect(find.byTooltip('الموافقات'), findsOneWidget);
    _expectSelected(tester, const Key('nav-home'));
  });

  testWidgets('the floating bar fits a narrow screen with large text', (
    tester,
  ) async {
    for (final (locale, scale) in const [
      (Locale('en'), 1.6),
      (Locale('ar'), 1.3),
    ]) {
      await _pump(tester, locale, const Size(320, 700), true, scale);
      final bar = tester.getRect(find.byKey(const Key('portal-bottom-nav')));
      expect(bar.left, greaterThanOrEqualTo(0));
      expect(bar.right, lessThanOrEqualTo(320));
      expect(bar.bottom, lessThanOrEqualTo(700));
      expect(
        (tester.takeException() as FlutterError?)?.toStringDeep(),
        isNull,
        reason: 'home $locale',
      );
      for (final key in const [
        'nav-approvals',
        'nav-history',
        'nav-profile',
        'nav-home',
      ]) {
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(
          (tester.takeException() as FlutterError?)?.toStringDeep(),
          isNull,
          reason: '$key $locale',
        );
        _expectSelected(tester, Key(key));
        final item = tester.getRect(find.byKey(Key(key)));
        final backdrop = tester.getRect(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect(backdrop.left, greaterThanOrEqualTo(item.left));
        expect(backdrop.right, lessThanOrEqualTo(item.right));
      }
      final widths = [
        for (final key in const [
          'nav-home',
          'nav-approvals',
          'nav-history',
          'nav-profile',
        ])
          tester.getSize(find.byKey(Key(key))).width,
      ];
      expect(widths.toSet(), hasLength(1));
    }
  });
}

Future<void> _pump(
  WidgetTester tester, [
  Locale locale = const Locale('en'),
  Size size = const Size(400, 900),
  bool seedApprovals = true,
  double textScale = 1,
]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: HomeScope(
        now: () => DateTime(2026, 10, 20, 9),
        seedApprovals: seedApprovals,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _swipeTabs(WidgetTester tester, {required bool forward}) async {
  final viewport = _tabScrollable(tester).position.viewportDimension;
  final direction = Directionality.of(
    tester.element(find.byKey(const Key('portal-tabs'))),
  );
  final towardNext = direction == TextDirection.ltr ? -1.0 : 1.0;
  await tester.drag(
    find.byKey(const Key('portal-tabs')),
    Offset((forward ? towardNext : -towardNext) * viewport * 0.6, 0),
  );
  await tester.pumpAndSettle();
}

ScrollableState _tabScrollable(WidgetTester tester) {
  return tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .firstWhere(
        (state) =>
            state.position.axis == Axis.horizontal &&
            state.position.maxScrollExtent >= state.position.viewportDimension,
      );
}

void _expectSelected(WidgetTester tester, Key key) {
  expect(_navIcon(tester, key).color, AppColors.primary);
  expect(_backdropColor(tester, key)?.a, greaterThan(0));
  expect(
    find.descendant(
      of: find.byKey(key),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text && !RegExp(r'^\d+\+?$').hasMatch(widget.data ?? ''),
      ),
    ),
    findsNothing,
  );
}

void _expectUnselected(WidgetTester tester, Key key) {
  expect(_navIcon(tester, key).color, _inactiveNav);
  expect(_backdropColor(tester, key)?.a, 0);
}

final _inactiveNav = Color.lerp(AppColors.title, AppColors.muted, 0.2);

Icon _navIcon(WidgetTester tester, Key key) {
  return tester.widget<Icon>(
    find.descendant(of: find.byKey(key), matching: find.byType(Icon)).first,
  );
}

Color? _backdropColor(WidgetTester tester, Key key) {
  final backdrop = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (backdrop.decoration as BoxDecoration?)?.color;
}

String? _badgeText(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const Key('nav-approvals-dot')),
          matching: find.byType(Text),
        ),
      )
      .data;
}

Future<void> _selectTrip(WidgetTester tester, String id) async {
  await tester.ensureVisible(find.byKey(const Key('expense-trip')));
  await tester.tap(find.byKey(const Key('expense-trip')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.ensureVisible(find.byKey(Key('expense-trip-$id')));
  await tester.tap(find.byKey(Key('expense-trip-$id')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _selectSettlement(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.byKey(const Key('expense-settlement')));
  await tester.tap(find.byKey(const Key('expense-settlement')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.ensureVisible(find.byKey(Key('expense-settlement-$name')));
  await tester.tap(find.byKey(Key('expense-settlement-$name')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
