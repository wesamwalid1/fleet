import '../../../finance/data/datasources/mock_cash_ledger.dart';
import '../../../finance/domain/entities/cash_transfer.dart';
import '../../../finance/domain/entities/custody_receipt.dart';
import '../../../finance/domain/entities/expense_request.dart';
import '../../../finance/domain/entities/road_expense_approval.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final MockCashLedger _ledger;

  const HistoryRepositoryImpl(this._ledger);

  @override
  Stream<void> get changes => _ledger.changes;

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) async {
    final entries = <HistoryEntry>[
      for (final expense in _ledger.expenses)
        if (expense.driverId == driverId) _expense(expense),
      for (final receipt in _ledger.custodyReceipts)
        if (receipt.driverId == driverId) _vault(receipt),
      for (final transfer in _ledger.transfers)
        if (transfer.recipientId == driverId)
          _incoming(transfer)
        else if (transfer.senderId == driverId)
          _outgoing(transfer),
      for (final approval in _ledger.roadExpenseApprovals)
        if (approval.driverId == driverId &&
            approval.status != RoadExpenseStatus.pending)
          _roadExpense(approval),
    ];
    entries.sort((a, b) {
      final byTime = b.occurredAt.compareTo(a.occurredAt);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
    return entries;
  }

  HistoryEntry _expense(ExpenseRequest expense) {
    return HistoryEntry(
      id: expense.id,
      kind: HistoryKind.expense,
      amountEgp: expense.amountEgp,
      credit: false,
      occurredAt: expense.createdAt,
      status: HistoryDisplayStatus.recorded,
      settlementType: expense.settlementType,
      tripCode: _ledger.codeForTrip(expense.tripId),
    );
  }

  HistoryEntry _vault(CustodyReceipt receipt) {
    return HistoryEntry(
      id: receipt.id,
      kind: HistoryKind.vault,
      amountEgp: receipt.amountEgp,
      credit: true,
      occurredAt: receipt.createdAt,
      status: receipt.status == CustodyReceiptStatus.pending
          ? HistoryDisplayStatus.awaitingApproval
          : HistoryDisplayStatus.approved,
    );
  }

  HistoryEntry _incoming(CashTransfer transfer) {
    return HistoryEntry(
      id: transfer.id,
      kind: HistoryKind.incoming,
      amountEgp: transfer.amountEgp,
      credit: true,
      occurredAt: transfer.createdAt,
      status: _transferStatus(transfer.status, incoming: true),
      counterpartyName: _ledger.nameOf(transfer.senderId),
      counterpartyId: transfer.senderId,
    );
  }

  HistoryEntry _roadExpense(RoadExpenseApproval approval) {
    return HistoryEntry(
      id: approval.id,
      kind: HistoryKind.roadExpense,
      amountEgp: approval.amountEgp,
      credit: false,
      occurredAt: approval.submittedAt,
      status: approval.status == RoadExpenseStatus.rejected
          ? HistoryDisplayStatus.rejected
          : HistoryDisplayStatus.approved,
      tripCode: approval.id,
    );
  }

  HistoryEntry _outgoing(CashTransfer transfer) {
    return HistoryEntry(
      id: transfer.id,
      kind: HistoryKind.outgoing,
      amountEgp: transfer.amountEgp,
      credit: false,
      occurredAt: transfer.createdAt,
      status: _transferStatus(transfer.status, incoming: false),
      counterpartyName: _ledger.nameOf(transfer.recipientId),
      counterpartyId: transfer.recipientId,
    );
  }

  HistoryDisplayStatus _transferStatus(
    TransferStatus status, {
    required bool incoming,
  }) {
    return switch (status) {
      TransferStatus.pending =>
        incoming
            ? HistoryDisplayStatus.awaitingApproval
            : HistoryDisplayStatus.pendingConfirm,
      TransferStatus.approved =>
        incoming
            ? HistoryDisplayStatus.approved
            : HistoryDisplayStatus.confirmed,
      TransferStatus.rejected => HistoryDisplayStatus.rejected,
    };
  }
}
