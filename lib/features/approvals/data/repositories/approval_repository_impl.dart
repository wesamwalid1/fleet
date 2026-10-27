import '../../../finance/data/datasources/mock_cash_ledger.dart';
import '../../../finance/domain/entities/cash_transfer.dart';
import '../../../finance/domain/entities/custody_receipt.dart';
import '../../../finance/domain/entities/road_expense_approval.dart';
import '../../../finance/domain/failures/approval_exception.dart';
import '../../domain/entities/approval_item.dart';
import '../../domain/repositories/approval_repository.dart';

class ApprovalRepositoryImpl implements ApprovalRepository {
  final MockCashLedger _ledger;

  const ApprovalRepositoryImpl(this._ledger);

  @override
  Stream<void> get changes => _ledger.changes;

  @override
  Future<List<ApprovalItem>> getApprovals(String driverId) async {
    final items = <ApprovalItem>[
      for (final receipt in _ledger.custodyReceipts)
        if (receipt.driverId == driverId) _vault(receipt),
      for (final transfer in _ledger.transfers)
        if (transfer.recipientId == driverId) _driver(transfer),
      for (final approval in _ledger.roadExpenseApprovals)
        if (approval.driverId == driverId) _road(approval),
    ];
    final pending = items.where((item) => item.isPending).toList()
      ..sort((a, b) {
        final rank = _rank(a.kind).compareTo(_rank(b.kind));
        if (rank != 0) return rank;
        return a.occurredAt.compareTo(b.occurredAt);
      });
    final completed = items.where((item) => !item.isPending).toList()
      ..sort((a, b) {
        final left = a.finalizedAt ?? a.occurredAt;
        final right = b.finalizedAt ?? b.occurredAt;
        return left.compareTo(right);
      });
    return [...pending, ...completed];
  }

  @override
  Future<int> getAvailableBalance(String driverId) async {
    return _ledger.balanceOf(driverId);
  }

  @override
  Future<void> approveVaultReceipt({
    required String driverId,
    required String receiptId,
    DateTime? finalizedAt,
  }) async {
    final receipt = _receipt(receiptId);
    if (receipt.driverId != driverId) throw const ApprovalNotFoundException();
    _ledger.approveVaultReceipt(receiptId, finalizedAt: finalizedAt);
  }

  @override
  Future<void> approveIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) async {
    final transfer = _transfer(transferId);
    if (transfer.recipientId != driverId) {
      throw const ApprovalNotFoundException();
    }
    _ledger.approve(transferId, finalizedAt: finalizedAt);
  }

  @override
  Future<void> declineIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) async {
    final transfer = _transfer(transferId);
    if (transfer.recipientId != driverId) {
      throw const ApprovalNotFoundException();
    }
    _ledger.reject(transferId, finalizedAt: finalizedAt);
  }

  @override
  Future<void> confirmRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) async {
    final approval = _roadApproval(approvalId);
    if (approval.driverId != driverId) throw const ApprovalNotFoundException();
    _ledger.confirmRoadExpense(approvalId, finalizedAt: finalizedAt);
  }

  @override
  Future<void> rejectRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) async {
    final approval = _roadApproval(approvalId);
    if (approval.driverId != driverId) throw const ApprovalNotFoundException();
    _ledger.rejectRoadExpense(approvalId, finalizedAt: finalizedAt);
  }

  ApprovalItem _vault(CustodyReceipt receipt) {
    final timing = _ledger.timingFor(receipt.id);
    return ApprovalItem(
      id: receipt.id,
      kind: ApprovalKind.vault,
      outcome: receipt.status == CustodyReceiptStatus.pending
          ? ApprovalOutcome.pending
          : ApprovalOutcome.approved,
      amountEgp: receipt.amountEgp,
      occurredAt: receipt.createdAt,
      finalizedAt: receipt.finalizedAt,
      recency: timing?.recency,
      minutes: timing?.minutes ?? 0,
      reference: receipt.id,
    );
  }

  ApprovalItem _driver(CashTransfer transfer) {
    final timing = _ledger.timingFor(transfer.id);
    return ApprovalItem(
      id: transfer.id,
      kind: ApprovalKind.driver,
      outcome: switch (transfer.status) {
        TransferStatus.pending => ApprovalOutcome.pending,
        TransferStatus.approved => ApprovalOutcome.approved,
        TransferStatus.rejected => ApprovalOutcome.rejected,
      },
      amountEgp: transfer.amountEgp,
      occurredAt: transfer.createdAt,
      finalizedAt: transfer.finalizedAt,
      recency: timing?.recency,
      minutes: timing?.minutes ?? 0,
      counterpartyName: _ledger.nameOf(transfer.senderId),
      counterpartyId: transfer.senderId,
      reference: transfer.id,
    );
  }

  ApprovalItem _road(RoadExpenseApproval approval) {
    return ApprovalItem(
      id: approval.id,
      kind: ApprovalKind.roadExpense,
      outcome: switch (approval.status) {
        RoadExpenseStatus.pending => ApprovalOutcome.pending,
        RoadExpenseStatus.approved => ApprovalOutcome.approved,
        RoadExpenseStatus.rejected => ApprovalOutcome.rejected,
      },
      amountEgp: approval.amountEgp,
      occurredAt: approval.submittedAt,
      finalizedAt: approval.finalizedAt,
      reference: approval.id,
      periodStart: approval.periodStart,
      periodEnd: approval.periodEnd,
      submittedBy: approval.submittedBy,
      vehicle: approval.vehicle,
      perTripEgp: approval.perTripEgp,
      lines: [
        for (final line in approval.lines)
          ApprovalTripLine(
            code: line.code,
            origin: line.origin,
            destination: line.destination,
            date: line.date,
            amountEgp: line.amountEgp,
            tripNumber: line.tripNumber,
          ),
      ],
    );
  }

  CustodyReceipt _receipt(String id) {
    for (final receipt in _ledger.custodyReceipts) {
      if (receipt.id == id) return receipt;
    }
    throw const ApprovalNotFoundException();
  }

  CashTransfer _transfer(String id) {
    for (final transfer in _ledger.transfers) {
      if (transfer.id == id) return transfer;
    }
    throw const ApprovalNotFoundException();
  }

  RoadExpenseApproval _roadApproval(String id) {
    for (final approval in _ledger.roadExpenseApprovals) {
      if (approval.id == id) return approval;
    }
    throw const ApprovalNotFoundException();
  }

  int _rank(ApprovalKind kind) {
    return switch (kind) {
      ApprovalKind.vault => 0,
      ApprovalKind.driver => 1,
      ApprovalKind.roadExpense => 2,
    };
  }
}
