sealed class CashRequestException implements Exception {
  const CashRequestException();
}

final class InvalidCashRequestAmountException extends CashRequestException {
  final int amountEgp;

  const InvalidCashRequestAmountException(this.amountEgp);
}

final class InsufficientRequestCapacityException extends CashRequestException {
  const InsufficientRequestCapacityException();
}

final class InsufficientWithdrawBalanceException extends CashRequestException {
  const InsufficientWithdrawBalanceException();
}

final class CashRequestNotFoundException extends CashRequestException {
  const CashRequestNotFoundException();
}

final class CashRequestAlreadyFinalizedException extends CashRequestException {
  const CashRequestAlreadyFinalizedException();
}
