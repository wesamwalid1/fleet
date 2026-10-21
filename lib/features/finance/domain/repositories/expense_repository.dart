import '../entities/assigned_trip.dart';
import '../entities/expense_attachment.dart';
import '../entities/expense_request.dart';
import '../entities/settlement_type.dart';

abstract class ExpenseRepository {
  Future<List<AssignedTrip>> getAssignedTrips(String driverId);

  Future<int> getAvailableBalance(String driverId);

  Future<ExpenseRequest> createRecordedExpense({
    required String driverId,
    required String tripId,
    required SettlementType settlementType,
    required int amountEgp,
    required String? notes,
    required List<ExpenseAttachment> attachments,
    required DateTime createdAt,
  });

  /// A recorded expense is final. Approval, rejection, and refunds do not apply.
  Future<ExpenseRequest> approve(String expenseId);

  /// A recorded expense is final and is never refunded.
  Future<ExpenseRequest> reject(String expenseId);

  /// A recorded expense cannot be withdrawn by the driver.
  Future<void> cancel(String expenseId);

  Future<List<ExpenseRequest>> getExpenses();
}
