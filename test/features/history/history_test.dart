import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/failures/approval_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/paint_frame.dart';

void main() {
  const driverId = MockCashLedger.senderId;

  test(
    'a highlight clears itself after one second and changes no data',
    () async {
      expect(historyHighlightDuration, const Duration(milliseconds: 1000));
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final bloc = HistoryBloc(
        driverId: driverId,
        repository: HistoryRepositoryImpl(ledger),
      )..add(const HistoryStarted());
      await withFrames(bloc.stream.firstWhere((state) => !state.loading));
      final entries = bloc.state.entries;

      final clock = Stopwatch()..start();
      bloc.add(const HistoryEntryHighlighted('DSB-2025-0441'));
      await bloc.stream.firstWhere(
        (state) => state.highlightedId == 'DSB-2025-0441',
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(bloc.state.highlightedId, 'DSB-2025-0441');

      await bloc.stream.firstWhere((state) => state.highlightedId == null);
      expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(1000));
      expect(clock.elapsedMilliseconds, lessThan(1500));
      expect(bloc.state.entries, entries);
      await bloc.close();
    },
  );

  test(
    'highlight clears conflicting filters and query so the target is visible',
    () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final bloc = HistoryBloc(
        driverId: driverId,
        repository: HistoryRepositoryImpl(ledger),
      )..add(const HistoryStarted());
      addTearDown(bloc.close);
      await withFrames(bloc.stream.firstWhere((state) => !state.loading));

      bloc.add(
        HistoryFiltersApplied(
          HistoryFilterDraft(
            filter: HistoryFilter.expenses,
            dateMode: HistoryDateMode.day,
            startDate: DateTime(2099, 1, 1),
            tripIds: const {'trip-missing'},
          ),
        ),
      );
      bloc.add(const HistorySearchChanged('zzz-no-match'));
      await bloc.stream.firstWhere(
        (state) =>
            state.filter == HistoryFilter.expenses &&
            state.query == 'zzz-no-match',
      );

      expect(
        bloc.state.visible.any((entry) => entry.id == 'DSB-2025-0441'),
        isFalse,
      );

      bloc.add(const HistoryEntryHighlighted('DSB-2025-0441'));
      await bloc.stream.firstWhere(
        (state) => state.highlightedId == 'DSB-2025-0441',
      );

      expect(bloc.state.filter, HistoryFilter.all);
      expect(bloc.state.query, isEmpty);
      expect(bloc.state.dateMode, HistoryDateMode.all);
      expect(bloc.state.startDate, isNull);
      expect(bloc.state.endDate, isNull);
      expect(bloc.state.tripIds, isEmpty);
      expect(
        bloc.state.visible.any((entry) => entry.id == 'DSB-2025-0441'),
        isTrue,
      );
    },
  );

  test('history reads the shared ledger and does not move money', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    final before = _balances(ledger);
    final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);

    expect(_balances(ledger), before);
    expect(entries.map((entry) => entry.id), [
      'RE-2026-1041',
      'TRF-2025-0123',
      'DSB-2025-0441',
      'TRF-2025-0090',
      'DSB-2025-0301',
    ]);
    expect(
      entries.firstWhere((entry) => entry.id == 'RE-2026-1041').status,
      HistoryDisplayStatus.awaitingApproval,
    );
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
      expect(_ids(entries, HistoryFilter.expenses), [
        'EXP-412138',
        'RE-2026-1041',
      ]);
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
        _ids(entries, HistoryFilter.cashTransfers),
        containsAll([
          'TRF-2025-0123',
          'TRF-2025-0090',
          'TRF-2026-0124',
          'TRF-2026-0125',
        ]),
      );
      expect(
        _ids(entries, HistoryFilter.cashTransfers),
        isNot(contains('DSB-2025-0441')),
      );
      expect(
        _ids(entries, HistoryFilter.pending),
        containsAll([
          'DSB-2025-0441',
          'TRF-2025-0123',
          'TRF-2026-0124',
          'RE-2026-1041',
        ]),
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
    await withFrames(bloc.stream.firstWhere((state) => !state.loading));
    bloc.add(const HistoryFilterSelected(HistoryFilter.sent));
    await bloc.stream.firstWhere((state) => state.filter == HistoryFilter.sent);

    expect(bloc.state.visible, isEmpty);
    expect(bloc.state.expenseCount, 0);
    expect(bloc.state.entries, isNotEmpty);
    expect(_balances(ledger), before);
  });

  test(
    'approving a vault receipt updates the same incoming history row',
    () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      ledger.approveVaultReceipt(
        'DSB-2025-0441',
        finalizedAt: DateTime(2026, 10, 21, 12),
      );

      final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
      final rows = entries.where((entry) => entry.id == 'DSB-2025-0441');
      expect(rows, hasLength(1));
      expect(rows.single.kind, HistoryKind.vault);
      expect(rows.single.credit, isTrue);
      expect(rows.single.status, HistoryDisplayStatus.approved);
      expect(rows.single.amountEgp, 2000);
      expect(
        () => ledger.approveVaultReceipt('DSB-2025-0441'),
        throwsA(isA<ApprovalAlreadyFinalizedException>()),
      );
      final again = await HistoryRepositoryImpl(ledger).getHistory(driverId);
      expect(again.where((entry) => entry.id == 'DSB-2025-0441'), hasLength(1));
      expect(ledger.balanceOf(driverId), 4200);
    },
  );

  test('approving an incoming transfer updates the same history row', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    ledger.approve('TRF-2025-0123', finalizedAt: DateTime(2026, 10, 21, 12));

    final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    final rows = entries.where((entry) => entry.id == 'TRF-2025-0123');
    expect(rows, hasLength(1));
    expect(rows.single.kind, HistoryKind.incoming);
    expect(rows.single.credit, isTrue);
    expect(rows.single.status, HistoryDisplayStatus.approved);
    expect(rows.single.amountEgp, 500);
    expect(
      () => ledger.approve('TRF-2025-0123'),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );
    final again = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    expect(again.where((entry) => entry.id == 'TRF-2025-0123'), hasLength(1));
    expect(ledger.balanceOf(driverId), 2700);
  });

  test('rejecting an incoming transfer updates the same history row', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    final before = _balances(ledger);
    ledger.reject('TRF-2025-0123', finalizedAt: DateTime(2026, 10, 21, 12));

    final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    final rows = entries.where((entry) => entry.id == 'TRF-2025-0123');
    expect(rows, hasLength(1));
    expect(rows.single.status, HistoryDisplayStatus.rejected);
    expect(rows.single.kind, HistoryKind.incoming);
    expect(ledger.balanceOf(driverId), before[driverId]);
    expect(ledger.balanceOf('DR-003'), before['DR-003']! + 500);
    final again = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    expect(again.where((entry) => entry.id == 'TRF-2025-0123'), hasLength(1));
  });

  test('confirming a road expense updates the same history row and does not move money', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    final before = _balances(ledger);
    final pending = (await HistoryRepositoryImpl(ledger).getHistory(driverId))
        .firstWhere((entry) => entry.id == 'RE-2026-1041');
    expect(pending.status, HistoryDisplayStatus.awaitingApproval);
    expect(pending.createdAt, DateTime(2026, 6, 22, 10, 15));
    expect(pending.updatedAt, pending.createdAt);

    ledger.confirmRoadExpense(
      'RE-2026-1041',
      finalizedAt: DateTime(2026, 10, 21, 12),
    );
    expect(_balances(ledger), before);

    final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    final rows = entries.where((entry) => entry.id == 'RE-2026-1041');
    expect(rows, hasLength(1));
    expect(rows.single.kind, HistoryKind.roadExpense);
    expect(rows.single.status, HistoryDisplayStatus.approved);
    expect(rows.single.amountEgp, 300);
    expect(rows.single.credit, isFalse);
    expect(rows.single.createdAt, pending.createdAt);
    expect(rows.single.updatedAt, DateTime(2026, 10, 21, 12));
    expect(rows.single.matches(HistoryFilter.expenses), isTrue);
    expect(entries.first.id, 'RE-2026-1041');
    expect(
      () => ledger.confirmRoadExpense('RE-2026-1041'),
      throwsA(isA<ApprovalAlreadyFinalizedException>()),
    );
    final again = await HistoryRepositoryImpl(ledger).getHistory(driverId);
    expect(again.where((entry) => entry.id == 'RE-2026-1041'), hasLength(1));
    expect(_balances(ledger), before);
  });

  test(
    'rejecting a road expense records the rejection without moving money',
    () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final before = _balances(ledger);
      ledger.rejectRoadExpense(
        'RE-2026-1041',
        finalizedAt: DateTime(2026, 10, 21, 12),
      );

      final entries = await HistoryRepositoryImpl(ledger).getHistory(driverId);
      final rows = entries.where((entry) => entry.id == 'RE-2026-1041');
      expect(rows, hasLength(1));
      expect(rows.single.status, HistoryDisplayStatus.rejected);
      expect(_balances(ledger), before);
      expect(
        () => ledger.rejectRoadExpense('RE-2026-1041'),
        throwsA(isA<ApprovalAlreadyFinalizedException>()),
      );
      final again = await HistoryRepositoryImpl(ledger).getHistory(driverId);
      expect(again.where((entry) => entry.id == 'RE-2026-1041'), hasLength(1));
    },
  );

  test('date and trip matching follow inclusive calendar boundaries', () {
    final expense = HistoryEntry(
      id: 'e1',
      kind: HistoryKind.expense,
      amountEgp: 10,
      credit: false,
      createdAt: DateTime(2026, 10, 20, 23, 59),
      updatedAt: DateTime(2026, 10, 20, 23, 59),
      status: HistoryDisplayStatus.recorded,
      tripId: 'trip-a',
      tripCode: 'TR-A',
    );
    final transfer = HistoryEntry(
      id: 't1',
      kind: HistoryKind.outgoing,
      amountEgp: 10,
      credit: false,
      createdAt: DateTime(2026, 10, 20, 12),
      updatedAt: DateTime(2026, 10, 20, 12),
      status: HistoryDisplayStatus.confirmed,
    );

    expect(
      expense.matchesDate(
        mode: HistoryDateMode.day,
        startDate: DateTime(2026, 10, 20),
      ),
      isTrue,
    );
    expect(
      expense.matchesDate(
        mode: HistoryDateMode.range,
        startDate: DateTime(2026, 10, 19),
        endDate: DateTime(2026, 10, 20),
      ),
      isTrue,
    );
    expect(
      expense.matchesDate(
        mode: HistoryDateMode.range,
        startDate: DateTime(2026, 10, 21),
        endDate: DateTime(2026, 10, 22),
      ),
      isFalse,
    );
    expect(
      expense.matchesTrip(
        filter: HistoryFilter.expenses,
        tripIds: const {'trip-a'},
      ),
      isTrue,
    );
    expect(
      expense.matchesTrip(
        filter: HistoryFilter.expenses,
        tripIds: const {'trip-b'},
      ),
      isFalse,
    );
    expect(
      transfer.matchesTrip(
        filter: HistoryFilter.cashTransfers,
        tripIds: const {'trip-a'},
      ),
      isTrue,
    );
    expect(
      transfer.matchesTrip(
        filter: HistoryFilter.all,
        tripIds: const {'trip-a'},
      ),
      isTrue,
    );
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
