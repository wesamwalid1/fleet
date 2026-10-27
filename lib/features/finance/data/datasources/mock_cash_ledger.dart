import 'dart:async';

import '../../domain/entities/approval_timing.dart';
import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/cash_transfer.dart';
import '../../domain/entities/custody_receipt.dart';
import '../../domain/entities/expense_attachment.dart';
import '../../domain/entities/expense_request.dart';
import '../../domain/entities/expense_trip_scope.dart';
import '../../domain/entities/finance_driver.dart';
import '../../domain/entities/finance_event.dart';
import '../../domain/entities/road_expense_approval.dart';
import '../../domain/entities/settlement_type.dart';
import '../../domain/failures/approval_exception.dart';
import '../../domain/failures/expense_exception.dart';
import '../../domain/failures/send_cash_exception.dart';
import 'mock_assigned_trips.dart';

class _DriverSeed {
  final String id;
  final String fullName;
  final int balanceEgp;

  const _DriverSeed(this.id, this.fullName, this.balanceEgp);
}

/// In-memory balances and transfer requests for the current session.
///
/// The sender's opening balance is supplied by the caller so it stays aligned
/// with the transaction summary. Recipient balances that are not shown in the
/// driver list screenshot are mock values: Mohamed Said 900, Sami Hassan 750.
class MockCashLedger {
  static const senderId = 'DR-001';

  static const _recipientOrder = ['DR-003', 'DR-002', 'DR-004'];

  final Map<String, String> _names = {};
  final Map<String, int> _balances = {};
  final List<CashTransfer> _transfers = [];
  final List<CustodyReceipt> _receipts = [];
  final List<RoadExpenseApproval> _roads = [];
  final Map<String, ApprovalTiming> _timings = {};
  final List<AssignedTrip> _trips = List.of(MockAssignedTrips.trips);
  final List<ExpenseRequest> _expenses = [];
  int _sequence = 124;
  int _expenseSequence = 412138;
  bool _approvalsSeeded = false;
  final List<void Function(FinanceEvent event)> _listeners = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires after every successful change to balances, transfers, receipts,
  /// road expenses, or expenses. Failed operations and seeding do not fire.
  Stream<void> get changes => _changes.stream;

  void _changed() => _changes.add(null);

  /// Listeners hear completed outcomes only; seeding does not emit.
  void addListener(void Function(FinanceEvent event) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(FinanceEvent event) listener) {
    _listeners.remove(listener);
  }

  void _emit(FinanceEvent event) {
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }

  MockCashLedger({required int senderBalanceEgp}) {
    const seeds = [
      _DriverSeed(senderId, 'Ahmed Ali', 0),
      _DriverSeed('DR-003', 'Khaled Ramadan', 1100),
      _DriverSeed('DR-002', 'Mohamed Said', 900),
      _DriverSeed('DR-004', 'Sami Hassan', 750),
    ];
    for (final seed in seeds) {
      _names[seed.id] = seed.fullName;
      _balances[seed.id] = seed.id == senderId
          ? senderBalanceEgp
          : seed.balanceEgp;
    }
  }

  int balanceOf(String driverId) {
    final balance = _balances[driverId];
    if (balance == null) throw UnknownDriverException(driverId);
    return balance;
  }

  List<FinanceDriver> recipients(String senderId) {
    return [
      for (final id in _recipientOrder)
        if (id != senderId) _driver(id),
    ];
  }

  List<CashTransfer> get transfers => List.unmodifiable(_transfers);

  List<CustodyReceipt> get custodyReceipts => List.unmodifiable(_receipts);

  List<RoadExpenseApproval> get roadExpenseApprovals =>
      List.unmodifiable(_roads);

  List<ExpenseRequest> get expenses => List.unmodifiable(_expenses);

  ApprovalTiming? timingFor(String id) => _timings[id];

  String nameOf(String driverId) {
    final name = _names[driverId];
    if (name == null) throw UnknownDriverException(driverId);
    return name;
  }

  String codeForTrip(String tripId) {
    for (final trip in _trips) {
      if (trip.id == tripId) return trip.code;
    }
    return tripId;
  }

  /// Session approvals for the signed-in driver.
  ///
  /// Historical receipts are already included in the opening balance, so this
  /// does not move money. The pending incoming transfer was deducted from the
  /// sender when it was created, and that deduction is already reflected in
  /// the sender's opening balance.
  void seedDriverApprovals() {
    if (_approvalsSeeded) return;
    _approvalsSeeded = true;

    _receipts.add(
      CustodyReceipt(
        id: 'DSB-2025-0441',
        driverId: senderId,
        amountEgp: 2000,
        createdAt: DateTime(2025, 5, 13),
        status: CustodyReceiptStatus.pending,
      ),
    );
    _timings['DSB-2025-0441'] = const ApprovalTiming.justNow();
    _receipts.add(
      CustodyReceipt(
        id: 'DSB-2025-0301',
        driverId: senderId,
        amountEgp: 3000,
        createdAt: DateTime(2025, 5, 10, 10),
        status: CustodyReceiptStatus.approved,
        finalizedAt: DateTime(2025, 5, 10, 10),
      ),
    );

    _transfers.add(
      CashTransfer(
        id: 'TRF-2025-0123',
        senderId: 'DR-003',
        recipientId: senderId,
        amountEgp: 500,
        createdAt: DateTime(2025, 5, 13),
        status: TransferStatus.pending,
      ),
    );
    _timings['TRF-2025-0123'] = const ApprovalTiming.minutesAgo(5);
    _transfers.add(
      CashTransfer(
        id: 'TRF-2025-0090',
        senderId: 'DR-004',
        recipientId: senderId,
        amountEgp: 800,
        createdAt: DateTime(2025, 5, 12, 14, 30),
        status: TransferStatus.approved,
        finalizedAt: DateTime(2025, 5, 12, 14, 30),
      ),
    );

    _roads.add(
      RoadExpenseApproval(
        id: 'RE-2026-1041',
        driverId: senderId,
        amountEgp: 300,
        submittedAt: DateTime(2026, 6, 22, 10, 15),
        periodStart: DateTime(2026, 5, 1),
        periodEnd: DateTime(2026, 5, 31),
        submittedBy: 'Admin · Hassan Allam',
        vehicle: 'Telescope',
        perTripEgp: 100,
        status: RoadExpenseStatus.pending,
        lines: [
          RoadExpenseLine(
            code: 'TR-2026-0881',
            origin: 'Cairo',
            destination: 'Alexandria',
            date: DateTime(2026, 5, 5),
            amountEgp: 100,
            tripNumber: 1,
          ),
          RoadExpenseLine(
            code: 'TR-2026-0904',
            origin: 'Alexandria',
            destination: 'Suez',
            date: DateTime(2026, 5, 14),
            amountEgp: 100,
            tripNumber: 2,
          ),
          RoadExpenseLine(
            code: 'TR-2026-0927',
            origin: 'Suez',
            destination: 'Cairo',
            date: DateTime(2026, 5, 28),
            amountEgp: 100,
            tripNumber: 3,
          ),
        ],
      ),
    );
  }

  void addPendingVaultReceipt({
    required String id,
    required int amountEgp,
    required DateTime createdAt,
    String driverId = senderId,
  }) {
    final receipt = CustodyReceipt(
      id: id,
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      status: CustodyReceiptStatus.pending,
    );
    _receipts.add(receipt);
    _emit(VaultReceiptCreated(receipt));
    _changed();
  }

  CustodyReceipt approveVaultReceipt(
    String receiptId, {
    DateTime? finalizedAt,
  }) {
    final index = _receiptIndex(receiptId);
    final receipt = _receipts[index];
    if (receipt.status != CustodyReceiptStatus.pending) {
      throw const ApprovalAlreadyFinalizedException();
    }
    final balance = _balances[receipt.driverId];
    if (balance == null) throw UnknownDriverException(receipt.driverId);
    _balances[receipt.driverId] = balance + receipt.amountEgp;
    final updated = receipt.copyWith(
      status: CustodyReceiptStatus.approved,
      finalizedAt: finalizedAt ?? DateTime.now(),
    );
    _receipts[index] = updated;
    _changed();
    return updated;
  }

  RoadExpenseApproval confirmRoadExpense(
    String approvalId, {
    DateTime? finalizedAt,
  }) {
    return _finalizeRoadExpense(
      approvalId,
      RoadExpenseStatus.approved,
      finalizedAt: finalizedAt,
    );
  }

  RoadExpenseApproval rejectRoadExpense(
    String approvalId, {
    DateTime? finalizedAt,
  }) {
    return _finalizeRoadExpense(
      approvalId,
      RoadExpenseStatus.rejected,
      finalizedAt: finalizedAt,
    );
  }

  RoadExpenseApproval _finalizeRoadExpense(
    String approvalId,
    RoadExpenseStatus status, {
    DateTime? finalizedAt,
  }) {
    final index = _roadIndex(approvalId);
    final approval = _roads[index];
    if (approval.status != RoadExpenseStatus.pending) {
      throw const ApprovalAlreadyFinalizedException();
    }
    final updated = approval.copyWith(
      status: status,
      finalizedAt: finalizedAt ?? DateTime.now(),
    );
    _roads[index] = updated;
    _changed();
    return updated;
  }

  int _receiptIndex(String receiptId) {
    final index = _receipts.indexWhere((receipt) => receipt.id == receiptId);
    if (index < 0) throw const ApprovalNotFoundException();
    return index;
  }

  int _roadIndex(String approvalId) {
    final index = _roads.indexWhere((approval) => approval.id == approvalId);
    if (index < 0) throw const ApprovalNotFoundException();
    return index;
  }

  List<AssignedTrip> eligibleTrips(String driverId) {
    return [
      for (final trip in _trips)
        if (trip.driverId == driverId &&
            (trip.status == TripStatus.active ||
                trip.status == TripStatus.completed))
          trip,
    ];
  }

  ExpenseRequest createRecordedExpense({
    required String driverId,
    required String tripId,
    required SettlementType settlementType,
    required int amountEgp,
    required String? notes,
    required List<ExpenseAttachment> attachments,
    required DateTime createdAt,
    ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
  }) {
    if (tripId.isEmpty) throw const MissingTripException();
    if (amountEgp <= 0) throw InvalidExpenseAmountException(amountEgp);
    final trip = _tripById(tripId);
    if (trip.driverId != driverId) {
      throw const TripAssignedToAnotherDriverException();
    }
    if (!tripScope.allows(trip)) throw const IneligibleTripException();
    final balance = _balances[driverId];
    if (balance == null) throw UnknownDriverException(driverId);
    if (amountEgp > balance) {
      throw const InsufficientExpenseBalanceException();
    }

    final trimmed = notes?.trim();
    final storedNotes = trimmed == null || trimmed.isEmpty ? null : trimmed;
    _balances[driverId] = balance - amountEgp;
    final expense = ExpenseRequest(
      id: 'EXP-$_expenseSequence',
      driverId: driverId,
      tripId: trip.id,
      settlementType: settlementType,
      amountEgp: amountEgp,
      notes: storedNotes,
      attachments: List.unmodifiable(attachments),
      createdAt: createdAt,
      status: ExpenseStatus.recorded,
    );
    _expenseSequence += 1;
    _expenses.add(expense);
    _emit(ExpenseRecorded(expense));
    _changed();
    return expense;
  }

  ExpenseRequest approveExpense(String expenseId) {
    _expenseIndex(expenseId);
    throw const ExpenseAlreadyFinalizedException();
  }

  ExpenseRequest rejectExpense(String expenseId) {
    _expenseIndex(expenseId);
    throw const ExpenseAlreadyFinalizedException();
  }

  void cancelExpense(String expenseId) {
    _expenseIndex(expenseId);
    throw const ExpenseCannotBeCancelledException();
  }

  AssignedTrip _tripById(String tripId) {
    for (final trip in _trips) {
      if (trip.id == tripId) return trip;
    }
    throw const IneligibleTripException();
  }

  int _expenseIndex(String expenseId) {
    final index = _expenses.indexWhere((expense) => expense.id == expenseId);
    if (index < 0) throw const ExpenseNotFoundException();
    return index;
  }

  CashTransfer createPendingTransfer({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    required DateTime createdAt,
  }) {
    if (senderId == recipientId) throw const SendCashToSelfException();
    if (amountEgp <= 0) throw InvalidTransferAmountException(amountEgp);
    final senderBalance = _balances[senderId];
    final recipientBalance = _balances[recipientId];
    if (senderBalance == null) throw UnknownDriverException(senderId);
    if (recipientBalance == null) throw UnknownDriverException(recipientId);
    if (amountEgp > senderBalance) throw const InsufficientBalanceException();

    _balances[senderId] = senderBalance - amountEgp;
    final transfer = CashTransfer(
      id: 'TRF-${createdAt.year}-${_sequence.toString().padLeft(4, '0')}',
      senderId: senderId,
      recipientId: recipientId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      status: TransferStatus.pending,
    );
    _sequence += 1;
    _transfers.add(transfer);
    _emit(TransferCreated(transfer));
    _changed();
    return transfer;
  }

  CashTransfer approve(String transferId, {DateTime? finalizedAt}) {
    final index = _indexOf(transferId);
    final transfer = _transfers[index];
    if (transfer.status != TransferStatus.pending) {
      throw const TransferAlreadyFinalizedException();
    }
    final recipientBalance = _balances[transfer.recipientId];
    if (recipientBalance == null) {
      throw UnknownDriverException(transfer.recipientId);
    }
    _balances[transfer.recipientId] = recipientBalance + transfer.amountEgp;
    final updated = transfer.copyWith(
      status: TransferStatus.approved,
      finalizedAt: finalizedAt ?? DateTime.now(),
    );
    _transfers[index] = updated;
    _emit(TransferApproved(updated));
    _changed();
    return updated;
  }

  CashTransfer reject(String transferId, {DateTime? finalizedAt}) {
    final index = _indexOf(transferId);
    final transfer = _transfers[index];
    if (transfer.status != TransferStatus.pending) {
      throw const TransferAlreadyFinalizedException();
    }
    final senderBalance = _balances[transfer.senderId];
    if (senderBalance == null) throw UnknownDriverException(transfer.senderId);
    _balances[transfer.senderId] = senderBalance + transfer.amountEgp;
    final updated = transfer.copyWith(
      status: TransferStatus.rejected,
      finalizedAt: finalizedAt ?? DateTime.now(),
    );
    _transfers[index] = updated;
    _emit(TransferRejected(updated));
    _changed();
    return updated;
  }

  int _indexOf(String transferId) {
    final index = _transfers.indexWhere(
      (transfer) => transfer.id == transferId,
    );
    if (index < 0) throw const TransferNotFoundException();
    return index;
  }

  FinanceDriver _driver(String id) {
    return FinanceDriver(
      id: id,
      fullName: _names[id]!,
      balanceEgp: _balances[id]!,
    );
  }
}
