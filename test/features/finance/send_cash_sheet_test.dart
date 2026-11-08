import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/send_cash_success.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recipient list excludes sender and enables continue on select', (
    tester,
  ) async {
    await _openFlow(tester);

    expect(find.byKey(const Key('send-cash-flow')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-002')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-004')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-001')), findsNothing);

    expect(
      tester.getTopLeft(find.byKey(const Key('send-cash-driver-DR-003'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('send-cash-driver-DR-002'))).dy,
      ),
    );

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('send-cash-continue')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('send-cash-driver-DR-003')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('send-cash-continue')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('recipient search matches English, Arabic, ID, and case', (
    tester,
  ) async {
    await _openFlow(tester);

    await tester.enterText(find.byKey(const Key('send-cash-search')), 'khaled');
    await tester.pump();
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-002')), findsNothing);
    expect(find.byKey(const Key('send-cash-driver-DR-004')), findsNothing);

    await tester.enterText(find.byKey(const Key('send-cash-search')), 'خالد');
    await tester.pump();
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-002')), findsNothing);

    await tester.enterText(find.byKey(const Key('send-cash-search')), 'dr-002');
    await tester.pump();
    expect(find.byKey(const Key('send-cash-driver-DR-002')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('send-cash-search')),
      '  SAMI   hassan ',
    );
    await tester.pump();
    expect(find.byKey(const Key('send-cash-driver-DR-004')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsNothing);
  });

  testWidgets('search empty state clears and restores the full list', (
    tester,
  ) async {
    await _openFlow(tester);

    await tester.enterText(find.byKey(const Key('send-cash-search')), 'zzzz');
    await tester.pump();
    expect(
      find.byKey(const Key('send-cash-no-search-results')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsNothing);
    expect(find.text('No drivers available'), findsNothing);

    await tester.tap(find.byKey(const Key('send-cash-search-clear')));
    await tester.pump();
    expect(find.byKey(const Key('send-cash-no-search-results')), findsNothing);
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-002')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-driver-DR-004')), findsOneWidget);
  });

  testWidgets('selection survives filtering and drives Continue', (
    tester,
  ) async {
    await _openFlow(tester);

    await tester.tap(find.byKey(const Key('send-cash-driver-DR-003')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('send-cash-continue')))
          .onPressed,
      isNotNull,
    );

    await tester.enterText(find.byKey(const Key('send-cash-search')), 'sami');
    await tester.pump();
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsNothing);
    expect(find.byKey(const Key('send-cash-driver-DR-004')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('send-cash-continue')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Khaled'), findsWidgets);

    await tester.tap(find.byKey(const Key('send-cash-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsOneWidget);
  });

  testWidgets('amount chips and balance-after follow existing rules', (
    tester,
  ) async {
    await _openFlow(tester);
    await _selectRecipient(tester);
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('2,200'), findsWidgets);
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();

    expect(find.textContaining('1,700'), findsWidgets);
    expect(find.textContaining('Khaled'), findsWidgets);

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('send-cash-continue')))
          .onPressed,
      isNotNull,
    );

    await tester.enterText(find.byKey(const Key('send-cash-amount')), '2201');
    await tester.pump();
    expect(find.text('Amount exceeds your available balance'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('send-cash-continue')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('review preserves input and confirm sends once', (tester) async {
    await _openFlow(tester);
    await _selectRecipient(tester);
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Review transfer'), findsOneWidget);
    expect(find.text('Khaled Ramadan'), findsOneWidget);
    expect(find.text('DR-003'), findsOneWidget);
    expect(find.textContaining('500'), findsWidgets);

    await tester.tap(find.byKey(const Key('send-cash-edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-cash-amount')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('send-cash-amount')))
          .controller
          ?.text,
      '500',
    );

    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(RequestSentPage), findsOneWidget);
    expect(find.text('Request Sent!'), findsOneWidget);
    expect(find.textContaining('TRF-'), findsOneWidget);
  });

  testWidgets('back from amount keeps the selected recipient', (tester) async {
    await _openFlow(tester);
    await _selectRecipient(tester);
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send-cash-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('send-cash-driver-DR-003')), findsOneWidget);
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-cash-amount')), findsOneWidget);
  });

  testWidgets('cancel from recipient leaves the balance unchanged', (
    tester,
  ) async {
    await _openFlow(tester);
    await _selectRecipient(tester);
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('send-cash-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash-back')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('send-cash-flow'), skipOffstage: false),
      findsNothing,
    );
    await _revealHomeBalance(tester);
    expect(_keyedText(tester, 'home-balance'), '2,200 EGP');
    expect(find.textContaining('1,700'), findsNothing);
  });

  testWidgets('a valid confirm deducts the balance and shows success', (
    tester,
  ) async {
    await _completeSend(tester);

    expect(find.text('Request Sent!'), findsOneWidget);
    expect(find.textContaining('Khaled Ramadan'), findsWidgets);
    expect(find.text('1,700 EGP'), findsWidgets);

    await tester.tap(find.byKey(const Key('send-cash-home')));
    await tester.pumpAndSettle();
    await _revealHomeBalance(tester);

    expect(_keyedText(tester, 'home-balance'), '1,700 EGP');
    expect(_keyedText(tester, 'home-frozen-balance'), '500 EGP');
    expect(_keyedText(tester, 'home-total-balance'), '2,200 EGP');
    expect(_keyedText(tester, 'home-charge'), '3,200 EGP');
    expect(_keyedText(tester, 'home-max-limit'), '5,000 EGP');
    expect(find.byKey(const Key('home-pending-TRF-2026-0124')), findsNothing);
  });

  testWidgets('view transaction opens history and highlights the new row', (
    tester,
  ) async {
    await _completeSend(tester);

    expect(find.byType(RequestSentPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('send-cash-view')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(
      find.byKey(const Key('history-highlight-TRF-2026-0124')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('history-entry-TRF-2026-0124')),
      findsOneWidget,
    );

    await tester.pump(historyHighlightDuration);
    await tester.pump();

    expect(
      find.byKey(const Key('history-highlight-TRF-2026-0124')),
      findsNothing,
    );
  });

  testWidgets('confirm label stays visible on a narrow width', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openFlow(tester);
    await _selectRecipient(tester);
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('send-cash-submit'));
    final label = find.descendant(of: button, matching: find.text('Confirm'));
    expect(label, findsOneWidget);
    final buttonBox = tester.getRect(button);
    final labelBox = tester.getRect(label);
    expect(labelBox.left, greaterThanOrEqualTo(buttonBox.left));
    expect(labelBox.right, lessThanOrEqualTo(buttonBox.right + 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('arabic send cash flow is right to left', (tester) async {
    await _openFlow(tester, locale: const Locale('ar'));
    expect(find.text('المستلم'), findsWidgets);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('send-cash-flow'))),
      ),
      TextDirection.rtl,
    );
  });

  testWidgets('dark mode send cash flow does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send-cash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-cash-flow')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _keyedText(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Future<void> _revealHomeBalance(WidgetTester tester) async {
  final balance = find.byKey(const Key('home-balance'), skipOffstage: false);
  await tester.ensureVisible(balance);
  await tester.pumpAndSettle();
}

Future<void> _openFlow(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(locale: locale));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('send-cash')));
  await tester.tap(find.byKey(const Key('send-cash')));
  await tester.pumpAndSettle();
}

Future<void> _selectRecipient(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('send-cash-driver-DR-003')));
  await tester.tap(find.byKey(const Key('send-cash-driver-DR-003')));
  await tester.pump();
}

Future<void> _completeSend(WidgetTester tester) async {
  await _openFlow(tester);
  await _selectRecipient(tester);
  await tester.tap(find.byKey(const Key('send-cash-continue')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('send-cash-chip-500')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('send-cash-continue')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('send-cash-submit')));
  await tester.pump();
  await tester.pump();
}

Widget _app({
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: locale,
    themeMode: themeMode,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeScope(now: _now),
  );
}

DateTime _now() => DateTime(2026, 10, 20, 9);
