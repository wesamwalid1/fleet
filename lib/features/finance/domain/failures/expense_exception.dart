sealed class ExpenseException implements Exception {
  const ExpenseException();
}

final class InvalidExpenseAmountException extends ExpenseException {
  final int amountEgp;

  const InvalidExpenseAmountException(this.amountEgp);
}

final class InsufficientExpenseBalanceException extends ExpenseException {
  const InsufficientExpenseBalanceException();
}

final class MissingTripException extends ExpenseException {
  const MissingTripException();
}

final class IneligibleTripException extends ExpenseException {
  const IneligibleTripException();
}

final class TripAssignedToAnotherDriverException extends ExpenseException {
  const TripAssignedToAnotherDriverException();
}

final class MissingSettlementTypeException extends ExpenseException {
  const MissingSettlementTypeException();
}

final class ExpenseNotFoundException extends ExpenseException {
  const ExpenseNotFoundException();
}

final class ExpenseAlreadyFinalizedException extends ExpenseException {
  const ExpenseAlreadyFinalizedException();
}

final class ExpenseCannotBeCancelledException extends ExpenseException {
  const ExpenseCannotBeCancelledException();
}

final class ExpenseAttachmentFailedException extends ExpenseException {
  const ExpenseAttachmentFailedException();
}
