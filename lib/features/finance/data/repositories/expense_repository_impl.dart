import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/expense_attachment.dart';
import '../../domain/entities/expense_request.dart';
import '../../domain/entities/expense_trip_scope.dart';
import '../../domain/entities/settlement_type.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/mock_cash_ledger.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final MockCashLedger _ledger;

  const ExpenseRepositoryImpl(this._ledger);

  @override
  Future<List<AssignedTrip>> getAssignedTrips(String driverId) async {
    return _ledger.eligibleTrips(driverId);
  }

  @override
  Future<int> getAvailableBalance(String driverId) async {
    return _ledger.balanceOf(driverId);
  }

  @override
  Future<ExpenseRequest> createRecordedExpense({
    required String driverId,
    required String tripId,
    required SettlementType settlementType,
    required int amountEgp,
    required String? notes,
    required List<ExpenseAttachment> attachments,
    required DateTime createdAt,
    ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
  }) async {
    return _ledger.createRecordedExpense(
      driverId: driverId,
      tripId: tripId,
      settlementType: settlementType,
      amountEgp: amountEgp,
      notes: notes,
      attachments: attachments,
      createdAt: createdAt,
      tripScope: tripScope,
    );
  }

  @override
  Future<ExpenseRequest> approve(String expenseId) async {
    return _ledger.approveExpense(expenseId);
  }

  @override
  Future<ExpenseRequest> reject(String expenseId) async {
    return _ledger.rejectExpense(expenseId);
  }

  @override
  Future<void> cancel(String expenseId) async {
    _ledger.cancelExpense(expenseId);
  }

  @override
  Future<List<ExpenseRequest>> getExpenses() async {
    return _ledger.expenses;
  }
}
