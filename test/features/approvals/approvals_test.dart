import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_transfer_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/failures/approval_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/record_expense.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/send_cash.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const driverId = MockCashLedger.senderId;

  test('seeding approvals does not move money or shift transfer ids', () {
    final ledger = MockCashLedger(senderBalanceEgp: 2200);
    ledger.seedDriverApprovals();
    ledger.seedDriverApprovals();

    expect(ledger.balanceOf('DR-001'), 2200);
    expect(ledger.balanceOf('DR-003'), 1100);
    expect(ledger.balanceOf('DR-002'), 900);
    expect(ledger.balanceOf('DR-004'), 750);
    expect(ledger.transfers, hasLength(2));
    expect(ledger.custodyReceipts, hasLength(2));
    expect(ledger.roadExpenseApprovals, hasLength(1));
  });

  test('vault approval credits the driver once', () async {
    final harness = _Harness();
    await harness.approveVault(receiptId: 'DSB-2025-0441');

    expect(harness.ledger.balanceOf('DR-001'), 4200);
    expect(harness.ledger.balanceOf('DR-003'), 1100);
    final receipt = harness.ledger.custodyReceipts.firstWhere(
      (item) => item.id == 'DSB-2025-0441',
    );
    expect(receipt.status.name, 'approved');

    expect(
      () => harness.approveVault(receiptId: 'DSB-2025-0441'),
      throwsA(isA<ApprovalAlreadyFinalizedException>()),
    );
    expect(harness.ledger.balanceOf('DR-001'), 4200);

    final summary = await harness.summary();
    expect(summary.balanceEgp, 4200);
    expect(summary.chargeEgp, 3200);
    expect(summary.maxLimitEgp, 5000);
  });

  test('approving an incoming transfer credits the recipient once', () async {
    final harness = _Harness();
    await harness.approveTransfer(transferId: 'TRF-2025-0123');

    expect(harness.ledger.balanceOf('DR-001'), 2700);
    expect(harness.ledger.balanceOf('DR-003'), 1100);
    expect(
      harness.ledger.transfers
          .firstWhere((transfer) => transfer.id == 'TRF-2025-0123')
          .status,
      TransferStatus.approved,
    );

    expect(
      () => harness.approveTransfer(transferId: 'TRF-2025-0123'),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );
    expect(harness.ledger.balanceOf('DR-001'), 2700);
    expect(harness.ledger.balanceOf('DR-003'), 1100);
  });

  test('declining an incoming transfer refunds the sender once', () async {
    final harness = _Harness();
    await harness.declineTransfer(transferId: 'TRF-2025-0123');

    expect(harness.ledger.balanceOf('DR-001'), 2200);
    expect(harness.ledger.balanceOf('DR-003'), 1600);
    expect(
      harness.ledger.transfers
          .firstWhere((transfer) => transfer.id == 'TRF-2025-0123')
          .status,
      TransferStatus.rejected,
    );

    expect(
      () => harness.declineTransfer(transferId: 'TRF-2025-0123'),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );
    expect(harness.ledger.balanceOf('DR-003'), 1600);
    expect(harness.ledger.balanceOf('DR-001'), 2200);
  });

  test('road expense confirmation does not change any balance', () async {
    final harness = _Harness();
    final before = _balances(harness.ledger);

    await harness.confirmRoad(approvalId: 'RE-2026-1041');

    expect(_balances(harness.ledger), before);
    expect(harness.ledger.roadExpenseApprovals.single.status.name, 'approved');
    expect(
      () => harness.confirmRoad(approvalId: 'RE-2026-1041'),
      throwsA(isA<ApprovalAlreadyFinalizedException>()),
    );
    expect(_balances(harness.ledger), before);
    expect(harness.ledger.expenses, isEmpty);

    final summary = await harness.summary();
    expect(summary.balanceEgp, 2200);
    expect(summary.chargeEgp, 3200);
    expect(summary.maxLimitEgp, 5000);
  });

  test('road expense rejection does not change any balance', () async {
    final harness = _Harness();
    final before = _balances(harness.ledger);

    await harness.rejectRoad(approvalId: 'RE-2026-1041');

    expect(_balances(harness.ledger), before);
    expect(harness.ledger.roadExpenseApprovals.single.status.name, 'rejected');
    expect(
      () => harness.rejectRoad(approvalId: 'RE-2026-1041'),
      throwsA(isA<ApprovalAlreadyFinalizedException>()),
    );
    expect(_balances(harness.ledger), before);
    expect(harness.ledger.expenses, isEmpty);
  });

  test('finalized approvals leave the pending list', () async {
    final harness = _Harness();
    await harness.approveVault(receiptId: 'DSB-2025-0441');
    await harness.declineTransfer(transferId: 'TRF-2025-0123');
    await harness.rejectRoad(approvalId: 'RE-2026-1041');

    final items = await harness.repository.getApprovals(driverId);
    expect(items.where((item) => item.isPending), isEmpty);
    expect(
      items.map((item) => item.id),
      containsAll(['DSB-2025-0441', 'TRF-2025-0123', 'RE-2026-1041']),
    );
    expect(
      items.firstWhere((item) => item.id == 'TRF-2025-0123').outcome,
      ApprovalOutcome.rejected,
    );
    expect(
      items.firstWhere((item) => item.id == 'RE-2026-1041').outcome,
      ApprovalOutcome.rejected,
    );
  });

  test('a recorded expense stays recorded and out of approvals', () async {
    final harness = _Harness();
    final expenses = ExpenseRepositoryImpl(harness.ledger);
    final result = await RecordExpense(expenses)(
      driverId: driverId,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      createdAt: DateTime(2026, 10, 20, 9),
    );

    expect(result.expense.status, ExpenseStatus.recorded);
    expect(result.expense.id, 'EXP-412138');
    expect(harness.ledger.balanceOf(driverId), 1900);
    final items = await harness.repository.getApprovals(driverId);
    expect(items.map((item) => item.id), isNot(contains('EXP-412138')));
    expect(harness.ledger.balanceOf('DR-003'), 1100);
  });

  test('send cash stays a pending outgoing transfer', () async {
    final harness = _Harness();
    final transfers = CashTransferRepositoryImpl(harness.ledger);
    final sent = await SendCash(transfers)(
      senderId: driverId,
      recipientId: 'DR-003',
      amountEgp: 500,
      createdAt: DateTime(2026, 10, 20, 9),
    );

    expect(sent.transfer.id, 'TRF-2026-0124');
    expect(sent.transfer.status, TransferStatus.pending);
    expect(harness.ledger.balanceOf(driverId), 1700);
    expect(harness.ledger.balanceOf('DR-003'), 1100);

    final items = await harness.repository.getApprovals(driverId);
    expect(items.map((item) => item.id), isNot(contains('TRF-2026-0124')));

    expect(
      () => harness.repository.approveIncomingTransfer(
        driverId: driverId,
        transferId: sent.transfer.id,
      ),
      throwsA(isA<ApprovalNotFoundException>()),
    );
    expect(harness.ledger.balanceOf('DR-003'), 1100);

    final approved = await transfers.approve(sent.transfer.id);
    expect(approved.status, TransferStatus.approved);
    expect(harness.ledger.balanceOf(driverId), 1700);
    expect(harness.ledger.balanceOf('DR-003'), 1600);
  });
}

Map<String, int> _balances(MockCashLedger ledger) {
  return {
    for (final id in ['DR-001', 'DR-003', 'DR-002', 'DR-004'])
      id: ledger.balanceOf(id),
  };
}

class _Harness {
  late final MockCashLedger ledger;
  late final ApprovalRepositoryImpl repository;

  _Harness() {
    ledger = MockCashLedger(senderBalanceEgp: 2200)..seedDriverApprovals();
    repository = ApprovalRepositoryImpl(ledger);
  }

  late final ApproveVaultReceipt _approveVault = ApproveVaultReceipt(
    repository,
  );
  late final ApproveIncomingTransfer _approveTransfer = ApproveIncomingTransfer(
    repository,
  );
  late final DeclineIncomingTransfer _declineTransfer = DeclineIncomingTransfer(
    repository,
  );
  late final ConfirmRoadExpense _confirmRoad = ConfirmRoadExpense(repository);
  late final RejectRoadExpense _rejectRoad = RejectRoadExpense(repository);

  Future<void> approveVault({required String receiptId}) {
    return _approveVault(
      driverId: MockCashLedger.senderId,
      receiptId: receiptId,
    );
  }

  Future<void> approveTransfer({required String transferId}) {
    return _approveTransfer(
      driverId: MockCashLedger.senderId,
      transferId: transferId,
    );
  }

  Future<void> declineTransfer({required String transferId}) {
    return _declineTransfer(
      driverId: MockCashLedger.senderId,
      transferId: transferId,
    );
  }

  Future<void> confirmRoad({required String approvalId}) {
    return _confirmRoad(
      driverId: MockCashLedger.senderId,
      approvalId: approvalId,
    );
  }

  Future<void> rejectRoad({required String approvalId}) {
    return _rejectRoad(
      driverId: MockCashLedger.senderId,
      approvalId: approvalId,
    );
  }

  Future<dynamic> summary() {
    return SessionFinanceRepository(
      const MockFinanceDataSource(),
      ledger,
    ).getFinancialSummary();
  }
}
