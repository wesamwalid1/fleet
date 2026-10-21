import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const driverId = MockCashLedger.senderId;

  test('history reads the shared ledger and does not move money', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    final before = _balances(ledger);
    final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);

    expect(_balances(ledger), before);
    expect(entries.map((entry) => entry.id), [
      'TRF-2025-0123',
      'DSB-2025-0441',
      'TRF-2025-0090',
      'DSB-2025-0301',
    ]);
    expect(entries.map((entry) => entry.id), isNot(contains('RE-2026-1041')));
    expect(
      entries.where((entry) => entry.kind == HistoryKind.expense),
      isEmpty,
    );
    expect(
      entries.firstWhere((entry) => entry.id == 'DSB-2025-0441').status,
      HistoryDisplayStatus.awaitingApproval,
    );
    expect(
      entries.firstWhere((entry) => entry.id == 'DSB-2025-0301').status,
      HistoryDisplayStatus.approved,
    );
    expect(
      entries.firstWhere((entry) => entry.id == 'TRF-2025-0123').isPending,
      isTrue,
    );
  });

  test(
    'filters follow type and direction, and expenses are counted alone',
    () async {
      final ledger = _richLedger();
      final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
      final expenseCount = entries
          .where((entry) => entry.kind == HistoryKind.expense)
          .length;

      expect(expenseCount, 1);
      expect(entries.length, greaterThan(expenseCount));
      expect(_ids(entries, HistoryFilter.expenses), ['EXP-412138']);
      expect(
        _ids(entries, HistoryFilter.vault),
        containsAll(['DSB-2025-0441', 'DSB-2025-0301']),
      );
      expect(_ids(entries, HistoryFilter.vault), isNot(contains('EXP-412138')));
      expect(
        _ids(entries, HistoryFilter.drivers),
        containsAll(['TRF-2025-0123', 'TRF-2025-0090']),
      );
      expect(
        _ids(entries, HistoryFilter.drivers),
        isNot(contains('TRF-2026-0124')),
      );
      expect(_ids(entries, HistoryFilter.sent), [
        'TRF-2026-0124',
        'TRF-2026-0125',
      ]);
      expect(
        _ids(entries, HistoryFilter.pending),
        containsAll(['DSB-2025-0441', 'TRF-2025-0123', 'TRF-2026-0124']),
      );
      expect(
        _ids(entries, HistoryFilter.pending),
        isNot(contains('EXP-412138')),
      );
      expect(
        _ids(entries, HistoryFilter.pending),
        isNot(contains('TRF-2026-0125')),
      );
      expect(_ids(entries, HistoryFilter.all), contains('EXP-412138'));
      expect(_ids(entries, HistoryFilter.all), contains('TRF-2026-0124'));
    },
  );

  test('entries are newest first and grouped by calendar day', () async {
    final ledger = _richLedger();
    final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    final times = entries.map((entry) => entry.occurredAt).toList();
    expect(times, orderedEquals([...times]..sort((a, b) => b.compareTo(a))));

    final groups = groupHistoryByDay(entries);
    expect(groups.first.day, DateTime(2026, 10, 21));
    expect(groups.first.entries.single.id, 'EXP-412138');
    expect(
      groups.map((group) => group.day).toList(),
      orderedEquals(
        [...groups.map((group) => group.day)]..sort((a, b) => b.compareTo(a)),
      ),
    );
  });

  test(
    'approval updates the same history row without a second credit',
    () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final repository = HistoryRepositoryImpl(ledger);

      ledger.approveVaultReceipt(
        'DSB-2025-0441',
        finalizedAt: DateTime(2026, 10, 21, 12),
      );
      final afterApprove = _balances(ledger);
      expect(afterApprove['DR-001'], 4200);

      final entries = await repository.getHistory(driverId);
      expect(
        entries.firstWhere((entry) => entry.id == 'DSB-2025-0441').status,
        HistoryDisplayStatus.approved,
      );
      expect(_balances(ledger), afterApprove);

      await repository.getHistory(driverId);
      expect(_balances(ledger), afterApprove);
    },
  );

  test(
    'a rejected outgoing stays rejected and is not refunded by history',
    () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final sent = ledger.createPendingTransfer(
        senderId: driverId,
        recipientId: 'DR-004',
        amountEgp: 300,
        createdAt: DateTime(2026, 10, 21, 9),
      );
      ledger.reject(sent.id, finalizedAt: DateTime(2026, 10, 21, 10));
      final afterReject = _balances(ledger);
      expect(afterReject['DR-001'], 2200);
      expect(afterReject['DR-004'], 750);

      final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
      final row = entries.single;
      expect(row.kind, HistoryKind.outgoing);
      expect(row.status, HistoryDisplayStatus.rejected);
      expect(row.amountEgp, 300);
      expect(row.credit, isFalse);
      await HistoryRepositoryImpl(ledger).getHistory(driverId);
      expect(_balances(ledger), afterReject);
      expect(ledger.transfers.single.status, TransferStatus.rejected);
    },
  );

  test('switching filters does not reload or change the ledger', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    final bloc = HistoryBloc(
      driverId: driverId,
      repository: HistoryRepositoryImpl(ledger),
    );
    addTearDown(bloc.close);
    final before = _balances(ledger);
    bloc.add(const HistoryStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(const HistoryFilterSelected(HistoryFilter.sent));
    await bloc.stream.firstWhere((state) => state.filter == HistoryFilter.sent);

    expect(bloc.state.visible, isEmpty);
    expect(bloc.state.expenseCount, 0);
    expect(bloc.state.entries, isNotEmpty);
    expect(_balances(ledger), before);
  });
}

List<String> _ids(List<HistoryEntry> entries, HistoryFilter filter) {
  return [
    for (final entry in entries)
      if (entry.matches(filter)) entry.id,
  ];
}

Map<String, int> _balances(MockCashLedger ledger) {
  return {
    for (final id in ['DR-001', 'DR-002', 'DR-003', 'DR-004'])
      id: ledger.balanceOf(id),
  };
}

MockCashLedger _richLedger() {
  final ledger = MockCashLedger(senderBalanceEgp: 2200)..seedDriverApprovals();
  ledger.createRecordedExpense(
    driverId: MockCashLedger.senderId,
    tripId: 'trip-2026-0927',
    settlementType: SettlementType.fuel,
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
  final confirmed = ledger.createPendingTransfer(
    senderId: MockCashLedger.senderId,
    recipientId: 'DR-004',
    amountEgp: 100,
    createdAt: DateTime(2026, 5, 12, 9),
  );
  ledger.approve(confirmed.id, finalizedAt: DateTime(2026, 5, 12, 9, 30));
  return ledger;
}
