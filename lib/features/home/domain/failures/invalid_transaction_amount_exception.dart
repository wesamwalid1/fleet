import '../entities/money_transaction.dart';

final class InvalidTransactionAmountException implements Exception {
  final MoneyTransactionType type;
  final int amountEgp;

  const InvalidTransactionAmountException({
    required this.type,
    required this.amountEgp,
  });

  @override
  String toString() {
    return 'InvalidTransactionAmountException($type, $amountEgp)';
  }
}
