import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/haptic_log.dart';

void main() {
  testWidgets('different-tab tap triggers selection once', (tester) async {
    final log = HapticLog.install();
    await _pump(tester);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pump();

    log.expectOnly(['HapticFeedbackType.selectionClick']);
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
  });

  testWidgets('same-tab reselect triggers no haptic and scrolls to top', (
    tester,
  ) async {
    final log = HapticLog.install();
    await _pump(tester);

    final homeScroll = tester
        .widget<CustomScrollView>(
          find.descendant(
            of: find.byKey(const Key('home-page')),
            matching: find.byType(CustomScrollView),
          ),
        )
        .controller!;
    await tester.drag(
      find.descendant(
        of: find.byKey(const Key('home-page')),
        matching: find.byType(CustomScrollView),
      ),
      const Offset(0, -2400),
    );
    await tester.pumpAndSettle();
    expect(homeScroll.offset, greaterThan(0));

    log.clear();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();

    log.expectNone();
    expect(homeScroll.offset, 0);
  });

  testWidgets('swipe-only tab changes trigger no haptic', (tester) async {
    final log = HapticLog.install();
    await _pump(tester);

    final viewport = _tabScrollable(tester).position.viewportDimension;
    await tester.drag(
      find.byKey(const Key('portal-tabs')),
      Offset(-viewport * 0.6, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pending-count')), findsOneWidget);
    log.expectNone();
  });
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
      home: HomeScope(now: () => DateTime(2026, 10, 20, 9)),
    ),
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
