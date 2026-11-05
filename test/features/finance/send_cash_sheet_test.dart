import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/send_cash_sheet.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cancel closes the sheet and leaves the balance unchanged', (
    tester,
  ) async {
    await _openForm(tester);
    await _selectKhaled(tester);
    await tester.ensureVisible(find.byKey(const Key('send-cash-chip-500')));
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('send-cash-cancel')));
    await tester.tap(find.byKey(const Key('send-cash-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Send Cash to Driver'), findsNothing);
    expect(find.text('2,200 EGP'), findsNWidgets(2));
    expect(find.text('1,700 EGP'), findsNothing);
  });

  testWidgets('a valid request deducts the balance and shows confirmation', (
    tester,
  ) async {
    await _openForm(tester);
    await _selectKhaled(tester);
    await tester.ensureVisible(find.byKey(const Key('send-cash-chip-500')));
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('send-cash-submit')));
    await tester.tap(find.byKey(const Key('send-cash-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Request Sent!'), findsOneWidget);
    expect(find.textContaining('Khaled Ramadan'), findsWidgets);
    expect(find.text('1,700 EGP'), findsWidgets);
    expect(find.textContaining('TRF-'), findsOneWidget);

    await tester.tap(find.byKey(const Key('send-cash-home')));
    await tester.pumpAndSettle();

    // Pending Send Cash: Available 1,700, Frozen 500, Total stays 2,200.
    // Amounts are asserted by key so unsigned pending rows do not collide.
    expect(_keyedText(tester, 'home-balance'), '1,700 EGP');
    expect(_keyedText(tester, 'home-frozen-balance'), '500 EGP');
    expect(_keyedText(tester, 'home-total-balance'), '2,200 EGP');
    expect(_keyedText(tester, 'home-charge'), '3,200 EGP');
    expect(_keyedText(tester, 'home-max-limit'), '5,000 EGP');
    expect(find.byKey(const Key('record-expense')), findsOneWidget);
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2026-0124')), findsNothing);
  });

  testWidgets('send request label stays fully visible on a narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('send-cash')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _selectKhaled(tester);
    await tester.ensureVisible(find.byKey(const Key('send-cash-chip-500')));
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();

    final button = find.byKey(const Key('send-cash-submit'));
    await tester.ensureVisible(button);
    final label = find.descendant(
      of: button,
      matching: find.text('Send Request'),
    );
    expect(label, findsOneWidget);
    final buttonBox = tester.getRect(button);
    final labelBox = tester.getRect(label);
    expect(labelBox.left, greaterThanOrEqualTo(buttonBox.left));
    expect(labelBox.right, lessThanOrEqualTo(buttonBox.right + 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('view transaction opens history and highlights the new row', (
    tester,
  ) async {
    await _openForm(tester);
    await _selectKhaled(tester);
    await tester.ensureVisible(find.byKey(const Key('send-cash-chip-500')));
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('send-cash-submit')));
    await tester.tap(find.byKey(const Key('send-cash-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Request Sent!'), findsOneWidget);
    expect(find.byType(RequestSentPage), findsOneWidget);
    expect(find.byKey(const Key('send-cash-home')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-view')), findsOneWidget);

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
    expect(
      find.byKey(const Key('history-entry-TRF-2026-0124')),
      findsOneWidget,
    );
  });
}

String _keyedText(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Future<void> _openForm(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('send-cash')));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _selectKhaled(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('send-cash-driver')));
  await tester.tap(find.byKey(const Key('send-cash-driver')));
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('send-cash-driver-DR-003')));
  await tester.tap(find.byKey(const Key('send-cash-driver-DR-003')));
  await tester.pump();
}

Widget _app() {
  return const MaterialApp(
    locale: Locale('en'),
    localizationsDelegates: [
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
