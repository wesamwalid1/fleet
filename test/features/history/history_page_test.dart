import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/app_colors.dart';
import 'package:driver_portal_app/core/theme/app_text_styles.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_ledger_row.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('history lists shared ledger rows and filters are read-only', (
    tester,
  ) async {
    await _openHistory(tester);

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.byKey(const Key('history-expense-count')), findsNothing);
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('13 May 2025'), findsOneWidget);
    expect(find.textContaining('Today'), findsNothing);

    await _selectHistoryType(tester, const Key('history-filter-expenses'));
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);

    await _selectHistoryType(tester, const Key('history-filter-vault'));
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Pending — from Khaled Ramadan'), findsNothing);

    await _selectHistoryType(tester, const Key('history-filter-cash'));
    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsNWidgets(2));
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('recorded expenses and sent cash appear from the same ledger', (
    tester,
  ) async {
    await _openHistory(
      tester,
      now: () => DateTime(2026, 10, 21, 12),
      configureLedger: (ledger) {
        ledger.createRecordedExpense(
          driverId: MockCashLedger.senderId,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.crossBorder,
          amountEgp: 300,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 21, 11, 37),
        );
        ledger.createPendingTransfer(
          senderId: MockCashLedger.senderId,
          recipientId: 'DR-002',
          amountEgp: 200,
          createdAt: DateTime(2026, 10, 20, 14, 30),
        );
      },
    );

    expect(find.text('Today — 21 Oct 2026'), findsOneWidget);
    expect(find.text('Yesterday — 20 Oct 2026'), findsOneWidget);
    expect(find.text('Cross Border'), findsOneWidget);
    expect(_line('TR-2026-0927', 'Recorded'), findsOneWidget);
    expect(find.text('Sent to Mohamed Said'), findsOneWidget);
    expect(_line('DR-002', 'Pending confirm'), findsOneWidget);

    await _selectHistoryType(tester, const Key('history-filter-cash'));
    expect(find.text('Sent to Mohamed Said'), findsOneWidget);
    expect(find.text('Cross Border'), findsNothing);

    await _selectHistoryType(tester, const Key('history-filter-expenses'));
    expect(find.text('Cross Border'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Sent to Mohamed Said'), findsNothing);

    await tester.tap(find.byKey(const Key('history-entry-EXP-412138')));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('history-detail-amount'))).data,
      startsWith('-'),
    );
    expect(find.text('EXP-412138'), findsWidgets);
    await tester.tap(find.byKey(const Key('history-expense-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('1,700 EGP'), findsOneWidget);
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('an approval is reflected the next time history opens', (
    tester,
  ) async {
    await _openHistory(tester);
    expect(_line('Drivers Vault', 'Awaiting your approval'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(_line('Drivers Vault', 'Awaiting your approval'), findsNothing);
    expect(_line('Drivers Vault', 'Approved'), findsWidgets);
    expect(find.text('4,200 EGP'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('4,200 EGP'), findsNWidgets(2));
    expect(find.text('6,200 EGP'), findsNothing);
  });

  testWidgets('approving an incoming transfer updates the same history row', (
    tester,
  ) async {
    await _openHistory(tester);
    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    expect(
      find.byKey(const Key('history-entry-TRF-2025-0123')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-TRF-2025-0123')),
    );
    await tester.tap(find.byKey(const Key('approval-action-TRF-2025-0123')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Pending — from Khaled Ramadan'), findsNothing);
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(
      find.byKey(const Key('history-entry-TRF-2025-0123')),
      findsOneWidget,
    );
    expect(_line('DR-003', 'Approved'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,700 EGP'), findsNWidgets(2));
  });

  testWidgets('rejecting an incoming transfer updates the same history row', (
    tester,
  ) async {
    await _openHistory(tester);
    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-decline-TRF-2025-0123')),
    );
    await tester.tap(find.byKey(const Key('approval-decline-TRF-2025-0123')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Pending — from Khaled Ramadan'), findsNothing);
    expect(
      find.byKey(const Key('history-entry-TRF-2025-0123')),
      findsOneWidget,
    );
    expect(find.textContaining('Rejected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsNWidgets(2));
  });

  testWidgets('confirming a road expense updates the same history row', (
    tester,
  ) async {
    await _openHistory(tester);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(_line('RE-2026-1041', 'Awaiting your approval'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-action-RE-2026-1041')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.byKey(const Key('history-entry-RE-2026-1041')), findsOneWidget);
    expect(_line('RE-2026-1041', 'Approved'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsNWidgets(2));
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('rejecting a road expense is reflected in history', (
    tester,
  ) async {
    await _openHistory(tester);
    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-reject-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-reject-RE-2026-1041')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approval-reject-yes')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.byKey(const Key('history-entry-RE-2026-1041')), findsOneWidget);
    expect(_line('RE-2026-1041', 'Rejected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsNWidgets(2));
  });

  testWidgets('arabic history copy is localized', (tester) async {
    await _openHistory(tester, locale: const Locale('ar'));

    expect(find.text('السجل'), findsWidgets);
    expect(find.text('تصفية'), findsOneWidget);
    expect(find.text('بانتظار موافقتك'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('history-title')))),
      TextDirection.rtl,
    );
    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();
    expect(find.text('تصفية الحركات'), findsOneWidget);
    expect(find.text('مسح الكل'), findsOneWidget);
    expect(find.text('تطبيق عوامل التصفية'), findsOneWidget);
    expect(find.text('معاملات الخزينة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-filter-apply')));
    await tester.pumpAndSettle();
  });

  testWidgets('history rows use a compact trailing amount column', (
    tester,
  ) async {
    await _openHistory(
      tester,
      configureLedger: (ledger) {
        ledger.createRecordedExpense(
          driverId: MockCashLedger.senderId,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.crossBorder,
          amountEgp: 555,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 21, 11, 37),
        );
      },
    );

    final tile = find.byKey(const Key('history-entry-EXP-412138'));
    final details = find.byKey(const Key('history-entry-details-EXP-412138'));
    final values = find.byKey(const Key('history-entry-values-EXP-412138'));
    final title = tester.getRect(find.text('Cross Border'));
    final amount = tester.getRect(find.text('-555 EGP'));
    final referenceText = find.descendant(
      of: tile,
      matching: find.text('TR-2026-0927'),
    );
    final reference = tester.getRect(referenceText);
    final time = tester.getRect(find.textContaining('11:37'));
    final tileRect = tester.getRect(tile);
    final detailsRect = tester.getRect(details);
    final valuesRect = tester.getRect(values);

    expect(detailsRect.left, lessThan(valuesRect.left));
    expect(valuesRect.left - detailsRect.right, closeTo(12, 1));
    expect(valuesRect.right, closeTo(tileRect.right, 1));
    expect(title.left, closeTo(detailsRect.left, 1));
    expect(title.right, lessThanOrEqualTo(detailsRect.right + 1));
    expect(amount.right, closeTo(valuesRect.right, 1));
    expect(time.right, closeTo(amount.right, 1));
    expect(time.top, greaterThan(amount.bottom - 1));
    expect(reference.left, closeTo(title.left, 1));
    expect(reference.top, greaterThan(title.bottom - 1));
    expect((title.top - amount.top).abs(), lessThan(2));

    final titleStyle = tester.widget<Text>(find.text('Cross Border')).style!;
    final amountStyle = tester.widget<Text>(find.text('-555 EGP')).style!;
    final referenceStyle = tester.widget<Text>(referenceText).style!;
    final timeStyle = tester.widget<Text>(find.textContaining('11:37')).style!;
    expect(titleStyle.fontSize, AppTextStyles.bodyLarge.fontSize);
    expect(amountStyle.fontSize, AppTextStyles.bodyLarge.fontSize);
    expect(amountStyle.fontFeatures, AppTextStyles.tabular);
    expect(referenceStyle.fontSize, lessThan(titleStyle.fontSize!));
    expect(timeStyle.fontSize, AppTextStyles.helper.fontSize);
    expect(timeStyle.fontSize, lessThanOrEqualTo(referenceStyle.fontSize!));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every history row has a divider below it', (tester) async {
    await _openHistory(tester);

    const ids = [
      'RE-2026-1041',
      'TRF-2025-0123',
      'DSB-2025-0441',
      'TRF-2025-0090',
      'DSB-2025-0301',
    ];
    expect(find.byType(HistoryLedgerDivider), findsNWidgets(ids.length));
    final line = tester.widget<Divider>(find.byType(Divider).first);
    expect(line.height, 1);
    expect(line.thickness, 1);
    expect(line.color, AppColors.slate100);

    for (final id in ids) {
      final tile = tester.getRect(find.byKey(Key('history-entry-$id')));
      final below = _dividerBelow(tester, tile);
      expect(below.top, closeTo(tile.bottom, 1));
      expect(below.width, closeTo(tile.width, 1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('arabic history rows keep the amount on the trailing edge', (
    tester,
  ) async {
    await _openHistory(tester, locale: const Locale('ar'));

    final tile = find.byKey(const Key('history-entry-DSB-2025-0441'));
    expect(Directionality.of(tester.element(tile)), TextDirection.rtl);
    final title = tester.getRect(
      find.descendant(of: tile, matching: find.text('استلام من الخزينة')),
    );
    final amount = tester.getRect(
      find.descendant(of: tile, matching: find.textContaining('ج.م')),
    );
    final tileRect = tester.getRect(tile);

    expect(amount.right, lessThan(title.left));
    expect(title.left - amount.right, closeTo(12, 1));
    expect(amount.left, closeTo(tileRect.left, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow history row does not overflow', (tester) async {
    await _openHistory(
      tester,
      surfaceSize: const Size(320, 640),
      textScale: 1.6,
    );

    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    final title = tester.getRect(find.text('Pending — from Khaled Ramadan'));
    final amount = tester.getRect(find.text('+500 EGP'));
    expect(title.right, lessThanOrEqualTo(amount.left + 1));
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Received from Vault'),
      250,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
      ),
    );
    await tester.pump();
    expect(find.text('Received from Vault'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and trip filters combine for expenses', (tester) async {
    await _openHistory(
      tester,
      now: () => DateTime(2026, 10, 21, 12),
      configureLedger: (ledger) {
        ledger.createRecordedExpense(
          driverId: MockCashLedger.senderId,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.crossBorder,
          amountEgp: 300,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 21, 11, 37),
        );
      },
    );

    await tester.enterText(find.byKey(const Key('history-search')), 'Cross');
    await tester.pumpAndSettle();
    expect(find.text('Cross Border'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();
    expect(find.text('Filter Transactions'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-filter-expenses')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-trip-field')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-trip-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-trip-trip-2026-0927')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-trip-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Cross Border'), findsOneWidget);
    expect(find.byKey(const Key('history-search')), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-trip-field')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('history-filter-cash')));
    await tester.tap(find.byKey(const Key('history-filter-cash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-trip-field')), findsNothing);
    await tester.tap(find.byKey(const Key('history-filter-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Cross Border'), findsOneWidget);
  });

  testWidgets('filter sheet sizes to content and labels date range from/to', (
    tester,
  ) async {
    await _openHistory(
      tester,
      now: () => DateTime(2026, 10, 21, 12),
      configureLedger: (ledger) {
        ledger.createRecordedExpense(
          driverId: MockCashLedger.senderId,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.crossBorder,
          amountEgp: 300,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 21, 11, 37),
        );
      },
    );

    // MediaQuery follows the view, not the surface size; match the surface so
    // the sheet's 85% height cap is measured against the same screen.
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('filter-bottom-sheet'));
    expect(sheet, findsOneWidget);
    final baseHeight = tester.getSize(sheet).height;
    expect(baseHeight, lessThan(tester.view.physicalSize.height * 0.85));

    await tester.tap(find.byKey(const Key('history-filter-expenses')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-trip-field')), findsOneWidget);
    final withTripsHeight = tester.getSize(sheet).height;
    expect(withTripsHeight, greaterThan(baseHeight));

    await tester.tap(find.byKey(const Key('history-filter-cash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-trip-field')), findsNothing);
    expect(tester.getSize(sheet).height, lessThan(withTripsHeight));

    await tester.tap(find.byKey(const Key('history-date-range')));
    await tester.pumpAndSettle();
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.byKey(const Key('history-date-start')), findsOneWidget);
    expect(find.byKey(const Key('history-date-end')), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-apply')));
    await tester.pumpAndSettle();
  });

  testWidgets('arabic filter sheet labels date range from/to', (tester) async {
    await _openHistory(tester, locale: const Locale('ar'));

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-date-range')));
    await tester.pumpAndSettle();
    expect(find.text('من'), findsOneWidget);
    expect(find.text('إلى'), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-filter-apply')));
    await tester.pumpAndSettle();
  });

  testWidgets('filter sheet reset restores defaults without clearing search', (
    tester,
  ) async {
    await _openHistory(
      tester,
      now: () => DateTime(2026, 10, 21, 12),
      configureLedger: (ledger) {
        ledger.createRecordedExpense(
          driverId: MockCashLedger.senderId,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.crossBorder,
          amountEgp: 300,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 21, 11, 37),
        );
      },
    );

    await tester.enterText(find.byKey(const Key('history-search')), 'Cross');
    await tester.pumpAndSettle();
    await _selectHistoryType(tester, const Key('history-filter-vault'));
    expect(find.byKey(const Key('history-no-results')), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Cross Border'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('history-search')))
          .controller!
          .text,
      'Cross',
    );
  });
}

Future<void> _selectHistoryType(WidgetTester tester, Key optionKey) async {
  await tester.tap(find.byKey(const Key('history-filter-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(optionKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('history-filter-apply')));
  await tester.pumpAndSettle();
}

Future<void> _openHistory(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  DateTime Function()? now,
  Size surfaceSize = const Size(400, 1400),
  double textScale = 1,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: HomeScope(
        now: now ?? () => DateTime(2026, 10, 21, 12),
        configureLedger: configureLedger,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-history')));
  await tester.pumpAndSettle();
}

/// A History row line showing [reference] and a status starting with [status].
Finder _line(String reference, String status) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is HistoryReferenceLine &&
        widget.reference == reference &&
        widget.status.startsWith(status),
  );
}

Rect _dividerBelow(WidgetTester tester, Rect tile) {
  final dividers = find.byType(HistoryLedgerDivider);
  final count = tester.widgetList(dividers).length;
  return [
    for (var index = 0; index < count; index++)
      tester.getRect(dividers.at(index)),
  ].firstWhere((rect) => (rect.top - tile.bottom).abs() <= 1);
}
