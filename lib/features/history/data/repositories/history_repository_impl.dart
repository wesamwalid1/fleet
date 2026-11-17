import '../../../../core/debug/mock_network_delay.dart';
import '../../../finance/data/datasources/mock_cash_ledger.dart';
import '../../../finance/domain/entities/cash_request.dart';
import '../../../finance/domain/entities/cash_transfer.dart';
import '../../../finance/domain/entities/custody_receipt.dart';
import '../../../finance/domain/entities/expense_request.dart';
import '../../../finance/domain/entities/road_expense_approval.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final MockCashLedger _ledger;
  final Duration _networkDelay;

  HistoryRepositoryImpl(this._ledger, {Duration? networkDelay})
    : _networkDelay = MockNetworkDelay.resolve(override: networkDelay);

  @override
  Stream<void> get changes => _ledger.changes;

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) async {
    await MockNetworkDelay.wait(override: _networkDelay);
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
        if (approval.driverId == driverId) _roadExpense(approval),
      for (final request in _ledger.cashRequests)
        if (request.driverId == driverId) _cashRequest(request),
    ];
    entries.sort(_byUpdatedAtDesc);
    return entries;
  }

  static int _byUpdatedAtDesc(HistoryEntry a, HistoryEntry b) {
    final byTime = b.updatedAt.compareTo(a.updatedAt);
    if (byTime != 0) return byTime;
    return b.id.compareTo(a.id);
  }

  HistoryEntry _expense(ExpenseRequest expense) {
    return HistoryEntry(
      id: expense.id,
      kind: HistoryKind.expense,
      amountEgp: expense.amountEgp,
      credit: false,
      createdAt: expense.createdAt,
      updatedAt: expense.createdAt,
      status: HistoryDisplayStatus.recorded,
      settlementType: expense.settlementType,
      tripCode: _ledger.codeForTrip(expense.tripId),
      tripId: expense.tripId,
      note: expense.notes,
      balanceBeforeEgp: expense.balanceBeforeEgp,
      balanceAfterEgp: expense.balanceAfterEgp,
    );
  }

  HistoryEntry _vault(CustodyReceipt receipt) {
    final createdAt = receipt.createdAt;
    return HistoryEntry(
      id: receipt.id,
      kind: HistoryKind.vault,
      amountEgp: receipt.amountEgp,
      credit: true,
      createdAt: createdAt,
      updatedAt: historyActivityAt(
        createdAt: createdAt,
        updatedAt: receipt.finalizedAt,
      ),
      status: receipt.status == CustodyReceiptStatus.pending
          ? HistoryDisplayStatus.awaitingApproval
          : HistoryDisplayStatus.approved,
      balanceBeforeEgp: receipt.balanceBeforeEgp,
      balanceAfterEgp: receipt.balanceAfterEgp,
    );
  }

  HistoryEntry _incoming(CashTransfer transfer) {
    final createdAt = transfer.createdAt;
    return HistoryEntry(
      id: transfer.id,
      kind: HistoryKind.incoming,
      amountEgp: transfer.amountEgp,
      credit: true,
      createdAt: createdAt,
      updatedAt: historyActivityAt(
        createdAt: createdAt,
        updatedAt: transfer.finalizedAt,
      ),
      status: _transferStatus(transfer.status, incoming: true),
      counterpartyName: _ledger.nameOf(transfer.senderId),
      counterpartyId: transfer.senderId,
      balanceBeforeEgp: transfer.recipientBalanceBeforeEgp,
      balanceAfterEgp: transfer.recipientBalanceAfterEgp,
    );
  }

  HistoryEntry _roadExpense(RoadExpenseApproval approval) {
    final createdAt = approval.submittedAt;
    final relatedTripCodes = <String>[];
    final relatedTripIds = <String>[];
    final seenCodes = <String>{};
    final seenIds = <String>{};
    for (final line in approval.lines) {
      final code = line.code.trim();
      if (code.isEmpty || !seenCodes.add(code)) continue;
      relatedTripCodes.add(code);
      final trip = _ledger.tripByCode(code);
      if (trip != null && seenIds.add(trip.id)) {
        relatedTripIds.add(trip.id);
      }
    }
    return HistoryEntry(
      id: approval.id,
      kind: HistoryKind.roadExpense,
      amountEgp: approval.amountEgp,
      credit: false,
      createdAt: createdAt,
      updatedAt: historyActivityAt(
        createdAt: createdAt,
        updatedAt: approval.finalizedAt,
      ),
      status: switch (approval.status) {
        RoadExpenseStatus.pending => HistoryDisplayStatus.awaitingApproval,
        RoadExpenseStatus.rejected => HistoryDisplayStatus.rejected,
        RoadExpenseStatus.approved => HistoryDisplayStatus.approved,
      },
      relatedTripIds: List.unmodifiable(relatedTripIds),
      relatedTripCodes: List.unmodifiable(relatedTripCodes),
      note: approval.submittedBy,
      // Road expense confirm/reject does not move the driver balance.
    );
  }

  HistoryEntry _outgoing(CashTransfer transfer) {
    final createdAt = transfer.createdAt;
    return HistoryEntry(
      id: transfer.id,
      kind: HistoryKind.outgoing,
      amountEgp: transfer.amountEgp,
      credit: false,
      createdAt: createdAt,
      updatedAt: historyActivityAt(
        createdAt: createdAt,
        updatedAt: transfer.finalizedAt,
      ),
      status: _transferStatus(transfer.status, incoming: false),
      counterpartyName: _ledger.nameOf(transfer.recipientId),
      counterpartyId: transfer.recipientId,
      balanceBeforeEgp: transfer.senderBalanceBeforeEgp,
      balanceAfterEgp: transfer.senderBalanceAfterEgp,
    );
  }

  HistoryEntry _cashRequest(CashRequest request) {
    final isRequestCash = request.type == CashRequestType.requestCash;
    final createdAt = request.createdAt;
    return HistoryEntry(
      id: request.id,
      kind: isRequestCash ? HistoryKind.requestCash : HistoryKind.withdraw,
      amountEgp: request.amountEgp,
      credit: isRequestCash,
      createdAt: createdAt,
      updatedAt: historyActivityAt(
        createdAt: createdAt,
        updatedAt: request.processedAt,
      ),
      status: switch (request.status) {
        CashRequestStatus.pending => HistoryDisplayStatus.pendingConfirm,
        CashRequestStatus.approved => HistoryDisplayStatus.approved,
        CashRequestStatus.rejected => HistoryDisplayStatus.rejected,
      },
      note: request.note,
      requestNumber: request.requestNumber,
      balanceBeforeEgp: request.balanceBeforeEgp,
      balanceAfterEgp: request.balanceAfterEgp,
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
