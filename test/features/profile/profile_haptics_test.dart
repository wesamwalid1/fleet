import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/haptic_log.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('dark-mode actual change triggers one selection haptic', (
    tester,
  ) async {
    final log = HapticLog.install();
    await _openProfile(tester);

    // Clear the tab-selection haptic from navigating to Profile.
    log.clear();

    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();

    log.expectOnly(['HapticFeedbackType.selectionClick']);
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('profile-dark-mode-switch')))
          .value,
      isTrue,
    );
  });

  testWidgets('dark-mode row and switch share one haptic per change', (
    tester,
  ) async {
    final log = HapticLog.install();
    await _openProfile(tester);
    log.clear();

    await tester.tap(find.byKey(const Key('profile-dark-mode')));
    await tester.pumpAndSettle();
    log.expectOnly(['HapticFeedbackType.selectionClick']);

    log.clear();
    await tester.tap(find.byKey(const Key('profile-dark-mode-switch')));
    await tester.pumpAndSettle();
    log.expectOnly(['HapticFeedbackType.selectionClick']);
  });
}

Future<void> _openProfile(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
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
      home: HomeScope(now: () => DateTime(2026, 10, 21, 9)),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-profile')));
  await tester.pumpAndSettle();
}
