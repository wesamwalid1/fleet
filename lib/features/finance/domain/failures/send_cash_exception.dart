sealed class SendCashException implements Exception {
  const SendCashException();
}

final class InvalidTransferAmountException extends SendCashException {
  final int amountEgp;

  const InvalidTransferAmountException(this.amountEgp);
}

final class InsufficientBalanceException extends SendCashException {
  const InsufficientBalanceException();
}

final class SendCashToSelfException extends SendCashException {
  const SendCashToSelfException();
}

final class UnknownDriverException extends SendCashException {
  final String driverId;

  const UnknownDriverException(this.driverId);
}

final class TransferNotFoundException extends SendCashException {
  const TransferNotFoundException();
}

final class TransferAlreadyFinalizedException extends SendCashException {
  const TransferAlreadyFinalizedException();
}
