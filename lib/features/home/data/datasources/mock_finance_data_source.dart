import '../../domain/entities/money_transaction.dart';
import '../models/money_transaction_model.dart';

/// Cash received: 2,000 + 1,200 = 3,200 charge.
/// Expenses: 700 + 300 = 1,000.
/// Balance: 3,200 − 1,000 = 2,200.
/// Max limit is an account setting of 5,000 and is not a transaction.
class MockFinanceDataSource {
  static const int maxLimitEgp = 5000;

  static const List<MoneyTransactionModel> transactions = [
    MoneyTransactionModel(
      type: MoneyTransactionType.cashReceived,
      amountEgp: 2000,
      label: 'Vault cash',
    ),
    MoneyTransactionModel(
      type: MoneyTransactionType.cashReceived,
      amountEgp: 1200,
      label: 'Additional vault cash',
    ),
    MoneyTransactionModel(
      type: MoneyTransactionType.expense,
      amountEgp: 700,
      label: 'Fuel',
    ),
    MoneyTransactionModel(
      type: MoneyTransactionType.expense,
      amountEgp: 300,
      label: 'Road fees',
    ),
  ];

  const MockFinanceDataSource();

  Future<FinanceAccountModel> loadAccount() async {
    return const FinanceAccountModel(
      maxLimitEgp: maxLimitEgp,
      transactions: transactions,
    );
  }
}
