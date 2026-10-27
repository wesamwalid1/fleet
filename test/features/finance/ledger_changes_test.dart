import 'dart:async';

import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_state.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/custody_receipt.dart';
import 'package:driver_portal_app/features/finance/domain/entities/road_expense_approval.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/failures/approval_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/expense_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_driver_data_source.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/driver_repository_impl.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_current_driver.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/usecases/watch_finance_changes.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_event.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = MockCashLedger.senderId;

void main() {
  late MockCashLedger ledger;
  late int changes;
  late StreamSubscription<void> subscription;

  setUp(() {
    ledger = MockCashLedger(senderBalanceEgp: 2200);
    changes = 0;
    subscription = ledger.changes.listen((_) => changes += 1);
  });

  tearDown(() => subscription.cancel());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('ledger change notifications', () {
    test('seeding does not signal a change', () async {
      ledger.seedDriverApprovals();
      await settle();
      expect(changes, 0);
    });

    test('every successful mutation signals exactly once', () async {
      ledger.seedDriverApprovals();
      final steps = <void Function()>[
        () => ledger.addPendingVaultReceipt(
          id: 'DSB-2026-0900',
          amountEgp: 100,
          createdAt: DateTime(2026, 10, 30),
        ),
        () => ledger.approveVaultReceipt('DSB-2025-0441'),
        () => ledger.confirmRoadExpense('RE-2026-1041'),
        () => ledger.createRecordedExpense(
          driverId: _me,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.fuel,
          amountEgp: 50,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 30),
        ),
        () => ledger.createPendingTransfer(
          senderId: _me,
          recipientId: 'DR-004',
          amountEgp: 100,
          createdAt: DateTime(2026, 10, 30),
        ),
        () => ledger.approve('TRF-2025-0123'),
        () => ledger.reject(ledger.transfers.last.id),
      ];
      for (final (index, step) in steps.indexed) {
        step();
        await settle();
        expect(changes, index + 1, reason: 'step $index');
      }
    });

    test('rejecting a road expense signals once', () async {
      ledger.seedDriverApprovals();
      ledger.rejectRoadExpense('RE-2026-1041');
      await settle();
      expect(changes, 1);
    });

    test('failed operations signal nothing and change nothing', () async {
      ledger.seedDriverApprovals();
      final balance = ledger.balanceOf(_me);
      ledger.approveVaultReceipt('DSB-2025-0441');
      ledger.approve('TRF-2025-0123');
      ledger.confirmRoadExpense('RE-2026-1041');
      await settle();
      final before = changes;
      final balanceBefore = ledger.balanceOf(_me);
      expect(balanceBefore, balance + 2000 + 500);

      expect(
        () => ledger.approveVaultReceipt('DSB-2025-0441'),
        throwsA(isA<ApprovalAlreadyFinalizedException>()),
      );
      expect(
        () => ledger.approve('TRF-2025-0123'),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(
        () => ledger.reject('TRF-2025-0123'),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(
        () => ledger.rejectRoadExpense('RE-2026-1041'),
        throwsA(isA<ApprovalAlreadyFinalizedException>()),
      );
      expect(
        () => ledger.createPendingTransfer(
          senderId: _me,
          recipientId: 'DR-004',
          amountEgp: 999999,
          createdAt: DateTime(2026, 10, 30),
        ),
        throwsA(isA<InsufficientBalanceException>()),
      );
      expect(
        () => ledger.createRecordedExpense(
          driverId: _me,
          tripId: 'trip-2026-0904',
          settlementType: SettlementType.fuel,
          amountEgp: 50,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 30),
        ),
        throwsA(isA<IneligibleTripException>()),
      );
      await settle();

      expect(changes, before);
      expect(ledger.balanceOf(_me), balanceBefore);
      expect(ledger.expenses, isEmpty);
      expect(
        ledger.roadExpenseApprovals.single.status,
        RoadExpenseStatus.approved,
      );
    });

    test('repositories forward the ledger signal', () async {
      var approvals = 0;
      var history = 0;
      var finance = 0;
      final subscriptions = [
        ApprovalRepositoryImpl(ledger).changes.listen((_) => approvals += 1),
        HistoryRepositoryImpl(ledger).changes.listen((_) => history += 1),
        SessionFinanceRepository(
          const MockFinanceDataSource(),
          ledger,
        ).changes.listen((_) => finance += 1),
      ];
      ledger.createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-004',
        amountEgp: 100,
        createdAt: DateTime(2026, 10, 30),
      );
      await settle();
      expect((approvals, history, finance), (1, 1, 1));
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    });
  });

  group('ApprovalsBloc', () {
    ApprovalsBloc approvalsBloc() {
      final repository = ApprovalRepositoryImpl(ledger);
      return ApprovalsBloc(
        driverId: _me,
        repository: repository,
        approveVaultReceipt: ApproveVaultReceipt(repository),
        approveIncomingTransfer: ApproveIncomingTransfer(repository),
        declineIncomingTransfer: DeclineIncomingTransfer(repository),
        confirmRoadExpense: ConfirmRoadExpense(repository),
        rejectRoadExpense: RejectRoadExpense(repository),
      )..add(const ApprovalsStarted());
    }

    Future<ApprovalsState> until(
      ApprovalsBloc bloc,
      bool Function(ApprovalsState state) test,
    ) async {
      if (test(bloc.state)) return bloc.state;
      return bloc.stream.firstWhere(test);
    }

    test('a new pending item appears without changing the revision', () async {
      ledger.seedDriverApprovals();
      final bloc = approvalsBloc();
      await until(bloc, (state) => !state.loading);
      expect(bloc.state.pendingCount, 3);

      ledger.createPendingTransfer(
        senderId: 'DR-004',
        recipientId: _me,
        amountEgp: 300,
        createdAt: DateTime(2026, 10, 30),
      );
      ledger.addPendingVaultReceipt(
        id: 'DSB-2026-0900',
        amountEgp: 700,
        createdAt: DateTime(2026, 10, 30),
      );
      final state = await until(bloc, (state) => state.pendingCount == 5);
      expect(state.revision, 0);
      expect(state.busy, isFalse);
      expect(
        state.items.where((item) => item.id == 'DSB-2026-0900'),
        hasLength(1),
      );
      await bloc.close();
    });

    test(
      'a finalization elsewhere removes the item; the balance follows',
      () async {
        ledger.seedDriverApprovals();
        final bloc = approvalsBloc();
        await until(bloc, (state) => !state.loading);
        final balance = bloc.state.balanceEgp;

        ledger.reject('TRF-2025-0123');
        await until(bloc, (state) => state.pendingCount == 2);
        expect(bloc.state.balanceEgp, balance);

        ledger.createPendingTransfer(
          senderId: _me,
          recipientId: 'DR-004',
          amountEgp: 500,
          createdAt: DateTime(2026, 10, 30),
        );
        await until(bloc, (state) => state.balanceEgp == balance - 500);
        expect(bloc.state.revision, 0);
        await bloc.close();
      },
    );

    test(
      'a refresh during an approval keeps busy and blocks a repeat',
      () async {
        ledger.seedDriverApprovals();
        final bloc = approvalsBloc();
        await until(bloc, (state) => !state.loading);
        final balance = ledger.balanceOf(_me);
        final busyDropped = <ApprovalsState>[];
        final watch = bloc.stream.listen((state) {
          if (!state.busy && state.revision == 0 && busyDropped.isEmpty) {
            busyDropped.add(state);
          }
        });

        bloc
          ..add(
            const ApprovalActionRequested(
              id: 'DSB-2025-0441',
              command: ApprovalCommand.approveVault,
            ),
          )
          ..add(
            const ApprovalActionRequested(
              id: 'DSB-2025-0441',
              command: ApprovalCommand.approveVault,
            ),
          );
        final done = await until(bloc, (state) => state.revision == 1);
        await settle();
        await settle();

        expect(done.busy, isFalse);
        expect(bloc.state.failed, isFalse);
        expect(bloc.state.revision, 1);
        expect(bloc.state.pendingCount, 2);
        expect(ledger.balanceOf(_me), balance + 2000);
        expect(
          ledger.custodyReceipts
              .where((receipt) => receipt.id == 'DSB-2025-0441')
              .single
              .status,
          CustodyReceiptStatus.approved,
        );
        expect(busyDropped, isEmpty);
        await watch.cancel();
        await bloc.close();
      },
    );

    test('a declined transfer refunds once and leaves the list', () async {
      ledger.seedDriverApprovals();
      final bloc = approvalsBloc();
      await until(bloc, (state) => !state.loading);
      final sender = ledger.balanceOf('DR-003');

      bloc.add(
        const ApprovalActionRequested(
          id: 'TRF-2025-0123',
          command: ApprovalCommand.declineTransfer,
        ),
      );
      await until(bloc, (state) => state.revision == 1);
      bloc.add(
        const ApprovalActionRequested(
          id: 'TRF-2025-0123',
          command: ApprovalCommand.declineTransfer,
        ),
      );
      await until(bloc, (state) => state.failed);

      expect(ledger.balanceOf('DR-003'), sender + 500);
      expect(
        ledger.transfers.firstWhere((t) => t.id == 'TRF-2025-0123').status,
        TransferStatus.rejected,
      );
      expect(bloc.state.pendingCount, 2);
      expect(bloc.state.revision, 1);
      await bloc.close();
    });

    test('closing cancels the ledger subscription', () async {
      final bloc = approvalsBloc();
      await until(bloc, (state) => !state.loading);
      await bloc.close();
      ledger.addPendingVaultReceipt(
        id: 'DSB-2026-0901',
        amountEgp: 100,
        createdAt: DateTime(2026, 10, 30),
      );
      await settle();
      expect(bloc.isClosed, isTrue);
    });
  });

  group('HistoryBloc', () {
    test('a refresh keeps the filter and the highlight', () async {
      ledger.seedDriverApprovals();
      final bloc = HistoryBloc(
        driverId: _me,
        repository: HistoryRepositoryImpl(ledger),
      )..add(const HistoryStarted());
      await bloc.stream.firstWhere((state) => !state.loading);
      bloc
        ..add(const HistoryEntryHighlighted('DSB-2025-0441'))
        ..add(const HistoryFilterSelected(HistoryFilter.expenses));
      await bloc.stream.firstWhere(
        (state) => state.filter == HistoryFilter.expenses,
      );

      final expense = ledger.createRecordedExpense(
        driverId: _me,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 50,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, 30),
      );
      final state = await bloc.stream.firstWhere(
        (state) => state.entries.any((entry) => entry.id == expense.id),
      );
      expect(state.filter, HistoryFilter.expenses);
      expect(state.highlightedId, 'DSB-2025-0441');
      expect(state.loading, isFalse);
      expect(state.visible.single.id, expense.id);
      expect(state.entries.first.id, expense.id);
      await bloc.close();
    });
  });

  group('HomeBloc', () {
    test('the balance follows ledger changes', () async {
      ledger.seedDriverApprovals();
      final finance = SessionFinanceRepository(
        const MockFinanceDataSource(),
        ledger,
      );
      final bloc = HomeBloc(
        const GetCurrentDriver(DriverRepositoryImpl(MockDriverDataSource())),
        GetFinancialSummary(finance),
        watchFinanceChanges: WatchFinanceChanges(finance),
      )..add(const HomeStarted());
      HomeReady ready(HomeState state) => state as HomeReady;
      await bloc.stream.firstWhere(
        (state) =>
            state is HomeReady &&
            state.financeStatus == HomeFinanceStatus.ready,
      );
      final before = ready(bloc.state).summary!.balanceEgp;

      ledger.createRecordedExpense(
        driverId: _me,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 300,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, 30),
      );
      await bloc.stream.firstWhere(
        (state) =>
            state is HomeReady && state.summary?.balanceEgp == before - 300,
      );

      ledger.approveVaultReceipt('DSB-2025-0441');
      await bloc.stream.firstWhere(
        (state) =>
            state is HomeReady && state.summary?.balanceEgp == before + 1700,
      );
      await bloc.close();
    });
  });
}
