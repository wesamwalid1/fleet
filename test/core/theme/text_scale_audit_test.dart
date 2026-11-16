import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

/// Finding 8 audit + regressions: priority surfaces at text scales 1.3 / 1.6.
void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final scale in const [1.3, 1.6]) {
      for (final size in const [Size(320, 700), Size(400, 900)]) {
        testWidgets(
          'portal tabs survive $locale scale=$scale size=${size.width}x${size.height}',
          (tester) async {
            await _pumpPortal(
              tester,
              locale: locale,
              size: size,
              textScale: scale,
            );

            for (final key in const [
              Key('nav-home'),
              Key('nav-approvals'),
              Key('nav-history'),
              Key('nav-profile'),
            ]) {
              await tester.tap(find.byKey(key));
              await tester.pumpAndSettle();
              _expectNoException(
                tester,
                '${key.toString()} $locale@$scale ${size.width}',
              );
            }
          },
        );
      }
    }
  }

  testWidgets(
    'approvals header pending count does not overflow at AR 1.6 on 320',
    (tester) async {
      await _pumpPortal(
        tester,
        locale: const Locale('ar'),
        size: const Size(320, 700),
        textScale: 1.6,
      );
      await tester.tap(find.byKey(const Key('nav-approvals')));
      await tester.pumpAndSettle();

      _expectNoException(tester, 'approvals header');
      expect(find.byKey(const Key('pending-count')), findsOneWidget);
      final count = tester.getRect(find.byKey(const Key('pending-count')));
      expect(count.left, greaterThanOrEqualTo(0));
      expect(count.right, lessThanOrEqualTo(320));
    },
  );

  testWidgets('home action buttons stay tappable at AR 1.6 on narrow width', (
    tester,
  ) async {
    await _pumpPortal(
      tester,
      locale: const Locale('ar'),
      size: const Size(320, 700),
      textScale: 1.6,
    );
    for (final key in const [
      'send-cash',
      'record-expense',
      'request-cash',
      'withdraw',
    ]) {
      final finder = find.byKey(Key(key));
      expect(finder, findsOneWidget, reason: key);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      expect(finder.hitTestable(), findsOneWidget, reason: '$key hit-testable');
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(48), reason: '$key height');
    }
    _expectNoException(tester, 'home actions AR@1.6');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final scale in const [1.3, 1.6]) {
      testWidgets('login survives $locale scale=$scale on 320', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(testPortalApp(locale: locale));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('login-email')), findsOneWidget);
        _expectNoException(tester, 'login $locale@$scale');
      });
    }
  }
}

void _expectNoException(WidgetTester tester, String reason) {
  expect(tester.takeException(), isNull, reason: reason);
}

Future<void> _pumpPortal(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
  required double textScale,
}) async {
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
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: HomeScope(
        now: () => DateTime(2026, 10, 20, 9),
        seedApprovals: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
  _expectNoException(tester, 'initial portal $locale@$textScale');
}
