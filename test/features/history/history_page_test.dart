import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
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
    expect(find.text('0 expenses'), findsOneWidget);
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsNothing);
    expect(find.text('13 May 2025'), findsOneWidget);
    expect(find.textContaining('Today'), findsNothing);

    await tester.tap(find.byKey(const Key('history-filter-expenses')));
    await tester.pump();
    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);
    expect(find.text('0 expenses'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-vault')));
    await tester.pump();
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Pending — from Khaled Ramadan'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('history-filter-pending')));
    await tester.tap(find.byKey(const Key('history-filter-pending')));
    await tester.pump();
    expect(find.text('Drivers Vault · Awaiting your approval'), findsOneWidget);
    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    expect(find.textContaining('Approved'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
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

    expect(find.text('1 expense'), findsOneWidget);
    expect(find.text('Today — 21 Oct 2026'), findsOneWidget);
    expect(find.text('Yesterday — 20 Oct 2026'), findsOneWidget);
    expect(find.text('Cross Border'), findsOneWidget);
    expect(find.textContaining('TR-2026-0927 · Recorded'), findsOneWidget);
    expect(find.text('Sent to Mohamed Said'), findsOneWidget);
    expect(find.textContaining('DR-002 · Pending confirm'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('history-filter-sent')));
    await tester.tap(find.byKey(const Key('history-filter-sent')));
    await tester.pump();
    expect(find.text('Sent to Mohamed Said'), findsOneWidget);
    expect(find.text('Cross Border'), findsNothing);
    expect(find.text('1 expense'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('history-filter-expenses')),
    );
    await tester.tap(find.byKey(const Key('history-filter-expenses')));
    await tester.pump();
    expect(find.text('Cross Border'), findsOneWidget);
    expect(find.text('Sent to Mohamed Said'), findsNothing);

    await tester.tap(find.byKey(const Key('history-entry-EXP-412138')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Expense Details'), findsOneWidget);
    expect(find.text('DEDUCTED'), findsOneWidget);
    expect(find.text('EXP-412138'), findsWidgets);
    await tester.tap(find.byKey(const Key('history-expense-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('1,700 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('an approval is reflected the next time history opens', (
    tester,
  ) async {
    await _openHistory(tester);
    expect(find.text('Drivers Vault · Awaiting your approval'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Drivers Vault · Awaiting your approval'), findsNothing);
    expect(find.textContaining('Drivers Vault · Approved'), findsWidgets);
    expect(find.text('4,200 EGP'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('4,200 EGP'), findsOneWidget);
    expect(find.text('6,200 EGP'), findsNothing);
  });

  testWidgets('arabic history copy is localized', (tester) async {
    await _openHistory(tester, locale: const Locale('ar'));

    expect(find.text('السجل'), findsWidgets);
    expect(find.text('0 مصروفات'), findsOneWidget);
    expect(find.text('من الخزينة'), findsWidgets);
    expect(find.text('بانتظار موافقتك'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('history-title')))),
      TextDirection.rtl,
    );
  });
}

Future<void> _openHistory(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  DateTime Function()? now,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
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
