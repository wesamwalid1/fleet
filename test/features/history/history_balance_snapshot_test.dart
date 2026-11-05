import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _driverId = MockCashLedger.senderId;

void main() {
  group('ledger balance snapshots', () {
    test('immediate expense debit captures before/after', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final expense = ledger.createRecordedExpense(
        driverId: _driverId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 200,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, 21, 11),
      );

      expect(expense.balanceBeforeEgp, 2200);
      expect(expense.balanceAfterEgp, 2000);

      final row = await _row(ledger, expense.id);
      expect(row.balanceBeforeEgp, 2200);
      expect(row.balanceAfterEgp, 2000);
      expect(row.hasBalanceSnapshot, isTrue);
    });

    test('outgoing send captures sender debit at creation', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final transfer = ledger.createPendingTransfer(
        senderId: _driverId,
        recipientId: 'DR-002',
        amountEgp: 150,
        createdAt: DateTime(2026, 10, 20, 9),
      );

      expect(transfer.senderBalanceBeforeEgp, 2200);
      expect(transfer.senderBalanceAfterEgp, 2050);
      expect(transfer.recipientBalanceBeforeEgp, isNull);

      final pending = await _row(ledger, transfer.id);
      expect(pending.balanceBeforeEgp, 2200);
      expect(pending.balanceAfterEgp, 2050);

      ledger.approve(transfer.id, finalizedAt: DateTime(2026, 10, 21, 9));
      final confirmed = await _row(ledger, transfer.id);
      expect(confirmed.balanceBeforeEgp, 2200);
      expect(confirmed.balanceAfterEgp, 2050);
      expect(ledger.balanceOf(_driverId), 2050);
    });

    test('rejected outgoing keeps creation debit snapshots', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final transfer = ledger.createPendingTransfer(
        senderId: _driverId,
        recipientId: 'DR-002',
        amountEgp: 100,
        createdAt: DateTime(2026, 10, 20, 9),
      );
      expect(transfer.senderBalanceBeforeEgp, 2200);
      expect(transfer.senderBalanceAfterEgp, 2100);

      ledger.reject(transfer.id, finalizedAt: DateTime(2026, 10, 21, 9));
      final rejected = await _row(ledger, transfer.id);
      expect(rejected.balanceBeforeEgp, 2200);
      expect(rejected.balanceAfterEgp, 2100);
      expect(ledger.balanceOf(_driverId), 2200);
    });

    test('incoming pending has no recipient snapshot until approve', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final pending = await _row(ledger, 'TRF-2025-0123');
      expect(pending.hasBalanceSnapshot, isFalse);

      ledger.approve('TRF-2025-0123', finalizedAt: DateTime(2026, 10, 21, 12));
      final approved = await _row(ledger, 'TRF-2025-0123');
      expect(approved.balanceBeforeEgp, 2200);
      expect(approved.balanceAfterEgp, 2700);
    });

    test('incoming reject does not fabricate recipient snapshots', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      ledger.reject('TRF-2025-0123', finalizedAt: DateTime(2026, 10, 21, 12));
      final rejected = await _row(ledger, 'TRF-2025-0123');
      expect(rejected.hasBalanceSnapshot, isFalse);
      expect(ledger.balanceOf(_driverId), 2200);
    });

    test('vault pending has no snapshot; approve captures credit', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final pending = await _row(ledger, 'DSB-2025-0441');
      expect(pending.hasBalanceSnapshot, isFalse);

      ledger.approveVaultReceipt(
        'DSB-2025-0441',
        finalizedAt: DateTime(2026, 10, 21, 12),
      );
      final approved = await _row(ledger, 'DSB-2025-0441');
      expect(approved.balanceBeforeEgp, 2200);
      expect(approved.balanceAfterEgp, 4200);
    });

    test('request cash pending has no snapshot; approve credits', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final request = ledger.submitRequestCash(
        driverId: _driverId,
        amountEgp: 400,
        createdAt: DateTime(2026, 9, 10),
      );
      final pending = await _row(ledger, request.id);
      expect(pending.hasBalanceSnapshot, isFalse);

      ledger.approveCashRequest(request.id, processedAt: DateTime(2026, 9, 11));
      final approved = await _row(ledger, request.id);
      expect(approved.balanceBeforeEgp, 2200);
      expect(approved.balanceAfterEgp, 2600);
    });

    test('withdraw snapshots the debit at submit; approve keeps it', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final request = ledger.submitWithdraw(
        driverId: _driverId,
        amountEgp: 250,
        createdAt: DateTime(2026, 8, 5),
      );
      final pending = await _row(ledger, request.id);
      expect(pending.balanceBeforeEgp, 2200);
      expect(pending.balanceAfterEgp, 1950);

      ledger.approveCashRequest(request.id, processedAt: DateTime(2026, 8, 6));
      final approved = await _row(ledger, request.id);
      expect(approved.balanceBeforeEgp, 2200);
      expect(approved.balanceAfterEgp, 1950);
      expect(ledger.balanceOf(_driverId), 1950);
    });

    test(
      'rejected withdraw keeps the debit snapshot and refunds once',
      () async {
        final ledger = MockCashLedger(senderBalanceEgp: 2200);
        final request = ledger.submitWithdraw(
          driverId: _driverId,
          amountEgp: 250,
          createdAt: DateTime(2026, 8, 5),
        );

        ledger.rejectCashRequest(request.id, processedAt: DateTime(2026, 8, 6));
        final rejected = await _row(ledger, request.id);
        expect(rejected.status, HistoryDisplayStatus.rejected);
        expect(rejected.balanceBeforeEgp, 2200);
        expect(rejected.balanceAfterEgp, 1950);
        expect(ledger.balanceOf(_driverId), 2200);
      },
    );

    test('rejected cash request does not fabricate snapshots', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final request = ledger.submitRequestCash(
        driverId: _driverId,
        amountEgp: 100,
        createdAt: DateTime(2026, 8, 1),
      );
      ledger.rejectCashRequest(request.id, processedAt: DateTime(2026, 8, 2));
      final rejected = await _row(ledger, request.id);
      expect(rejected.hasBalanceSnapshot, isFalse);
      expect(ledger.balanceOf(_driverId), 2200);
    });

    test('road expense never captures balance snapshots', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final pending = await _row(ledger, 'RE-2026-1041');
      expect(pending.hasBalanceSnapshot, isFalse);

      ledger.confirmRoadExpense(
        'RE-2026-1041',
        finalizedAt: DateTime(2026, 10, 21),
      );
      final approved = await _row(ledger, 'RE-2026-1041');
      expect(approved.hasBalanceSnapshot, isFalse);
      expect(ledger.balanceOf(_driverId), 2200);
    });

    test('snapshots stay fixed after later transactions', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final first = ledger.createRecordedExpense(
        driverId: _driverId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 100,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, 21, 10),
      );
      ledger.createRecordedExpense(
        driverId: _driverId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 50,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, 21, 11),
      );

      final firstRow = await _row(ledger, first.id);
      expect(firstRow.balanceBeforeEgp, 2200);
      expect(firstRow.balanceAfterEgp, 2100);
      expect(ledger.balanceOf(_driverId), 2050);
    });

    test('legacy seed rows omit unrecovered snapshots', () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final vault = await _row(ledger, 'DSB-2025-0301');
      final incoming = await _row(ledger, 'TRF-2025-0090');
      expect(vault.hasBalanceSnapshot, isFalse);
      expect(incoming.hasBalanceSnapshot, isFalse);
    });
  });

  group('confirmed expense totals', () {
    test(
      'pending and rejected road expenses are excluded from totals',
      () async {
        final ledger = MockCashLedger(senderBalanceEgp: 2200)
          ..seedDriverApprovals();
        final bloc = HistoryBloc(
          driverId: _driverId,
          repository: HistoryRepositoryImpl(ledger),
        );
        addTearDown(bloc.close);
        bloc.add(const HistoryStarted());
        await bloc.stream.firstWhere((state) => !state.loading);

        expect(bloc.state.expenseCount, 0);
        expect(
          bloc.state.entries.any((entry) => entry.id == 'RE-2026-1041'),
          isTrue,
        );

        ledger.confirmRoadExpense(
          'RE-2026-1041',
          finalizedAt: DateTime(2026, 10, 21),
        );
        await bloc.stream.firstWhere(
          (state) => state.entries.any(
            (entry) =>
                entry.id == 'RE-2026-1041' &&
                entry.status == HistoryDisplayStatus.approved,
          ),
        );
        expect(bloc.state.expenseCount, 1);
      },
    );
  });

  group('details sheet display', () {
    testWidgets('shows snapshots and Arabic unavailable copy', (tester) async {
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
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-history')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('history-entry-EXP-412138')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('history-detail-balance-snapshot')),
        findsOneWidget,
      );
      expect(find.text('Balance before'), findsOneWidget);
      expect(find.text('Balance after'), findsOneWidget);
      expect(find.text('Deducted when recorded.'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('history-detail-balance-before')),
            )
            .data,
        '2,200 EGP',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('history-detail-balance-after')))
            .data,
        '2,110 EGP',
      );
      await tester.tap(find.byKey(const Key('history-expense-close')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('history-entry-DSB-2025-0441')));
      await tester.pumpAndSettle();
      expect(find.text('Not credited yet'), findsOneWidget);
      expect(find.text('Credited after you approve.'), findsOneWidget);
      expect(
        find.byKey(const Key('history-detail-balance-before')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('history-transaction-dismiss')));
      await tester.pumpAndSettle();
    });

    testWidgets('Arabic labels for balance snapshot', (tester) async {
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
      await tester.tap(find.byKey(const Key('history-entry-RE-2026-1041')));
      await tester.pumpAndSettle();

      expect(find.text('تغيّر الرصيد'), findsOneWidget);
      expect(find.text('لا تغيير'), findsOneWidget);
      expect(find.text('مصروفات الطريق لا تؤثر على رصيدك.'), findsOneWidget);
      expect(find.text('الرصيد قبل'), findsNothing);
    });
  });
}

Future<HistoryEntry> _row(MockCashLedger ledger, String id) async {
  final entries = await HistoryRepositoryImpl(ledger).getHistory(_driverId);
  return entries.firstWhere((entry) => entry.id == id);
}
