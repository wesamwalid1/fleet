import 'package:driver_portal_app/features/finance/domain/entities/expense_attachment.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/expense_attachment_picker.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/record_expense_sheet.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/home/presentation/pages/home_page.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cancel closes the sheet and leaves the balance unchanged', (
    tester,
  ) async {
    await _openForm(tester);
    await tester.tap(find.byKey(const Key('expense-close')));
    await tester.pumpAndSettle();

    expect(find.text('Record Expense'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('1,900 EGP'), findsNothing);
  });

  testWidgets('missing trip shows a validation message', (tester) async {
    await _openForm(tester);
    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pump();

    expect(find.text('Please select a trip'), findsOneWidget);
    expect(find.text('Confirm Expense'), findsNothing);
    expect(find.text('2,200 EGP'), findsWidgets);
  });

  testWidgets('a valid expense deducts the balance after confirmation', (
    tester,
  ) async {
    await _openForm(tester);
    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'fuel');
    await tester.ensureVisible(find.byKey(const Key('expense-amount')));
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();

    expect(find.textContaining('1,900 EGP'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pump();

    expect(find.text('Confirm Expense'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsWidgets);
    expect(find.text('Pending approval'), findsNothing);

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

    await tester.ensureVisible(find.byKey(const Key('expense-done')));
    await tester.tap(find.byKey(const Key('expense-done')));
    await tester.pumpAndSettle();

    expect(find.text('1,900 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsNothing);
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.textContaining('EXP-'), findsNothing);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsOneWidget,
    );
  });

  testWidgets('confirm expense sheet is shorter than the entry sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-expense')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final entryHeight = tester.getSize(find.byType(RecordExpenseSheet)).height;
    expect(entryHeight, greaterThan(1000));

    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'fuel');
    await tester.ensureVisible(find.byKey(const Key('expense-amount')));
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pump();

    expect(find.text('Confirm Expense'), findsOneWidget);
    expect(find.byKey(const Key('expense-back')), findsOneWidget);
    expect(find.byKey(const Key('expense-confirm')), findsOneWidget);

    final sheet = tester.getRect(find.byType(RecordExpenseSheet));
    final confirmButton = tester.getRect(
      find.byKey(const Key('expense-confirm')),
    );
    expect(sheet.height, lessThan(entryHeight));
    final gap = sheet.bottom - confirmButton.bottom;
    expect(gap, greaterThanOrEqualTo(24));
    expect(gap, lessThan(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm expense shows added attachments', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomePage));
    showRecordExpenseSheet(context, driverId: 'DR-001', picker: _FakePicker());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.byKey(const Key('expense-camera')));
    await tester.tap(find.byKey(const Key('expense-camera')));
    await tester.pump();

    await _selectTrip(tester, 'trip-2026-0927');
    await _selectSettlement(tester, 'crossBorder');
    await tester.ensureVisible(find.byKey(const Key('expense-amount')));
    await tester.enterText(find.byKey(const Key('expense-amount')), '411');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pump();
    await tester.ensureVisible(find.text('1 file'));

    expect(find.text('Confirm Expense'), findsOneWidget);
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('1 file'), findsOneWidget);
    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(
      find.byKey(const Key('expense-confirm-attachment-ATT-1')),
      findsOneWidget,
    );
    expect(find.text('Expense Recorded'), findsNothing);
  });

  testWidgets('completed trips stay visible but cannot be selected', (
    tester,
  ) async {
    await _openForm(tester);
    await tester.tap(find.byKey(const Key('expense-trip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('TR-2026-0927'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(
      find.byKey(const Key('expense-trip-locked-trip-2026-0904')),
      findsOneWidget,
    );
    expect(find.text('Completed'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const Key('expense-trip-trip-2026-0904')),
    );
    await tester.tap(find.byKey(const Key('expense-trip-trip-2026-0904')));
    await tester.pump();
    expect(find.text('Select Trip'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      'Suez',
    );
    await tester.pump();
    expect(find.text('TR-2026-0927'), findsOneWidget);
    expect(find.text('TR-2026-0904'), findsOneWidget);
    expect(
      find.byKey(const Key('expense-trip-locked-trip-2026-0904')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      '0904',
    );
    await tester.pump();
    expect(find.text('TR-2026-0904'), findsOneWidget);
    expect(find.text('TR-2026-0927'), findsNothing);
    await tester.tap(find.byKey(const Key('expense-trip-trip-2026-0904')));
    await tester.pump();
    expect(find.text('Select Trip'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('expense-trip-search')),
      '0927',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-trip-trip-2026-0927')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Select Trip'), findsNothing);
    expect(find.text('TR-2026-0927'), findsOneWidget);
    expect(find.text('Select trip...'), findsNothing);
  });

  testWidgets('english settlement labels do not include arabic', (
    tester,
  ) async {
    await _openSettlementPicker(tester);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Road Fees — Client'), findsOneWidget);
    expect(find.text('تموين'), findsNothing);
    expect(find.text('تراخيص'), findsNothing);

    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

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
    await _openSettlementPicker(tester, const Locale('ar'));
    expect(find.text('تموين'), findsOneWidget);
    expect(find.text('رسوم الطريق — العميل'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
    expect(find.text('Licensing'), findsNothing);

    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

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

Future<void> _openForm(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('record-expense')));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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

Future<void> _openSettlementPicker(
  WidgetTester tester, [
  Locale locale = const Locale('en'),
]) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(locale));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('record-expense')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.ensureVisible(find.byKey(const Key('expense-settlement')));
  await tester.tap(find.byKey(const Key('expense-settlement')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _app([Locale locale = const Locale('en')]) {
  return MaterialApp(
    locale: locale,
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
