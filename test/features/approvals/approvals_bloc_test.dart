import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
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
      containsAll([ApprovalKind.vault, ApprovalKind.driver]),
    );

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
  late final ApprovalsBloc bloc;

  _Harness({required bool seed}) {
    ledger = MockCashLedger(senderBalanceEgp: 2200);
    if (seed) ledger.seedDriverApprovals();
    final repository = ApprovalRepositoryImpl(ledger);
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
