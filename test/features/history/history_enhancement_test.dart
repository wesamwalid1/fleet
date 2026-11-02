import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/app_colors.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _driverId = MockCashLedger.senderId;

void main() {
  group('amount colors', () {
    test('debit and credit colors follow financial direction', () {
      expect(
        historyAmountColor(
          _entry(kind: HistoryKind.outgoing, credit: false, pending: true),
        ),
        AppColors.error,
      );
      expect(
        historyAmountColor(
          _entry(kind: HistoryKind.incoming, credit: true, pending: true),
        ),
        AppColors.creditText,
      );
      expect(
        historyAmountColor(_entry(kind: HistoryKind.expense, credit: false)),
        AppColors.error,
      );
      expect(
        historyAmountColor(_entry(kind: HistoryKind.vault, credit: true)),
        AppColors.creditText,
      );
      expect(
        historyAmountColor(
          _entry(kind: HistoryKind.requestCash, credit: true, pending: true),
        ),
        AppColors.creditText,
      );
      expect(
        historyAmountColor(
          _entry(kind: HistoryKind.withdraw, credit: false, pending: true),
        ),
        AppColors.error,
      );
      expect(
        historyAmountColor(
          _entry(kind: HistoryKind.roadExpense, credit: false, pending: true),
        ),
        AppColors.error,
      );
    });
  });

  group('pending lifecycle timestamps', () {
    test('send cash keeps one row and moves updatedAt on accept', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final createdAt = DateTime(2026, 10, 1, 9);
      final transfer = ledger.createPendingTransfer(
        senderId: _driverId,
        recipientId: 'DR-002',
        amountEgp: 150,
        createdAt: createdAt,
      );

      final pending = await _row(ledger, transfer.id);
      expect(pending.createdAt, createdAt);
      expect(pending.updatedAt, createdAt);
      expect(pending.status, HistoryDisplayStatus.pendingConfirm);
      expect(pending.credit, isFalse);

      final acceptedAt = DateTime(2026, 10, 2, 11);
      ledger.approve(transfer.id, finalizedAt: acceptedAt);
      final approved = await _row(ledger, transfer.id);
      expect(approved.createdAt, createdAt);
      expect(approved.updatedAt, acceptedAt);
      expect(approved.status, HistoryDisplayStatus.confirmed);
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.id == transfer.id),
        hasLength(1),
      );
    });

    test('incoming transfer keeps one row and updates on reject', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final pending = await _row(ledger, 'TRF-2025-0123');
      final createdAt = pending.createdAt;
      expect(pending.updatedAt, createdAt);
      expect(pending.status, HistoryDisplayStatus.awaitingApproval);

      final rejectedAt = DateTime(2026, 10, 3, 8);
      ledger.reject('TRF-2025-0123', finalizedAt: rejectedAt);
      final rejected = await _row(ledger, 'TRF-2025-0123');
      expect(rejected.createdAt, createdAt);
      expect(rejected.updatedAt, rejectedAt);
      expect(rejected.status, HistoryDisplayStatus.rejected);
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.id == 'TRF-2025-0123'),
        hasLength(1),
      );
    });

    test('request cash keeps one row and updates on approve', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final createdAt = DateTime(2026, 9, 10, 10);
      final request = ledger.submitRequestCash(
        driverId: _driverId,
        amountEgp: 400,
        createdAt: createdAt,
        note: 'fuel top-up',
      );

      final pending = await _row(ledger, request.id);
      expect(pending.kind, HistoryKind.requestCash);
      expect(pending.createdAt, createdAt);
      expect(pending.updatedAt, createdAt);
      expect(pending.status, HistoryDisplayStatus.pendingConfirm);
      expect(pending.credit, isTrue);

      final approvedAt = DateTime(2026, 9, 11, 15);
      ledger.approveCashRequest(request.id, processedAt: approvedAt);
      final approved = await _row(ledger, request.id);
      expect(approved.createdAt, createdAt);
      expect(approved.updatedAt, approvedAt);
      expect(approved.status, HistoryDisplayStatus.approved);
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.id == request.id),
        hasLength(1),
      );
      // Approved request must not also appear as a MoneyTransaction history row.
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.requestNumber == request.requestNumber),
        hasLength(1),
      );
    });

    test('withdraw keeps one row and updates on reject', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final createdAt = DateTime(2026, 8, 5, 12);
      final request = ledger.submitWithdraw(
        driverId: _driverId,
        amountEgp: 250,
        createdAt: createdAt,
      );

      final pending = await _row(ledger, request.id);
      expect(pending.kind, HistoryKind.withdraw);
      expect(pending.createdAt, createdAt);
      expect(pending.updatedAt, createdAt);
      expect(pending.credit, isFalse);

      final rejectedAt = DateTime(2026, 8, 6, 9);
      ledger.rejectCashRequest(request.id, processedAt: rejectedAt);
      final rejected = await _row(ledger, request.id);
      expect(rejected.createdAt, createdAt);
      expect(rejected.updatedAt, rejectedAt);
      expect(rejected.status, HistoryDisplayStatus.rejected);
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.id == request.id),
        hasLength(1),
      );
    });

    test('vault receipt keeps one row and updates on approve', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final pending = await _row(ledger, 'DSB-2025-0441');
      final createdAt = pending.createdAt;
      expect(pending.updatedAt, createdAt);

      final approvedAt = DateTime(2026, 7, 1, 14);
      ledger.approveVaultReceipt('DSB-2025-0441', finalizedAt: approvedAt);
      final approved = await _row(ledger, 'DSB-2025-0441');
      expect(approved.createdAt, createdAt);
      expect(approved.updatedAt, approvedAt);
      expect(approved.status, HistoryDisplayStatus.approved);
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.id == 'DSB-2025-0441'),
        hasLength(1),
      );
    });

    test('road expense keeps one pending row and updates on confirm', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final pending = await _row(ledger, 'RE-2026-1041');
      expect(pending.status, HistoryDisplayStatus.awaitingApproval);
      final createdAt = pending.createdAt;
      expect(pending.updatedAt, createdAt);

      final confirmedAt = DateTime(2026, 6, 23, 16);
      ledger.confirmRoadExpense('RE-2026-1041', finalizedAt: confirmedAt);
      final approved = await _row(ledger, 'RE-2026-1041');
      expect(approved.createdAt, createdAt);
      expect(approved.updatedAt, confirmedAt);
      expect(approved.status, HistoryDisplayStatus.approved);
      expect(
        (await HistoryRepositoryImpl(ledger).getHistory(_driverId))
            .where((entry) => entry.id == 'RE-2026-1041'),
        hasLength(1),
      );
    });

    test('record expense stays recorded without a pending lifecycle', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final createdAt = DateTime(2026, 10, 21, 11, 37);
      final expense = ledger.createRecordedExpense(
        driverId: _driverId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 120,
        notes: 'toll',
        attachments: const [],
        createdAt: createdAt,
      );

      final row = await _row(ledger, expense.id);
      expect(row.kind, HistoryKind.expense);
      expect(row.hasPendingLifecycle, isFalse);
      expect(row.status, HistoryDisplayStatus.recorded);
      expect(row.createdAt, createdAt);
      expect(row.updatedAt, createdAt);
      expect(row.isPending, isFalse);
    });
  });

  group('sorting and filters', () {
    test('sorts by updatedAt DESC with createdAt fallback', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final older = ledger.createPendingTransfer(
        senderId: _driverId,
        recipientId: 'DR-002',
        amountEgp: 50,
        createdAt: DateTime(2026, 1, 1),
      );
      final newer = ledger.createPendingTransfer(
        senderId: _driverId,
        recipientId: 'DR-004',
        amountEgp: 60,
        createdAt: DateTime(2026, 2, 1),
      );

      var entries = await HistoryRepositoryImpl(ledger).getHistory(_driverId);
      expect(entries.first.id, newer.id);

      ledger.approve(older.id, finalizedAt: DateTime(2026, 3, 1));
      entries = await HistoryRepositoryImpl(ledger).getHistory(_driverId);
      expect(entries.first.id, older.id);
      expect(entries.where((entry) => entry.id == older.id), hasLength(1));
    });

    test('legacy missing updatedAt uses createdAt via historyActivityAt', () {
      final created = DateTime(2026, 4, 1);
      expect(historyActivityAt(createdAt: created, updatedAt: null), created);
      expect(
        historyActivityAt(createdAt: created, updatedAt: DateTime(2026, 4, 2)),
        DateTime(2026, 4, 2),
      );
    });

    test('sorting remains correct after type and date filters', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      ledger.createRecordedExpense(
        driverId: _driverId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 80,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, 21, 10),
      );
      final entries = await HistoryRepositoryImpl(ledger).getHistory(_driverId);

      final expenses = [
        for (final entry in entries)
          if (entry.matches(HistoryFilter.expenses)) entry,
      ];
      final expenseTimes = expenses.map((e) => e.updatedAt).toList();
      expect(
        expenseTimes,
        orderedEquals([...expenseTimes]..sort((a, b) => b.compareTo(a))),
      );

      final dayFiltered = [
        for (final entry in entries)
          if (entry.matchesDate(
            mode: HistoryDateMode.day,
            startDate: DateTime(2026, 10, 21),
          ))
            entry,
      ];
      expect(dayFiltered, isNotEmpty);
      expect(dayFiltered.every((e) => e.updatedAt.day == 21), isTrue);
      final dayTimes = dayFiltered.map((e) => e.updatedAt).toList();
      expect(
        dayTimes,
        orderedEquals([...dayTimes]..sort((a, b) => b.compareTo(a))),
      );
    });
  });

  group('details bottom sheet', () {
    testWidgets('tapping history rows opens typed details with colors', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(
            now: () => DateTime(2026, 10, 21, 12),
            seedApprovals: true,
            configureLedger: (ledger) {
              ledger.createRecordedExpense(
                driverId: _driverId,
                tripId: 'trip-2026-0927',
                settlementType: SettlementType.crossBorder,
                amountEgp: 90,
                notes: null,
                attachments: const [],
                createdAt: DateTime(2026, 10, 21, 11),
              );
              ledger.createPendingTransfer(
                senderId: _driverId,
                recipientId: 'DR-002',
                amountEgp: 70,
                createdAt: DateTime(2026, 10, 20, 14),
              );
              ledger.submitRequestCash(
                driverId: _driverId,
                amountEgp: 100,
                createdAt: DateTime(2026, 10, 19, 9),
                note: 'ops',
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-history')));
      await tester.pumpAndSettle();

      Future<void> open(String id) async {
        final tile = find.byKey(Key('history-entry-$id'));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }

      await open('EXP-412138');
      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('DEBIT'), findsOneWidget);
      expect(find.text('Recorded'), findsWidgets);
      expect(find.text('Still pending'), findsNothing);
      await tester.tap(find.byKey(const Key('history-expense-close')));
      await tester.pumpAndSettle();

      await open('TRF-2026-0124');
      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('DEBIT'), findsOneWidget);
      expect(find.text('Still pending'), findsOneWidget);
      expect(find.text('Created'), findsWidgets);
      await tester.tap(find.byKey(const Key('history-transaction-dismiss')));
      await tester.pumpAndSettle();

      await open('RC-001');
      expect(find.text('Request number'), findsOneWidget);
      expect(find.text('CREDIT'), findsOneWidget);
      expect(find.text('ops'), findsOneWidget);
      expect(find.text('Still pending'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history-transaction-dismiss')));
      await tester.pumpAndSettle();

      await open('RE-2026-1041');
      expect(find.text('Expense type'), findsOneWidget);
      expect(find.text('DEBIT'), findsOneWidget);
      expect(find.text('Still pending'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history-transaction-dismiss')));
      await tester.pumpAndSettle();

      await open('DSB-2025-0441');
      expect(find.text('CREDIT'), findsOneWidget);
      expect(find.text('Drivers Vault'), findsWidgets);
      expect(find.text('Still pending'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history-transaction-dismiss')));
      await tester.pumpAndSettle();
    });

    testWidgets('arabic details sheet localizes labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(
            now: () => DateTime(2026, 10, 21, 12),
            seedApprovals: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-history')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-entry-DSB-2025-0441')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تفاصيل الحركة'), findsOneWidget);
      expect(find.text('دائن'), findsOneWidget);
      expect(find.text('الجدول الزمني'), findsOneWidget);
      expect(find.text('ما زال معلقاً'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('تفاصيل الحركة'))),
        TextDirection.rtl,
      );
    });
  });
}

Future<HistoryEntry> _row(MockCashLedger ledger, String id) async {
  final entries = await HistoryRepositoryImpl(ledger).getHistory(_driverId);
  return entries.firstWhere((entry) => entry.id == id);
}

HistoryEntry _entry({
  required HistoryKind kind,
  required bool credit,
  bool pending = false,
}) {
  final at = DateTime(2026, 1, 1);
  return HistoryEntry(
    id: 'x',
    kind: kind,
    amountEgp: 10,
    credit: credit,
    createdAt: at,
    updatedAt: at,
    status: pending
        ? HistoryDisplayStatus.pendingConfirm
        : HistoryDisplayStatus.approved,
  );
}
