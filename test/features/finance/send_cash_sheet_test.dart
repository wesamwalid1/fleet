import 'package:driver_portal_app/core/session/home_scope.dart';
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
    expect(find.text('2,200 EGP'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('send-cash-close')));
    await tester.pumpAndSettle();

    expect(find.text('1,700 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsNothing);
    expect(find.text('Record Expense'), findsOneWidget);
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-TRF-2026-0124')),
      findsNothing,
    );
  });
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
