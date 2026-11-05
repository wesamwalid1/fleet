import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/domain/repositories/approval_repository.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_state.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending count ignores completed history and filters', () async {
    final harness = _Harness(seed: true);
    final bloc = harness.bloc;
    addTearDown(bloc.close);
    bloc.add(const ApprovalsStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    expect(bloc.state.pendingCount, 3);
    expect(bloc.state.visiblePending, hasLength(3));
    expect(bloc.state.visibleCompleted, hasLength(2));
    expect(bloc.state.balanceEgp, 2200);

    bloc.add(const ApprovalsFilterSelected(ApprovalFilter.vault));
    await bloc.stream.firstWhere(
      (state) => state.filter == ApprovalFilter.vault,
    );

    expect(bloc.state.pendingCount, 3);
    expect(bloc.state.visiblePending, hasLength(1));
    expect(bloc.state.visiblePending.single.kind, ApprovalKind.vault);
    expect(
      bloc.state.visibleCompleted.map((item) => item.kind),
      everyElement(ApprovalKind.vault),
    );
    expect(bloc.state.visibleCompleted, isNotEmpty);

    bloc.add(const ApprovalsFilterSelected(ApprovalFilter.drivers));
    await bloc.stream.firstWhere(
      (state) => state.filter == ApprovalFilter.drivers,
    );
    expect(bloc.state.visiblePending.single.counterpartyId, 'DR-003');
    expect(bloc.state.pendingCount, 3);

    bloc.add(const ApprovalsFilterSelected(ApprovalFilter.roadExpense));
    await bloc.stream.firstWhere(
      (state) => state.filter == ApprovalFilter.roadExpense,
    );
    expect(bloc.state.visiblePending.single.id, 'RE-2026-1041');
    expect(bloc.state.pendingCount, 3);
  });

  test('an empty ledger has no pending approvals', () async {
    final harness = _Harness(seed: false);
    final bloc = harness.bloc;
    addTearDown(bloc.close);
    bloc.add(const ApprovalsStarted());
    final state = await bloc.stream.firstWhere((state) => !state.loading);

    expect(state.pendingCount, 0);
    expect(state.visiblePending, isEmpty);
    expect(state.visibleCompleted, isEmpty);
    expect(state.balanceEgp, 2200);
  });

  test(
    'balanceEgp is the ledger balance after a pending Withdraw deduction',
    () async {
      final harness = _Harness(
        seed: true,
        beforeBloc: (ledger) {
          ledger.submitWithdraw(
            driverId: MockCashLedger.senderId,
            amountEgp: 500,
            createdAt: DateTime(2026, 10, 20, 9),
          );
        },
      );
      expect(harness.ledger.currentBalance('DR-001'), 1700);
      expect(harness.ledger.availableBalance('DR-001'), 1700);
      expect(harness.ledger.frozenBalance('DR-001'), 500);

      final bloc = harness.bloc;
      addTearDown(bloc.close);
      bloc.add(const ApprovalsStarted());
      final state = await bloc.stream.firstWhere((s) => !s.loading);

      expect(state.balanceEgp, 1700);
      expect(await harness.repository.getAvailableBalance('DR-001'), 1700);
    },
  );

  test('ApprovalsStarted surfaces a load failure for Retry', () async {
    final harness = _Harness(seed: false);
    final failing = _FailingApprovals(harness.repository);
    final bloc = ApprovalsBloc(
      driverId: MockCashLedger.senderId,
      repository: failing,
      approveVaultReceipt: ApproveVaultReceipt(failing),
      approveIncomingTransfer: ApproveIncomingTransfer(failing),
      declineIncomingTransfer: DeclineIncomingTransfer(failing),
      confirmRoadExpense: ConfirmRoadExpense(failing),
      rejectRoadExpense: RejectRoadExpense(failing),
    );
    addTearDown(bloc.close);

    bloc.add(const ApprovalsStarted());
    final failed = await bloc.stream.firstWhere(
      (state) => state.failed && !state.loading,
    );
    expect(failed.items, isEmpty);

    failing.fail = false;
    bloc.add(const ApprovalsStarted());
    final recovered = await bloc.stream.firstWhere(
      (state) => !state.failed && !state.loading,
    );
    expect(recovered.items, isEmpty);
  });

  test('a finalized vault receipt cannot be approved again', () async {
    final harness = _Harness(seed: true);
    final bloc = harness.bloc;
    addTearDown(bloc.close);
    bloc.add(const ApprovalsStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    bloc.add(
      const ApprovalActionRequested(
        id: 'DSB-2025-0441',
        command: ApprovalCommand.approveVault,
      ),
    );
    await bloc.stream.firstWhere((state) => state.revision == 1);

    expect(harness.ledger.balanceOf('DR-001'), 4200);
    expect(
      bloc.state.items
          .firstWhere((item) => item.id == 'DSB-2025-0441')
          .isPending,
      isFalse,
    );
    expect(bloc.state.pendingCount, 2);

    final failed = expectLater(
      bloc.stream,
      emitsThrough(
        isA<ApprovalsState>().having((state) => state.failed, 'failed', true),
      ),
    );
    bloc.add(
      const ApprovalActionRequested(
        id: 'DSB-2025-0441',
        command: ApprovalCommand.approveVault,
      ),
    );
    await failed;
    expect(harness.ledger.balanceOf('DR-001'), 4200);
    expect(bloc.state.pendingCount, 2);
  });
}

class _Harness {
  late final MockCashLedger ledger;
  late final ApprovalRepositoryImpl repository;
  late final ApprovalsBloc bloc;

  _Harness({
    required bool seed,
    void Function(MockCashLedger ledger)? beforeBloc,
  }) {
    ledger = MockCashLedger(senderBalanceEgp: 2200);
    if (seed) ledger.seedDriverApprovals();
    beforeBloc?.call(ledger);
    repository = ApprovalRepositoryImpl(ledger);
    bloc = ApprovalsBloc(
      driverId: MockCashLedger.senderId,
      repository: repository,
      approveVaultReceipt: ApproveVaultReceipt(repository),
      approveIncomingTransfer: ApproveIncomingTransfer(repository),
      declineIncomingTransfer: DeclineIncomingTransfer(repository),
      confirmRoadExpense: ConfirmRoadExpense(repository),
      rejectRoadExpense: RejectRoadExpense(repository),
    );
  }
}

class _FailingApprovals implements ApprovalRepository {
  _FailingApprovals(this._inner);

  final ApprovalRepositoryImpl _inner;
  bool fail = true;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<ApprovalItem>> getApprovals(String driverId) async {
    if (fail) throw StateError('load failed');
    return _inner.getApprovals(driverId);
  }

  @override
  Future<int> getAvailableBalance(String driverId) =>
      _inner.getAvailableBalance(driverId);

  @override
  Future<void> approveVaultReceipt({
    required String driverId,
    required String receiptId,
    DateTime? finalizedAt,
  }) => _inner.approveVaultReceipt(
    driverId: driverId,
    receiptId: receiptId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> approveIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) => _inner.approveIncomingTransfer(
    driverId: driverId,
    transferId: transferId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> declineIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) => _inner.declineIncomingTransfer(
    driverId: driverId,
    transferId: transferId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> confirmRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) => _inner.confirmRoadExpense(
    driverId: driverId,
    approvalId: approvalId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> rejectRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) => _inner.rejectRoadExpense(
    driverId: driverId,
    approvalId: approvalId,
    finalizedAt: finalizedAt,
  );
}
