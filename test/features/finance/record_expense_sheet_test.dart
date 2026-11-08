import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_attachment.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/expense_attachment_picker.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/pages/record_expense_flow_page.dart';
import 'package:driver_portal_app/features/home/presentation/pages/home_page.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cancel closes the flow and leaves the balance unchanged', (
    tester,
  ) async {
    await _openFlow(tester);
    await tester.tap(find.byKey(const Key('expense-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expense-flow')), findsNothing);
    expect(find.byKey(const Key('record-expense')), findsOneWidget);
    await _revealHomeBalance(tester);
    expect(_keyedText(tester, 'home-balance'), '2,200 EGP');
  });

  testWidgets('continue stays disabled without a trip', (tester) async {
    await _openFlow(tester);
    expect(find.byKey(const Key('expense-step-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('expense-step-dot-4')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('expense-continue')))
          .onPressed,
      isNull,
    );
    expect(find.text('Confirm Expense'), findsNothing);
    expect(find.byKey(const Key('expense-flow')), findsOneWidget);
  });

  testWidgets('review stacks Road Fees Client settlement above its value', (
    tester,
  ) async {
    await _expectStackedSettlementReview(
      tester,
      settlementKey: 'roadFeesClient',
      label: 'Road Fees — Client',
    );
  });

  testWidgets('review stacks Road Fees Vendors settlement above its value', (
    tester,
  ) async {
    await _expectStackedSettlementReview(
      tester,
      settlementKey: 'roadFeesVendors',
      label: 'Road Fees — Vendors',
    );
  });

  testWidgets('amount chips fill the field and allow manual edit', (
    tester,
  ) async {
    await _openFlow(tester);
    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'fuel');

    expect(find.byKey(const Key('expense-chip-500')), findsOneWidget);
    expect(find.byKey(const Key('expense-chip-1000')), findsOneWidget);
    expect(find.byKey(const Key('expense-chip-1500')), findsOneWidget);
    expect(find.byKey(const Key('expense-chip-2000')), findsOneWidget);

    await tester.tap(find.byKey(const Key('expense-chip-500')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense-amount')))
          .controller
          ?.text,
      '500',
    );
    expect(find.textContaining('1,700 EGP'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense-amount')))
          .controller
          ?.text,
      '300',
    );
    expect(find.textContaining('1,900 EGP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('expense-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense-amount')))
          .controller
          ?.text,
      '300',
    );
  });

  testWidgets('a valid expense deducts the balance after confirmation', (
    tester,
  ) async {
    await _openFlow(tester);
    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'fuel');
    await tester.ensureVisible(find.byKey(const Key('expense-amount')));
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();

    expect(find.textContaining('1,900 EGP'), findsOneWidget);

    await _continueToAttachments(tester);
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Review expense'), findsOneWidget);
    expect(find.text('Pending approval'), findsNothing);
    expect(find.text('TR-2026-0927'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('expense-confirm')));
    await tester.tap(find.byKey(const Key('expense-confirm')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Expense Recorded'), findsOneWidget);
    expect(
      find.text('Recorded successfully. No approval is required.'),
      findsNothing,
    );
    expect(find.textContaining('EXP-'), findsOneWidget);
    expect(find.textContaining('1,900 EGP'), findsWidgets);
    expect(find.byKey(const Key('expense-step-label')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('expense-done')));
    await tester.tap(find.byKey(const Key('expense-done')));
    await tester.pumpAndSettle();
    await _revealHomeBalance(tester);

    expect(_keyedText(tester, 'home-balance'), '1,900 EGP');
    expect(_keyedText(tester, 'home-charge'), '3,200 EGP');
    expect(_keyedText(tester, 'home-max-limit'), '5,000 EGP');
  });

  testWidgets('review shows notes and preserves them after edit', (
    tester,
  ) async {
    await _openFlow(tester);
    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'fuel');
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    await _continueToAttachments(tester);
    await tester.enterText(find.byKey(const Key('expense-notes')), ' tolls ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();

    expect(find.text('tolls'), findsOneWidget);

    await tester.tap(find.byKey(const Key('expense-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expense-trip')), findsOneWidget);
    expect(
      tester
          .element(find.byKey(const Key('expense-flow')))
          .read<RecordExpenseBloc>()
          .state
          .notes,
      ' tolls ',
    );
    expect(
      tester
          .element(find.byKey(const Key('expense-flow')))
          .read<RecordExpenseBloc>()
          .state
          .amountEgp,
      300,
    );

    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense-amount')))
          .controller
          ?.text,
      '300',
    );
    await _continueToAttachments(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expense-notes')))
          .controller
          ?.text,
      ' tolls ',
    );
  });

  testWidgets('active trip entry skips trip selection with 4 steps', (
    tester,
  ) async {
    await _openFlow(tester, fromTripCard: true);
    expect(find.byKey(const Key('expense-flow')), findsOneWidget);
    expect(find.byKey(const Key('expense-trip')), findsNothing);
    expect(find.text('Select Trip'), findsNothing);
    expect(find.byKey(const Key('expense-settlement')), findsOneWidget);
    expect(find.byKey(const Key('expense-step-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('expense-step-dot-3')), findsOneWidget);
    expect(find.byKey(const Key('expense-step-dot-4')), findsNothing);

    await _selectSettlement(tester, 'fuel');
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    await _continueToAttachments(tester);
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();
    expect(find.text('TR-2026-0927'), findsWidgets);
  });

  testWidgets('confirm expense shows added attachments', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomePage));
    openRecordExpenseFlow(
      context,
      driverId: 'DR-001',
      tripScope: ExpenseTripScope.anyTrip,
      picker: _FakePicker(),
    );
    await tester.pumpAndSettle();

    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'crossBorder');
    await tester.ensureVisible(find.byKey(const Key('expense-amount')));
    await tester.enterText(find.byKey(const Key('expense-amount')), '411');
    await tester.pump();
    await _continueToAttachments(tester);

    await tester.ensureVisible(find.byKey(const Key('expense-camera')));
    await tester.tap(find.byKey(const Key('expense-camera')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1 file'));

    expect(find.text('Review expense'), findsOneWidget);
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('1 file'), findsOneWidget);
    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(
      find.byKey(const Key('expense-confirm-attachment-ATT-1')),
      findsOneWidget,
    );
    expect(find.text('Expense Recorded'), findsNothing);
  });

  testWidgets('trip step lists completed trips and supports search', (
    tester,
  ) async {
    await _openFlow(tester);

    expect(find.text('TR-2026-0927'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);
    expect(
      find.byKey(const Key('expense-trip-locked-trip-2026-0904')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      'Suez',
    );
    await tester.pump();
    expect(find.text('TR-2026-0927'), findsOneWidget);
    expect(find.text('TR-2026-0904'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      '0904',
    );
    await tester.pump();
    expect(find.text('TR-2026-0904'), findsOneWidget);
    expect(find.text('TR-2026-0927'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      'no-such-trip',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('expense-trip-no-search-results')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('expense-trip-search-clear')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      '0904',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-trip-trip-2026-0904')));
    await tester.pump();

    expect(
      tester
          .element(find.byKey(const Key('expense-flow')))
          .read<RecordExpenseBloc>()
          .state
          .tripId,
      'trip-2026-0904',
    );
    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense-settlement')), findsOneWidget);
  });

  testWidgets('english settlement labels do not include arabic', (
    tester,
  ) async {
    await _openSettlementStep(tester);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Road Fees — Client'), findsOneWidget);
    expect(find.text('تموين'), findsNothing);
    expect(find.text('تراخيص'), findsNothing);

    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pump();

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.textContaining('تموين'), findsNothing);
    expect(
      tester
          .element(find.byKey(const Key('expense-settlement')))
          .read<RecordExpenseBloc>()
          .state
          .settlementType,
      SettlementType.fuel,
    );
  });

  testWidgets('arabic settlement labels do not include english', (
    tester,
  ) async {
    await _openSettlementStep(tester, const Locale('ar'));
    expect(find.text('تموين'), findsOneWidget);
    expect(find.text('رسوم الطريق — العميل'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
    expect(find.text('Licensing'), findsNothing);

    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pump();

    expect(find.text('تموين'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
    expect(
      tester
          .element(find.byKey(const Key('expense-settlement')))
          .read<RecordExpenseBloc>()
          .state
          .settlementType,
      SettlementType.fuel,
    );
  });

  testWidgets('dark mode record expense flow does not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-expense')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense-flow')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakePicker implements ExpenseAttachmentPicker {
  @override
  Future<ExpenseAttachment?> pickCamera() async {
    return const ExpenseAttachment(
      id: 'ATT-1',
      name: 'receipt.pdf',
      path: '/tmp/receipt.pdf',
      kind: ExpenseAttachmentKind.file,
    );
  }

  @override
  Future<ExpenseAttachment?> pickGallery() async => null;

  @override
  Future<ExpenseAttachment?> pickFile() async => null;
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

Future<void> _openFlow(WidgetTester tester, {bool fromTripCard = false}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  if (fromTripCard) {
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('home-trip-card')),
        matching: find.byKey(const Key('trip-record-expense')),
      ),
    );
  } else {
    await tester.tap(find.byKey(const Key('record-expense')));
  }
  await tester.pumpAndSettle();
}

Future<void> _selectTrip(WidgetTester tester, String id) async {
  await tester.ensureVisible(find.byKey(Key('expense-trip-$id')));
  await tester.tap(find.byKey(Key('expense-trip-$id')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('expense-continue')));
  await tester.pumpAndSettle();
}

Future<void> _selectSettlement(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.byKey(Key('expense-settlement-$name')));
  await tester.tap(find.byKey(Key('expense-settlement-$name')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('expense-continue')));
  await tester.pumpAndSettle();
}

Future<void> _continueToAttachments(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('expense-continue')));
  await tester.tap(find.byKey(const Key('expense-continue')));
  await tester.pumpAndSettle();
}

Future<void> _expectStackedSettlementReview(
  WidgetTester tester, {
  required String settlementKey,
  required String label,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await _openFlow(tester);
  await _selectTrip(tester, 'trip-2026-0927');
  await _selectSettlement(tester, settlementKey);
  await tester.enterText(find.byKey(const Key('expense-amount')), '300');
  await tester.pump();
  await _continueToAttachments(tester);
  await tester.tap(find.byKey(const Key('expense-submit')));
  await tester.pumpAndSettle();

  final settlement = find.byKey(const Key('expense-review-settlement'));
  expect(settlement, findsOneWidget);
  expect(
    find.descendant(of: settlement, matching: find.text('Settlement Type')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: settlement, matching: find.text(label)),
    findsOneWidget,
  );

  final labelTop = tester
      .getTopLeft(
        find.descendant(of: settlement, matching: find.text('Settlement Type')),
      )
      .dy;
  final valueFinder = find.descendant(
    of: settlement,
    matching: find.text(label),
  );
  final valueTop = tester.getTopLeft(valueFinder).dy;
  expect(valueTop, greaterThan(labelTop));

  final settlementRect = tester.getRect(settlement);
  final valueRect = tester.getRect(valueFinder);
  expect(valueRect.left, greaterThanOrEqualTo(settlementRect.left));
  expect(valueRect.right, lessThanOrEqualTo(settlementRect.right + 0.5));
  expect(tester.takeException(), isNull);
}

Future<void> _openSettlementStep(
  WidgetTester tester, [
  Locale locale = const Locale('en'),
]) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(locale: locale));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('record-expense')));
  await tester.pumpAndSettle();
  await _selectTrip(tester, 'trip-2026-0927');
  expect(find.byKey(const Key('expense-settlement')), findsOneWidget);
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
