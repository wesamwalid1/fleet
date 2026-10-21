import '../../domain/entities/money_transaction.dart';

class MoneyTransactionModel {
  final MoneyTransactionType type;
  final int amountEgp;
  final String label;

  const MoneyTransactionModel({
    required this.type,
    required this.amountEgp,
    required this.label,
  });

  MoneyTransaction toEntity() {
    return MoneyTransaction(type: type, amountEgp: amountEgp, label: label);
  }
}

class FinanceAccountModel {
  final int maxLimitEgp;
  final List<MoneyTransactionModel> transactions;

  const FinanceAccountModel({
    required this.maxLimitEgp,
    required this.transactions,
  });
}
