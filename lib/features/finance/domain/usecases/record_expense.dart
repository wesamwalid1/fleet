import '../entities/expense_attachment.dart';
import '../entities/expense_trip_scope.dart';
import '../entities/record_expense_result.dart';
import '../entities/settlement_type.dart';
import '../failures/expense_exception.dart';
import '../repositories/expense_repository.dart';

class RecordExpense {
  final ExpenseRepository _repository;

  const RecordExpense(this._repository);

  Future<RecordExpenseResult> call({
    required String driverId,
    required String? tripId,
    required SettlementType? settlementType,
    required int amountEgp,
    String? notes,
    List<ExpenseAttachment> attachments = const [],
    DateTime? createdAt,
    ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
  }) async {
    if (tripId == null || tripId.isEmpty) {
      throw const MissingTripException();
    }
    if (settlementType == null) {
      throw const MissingSettlementTypeException();
    }
    if (amountEgp <= 0) {
      throw InvalidExpenseAmountException(amountEgp);
    }

    final expense = await _repository.createRecordedExpense(
      driverId: driverId,
      tripId: tripId,
      settlementType: settlementType,
      amountEgp: amountEgp,
      notes: notes,
      attachments: attachments,
      createdAt: createdAt ?? DateTime.now(),
      tripScope: tripScope,
    );
    final balance = await _repository.getAvailableBalance(driverId);
    return RecordExpenseResult(expense: expense, balanceEgp: balance);
  }
}
