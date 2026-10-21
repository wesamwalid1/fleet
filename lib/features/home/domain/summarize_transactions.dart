import 'entities/financial_summary.dart';
import 'entities/money_transaction.dart';
import 'failures/invalid_transaction_amount_exception.dart';

/// Charge is the sum of cash received.
/// Balance is cash received minus expenses.
/// [maxLimitEgp] is copied through and is not derived from transactions.
///
/// Each [MoneyTransaction.amountEgp] must be greater than zero.
/// A non-positive amount throws [InvalidTransactionAmountException].
FinancialSummary summarizeTransactions({
  required int maxLimitEgp,
  required List<MoneyTransaction> transactions,
}) {
  var chargeEgp = 0;
  var balanceEgp = 0;

  for (final transaction in transactions) {
    if (transaction.amountEgp <= 0) {
      throw InvalidTransactionAmountException(
        type: transaction.type,
        amountEgp: transaction.amountEgp,
      );
    }

    switch (transaction.type) {
      case MoneyTransactionType.cashReceived:
        chargeEgp += transaction.amountEgp;
        balanceEgp += transaction.amountEgp;
      case MoneyTransactionType.expense:
        balanceEgp -= transaction.amountEgp;
    }
  }

  return FinancialSummary(
    balanceEgp: balanceEgp,
    chargeEgp: chargeEgp,
    maxLimitEgp: maxLimitEgp,
  );
}
