import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/finance_repository_impl.dart';
import 'package:driver_portal_app/features/home/domain/entities/money_transaction.dart';
import 'package:driver_portal_app/features/home/domain/failures/invalid_transaction_amount_exception.dart';
import 'package:driver_portal_app/features/home/domain/summarize_transactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mock records produce charge 3200, balance 2200, and max limit 5000',
    () async {
      final summary = await const FinanceRepositoryImpl(MockFinanceDataSource())
          .getFinancialSummary();

      expect(summary.chargeEgp, 3200);
      expect(summary.balanceEgp, 2200);
      expect(summary.maxLimitEgp, 5000);
    },
  );

  test('mock cash received and expenses explain those totals', () {
    final cashReceived = MockFinanceDataSource.transactions
        .where(
          (transaction) =>
              transaction.type == MoneyTransactionType.cashReceived,
        )
        .fold<int>(0, (sum, transaction) => sum + transaction.amountEgp);
    final expenses = MockFinanceDataSource.transactions
        .where(
          (transaction) => transaction.type == MoneyTransactionType.expense,
        )
        .fold<int>(0, (sum, transaction) => sum + transaction.amountEgp);

    expect(cashReceived, 3200);
    expect(expenses, 1000);
    expect(cashReceived - expenses, 2200);
    expect(MockFinanceDataSource.maxLimitEgp, 5000);
  });

  test('cash received increases balance and charge', () {
    final summary = summarizeTransactions(
      maxLimitEgp: 5000,
      transactions: const [
        MoneyTransaction(
          type: MoneyTransactionType.cashReceived,
          amountEgp: 2000,
          label: 'Vault cash',
        ),
        MoneyTransaction(
          type: MoneyTransactionType.cashReceived,
          amountEgp: 1200,
          label: 'Additional vault cash',
        ),
      ],
    );

    expect(summary.chargeEgp, 3200);
    expect(summary.balanceEgp, 3200);
  });

  test('expenses reduce balance and leave charge unchanged', () {
    final summary = summarizeTransactions(
      maxLimitEgp: 5000,
      transactions: const [
        MoneyTransaction(
          type: MoneyTransactionType.cashReceived,
          amountEgp: 3200,
          label: 'Vault cash',
        ),
        MoneyTransaction(
          type: MoneyTransactionType.expense,
          amountEgp: 700,
          label: 'Fuel',
        ),
        MoneyTransaction(
          type: MoneyTransactionType.expense,
          amountEgp: 300,
          label: 'Road fees',
        ),
      ],
    );

    expect(summary.chargeEgp, 3200);
    expect(summary.balanceEgp, 2200);
  });

  test('max limit is independent of the transactions', () {
    const transactions = [
      MoneyTransaction(
        type: MoneyTransactionType.cashReceived,
        amountEgp: 3200,
        label: 'Vault cash',
      ),
      MoneyTransaction(
        type: MoneyTransactionType.expense,
        amountEgp: 1000,
        label: 'Fuel',
      ),
    ];

    final configured = summarizeTransactions(
      maxLimitEgp: 5000,
      transactions: transactions,
    );
    final otherLimit = summarizeTransactions(
      maxLimitEgp: 9000,
      transactions: transactions,
    );

    expect(configured.balanceEgp, otherLimit.balanceEgp);
    expect(configured.chargeEgp, otherLimit.chargeEgp);
    expect(configured.maxLimitEgp, 5000);
    expect(otherLimit.maxLimitEgp, 9000);
  });

  test('an empty transaction list leaves charge and balance at zero', () {
    final summary = summarizeTransactions(
      maxLimitEgp: 5000,
      transactions: const [],
    );

    expect(summary.chargeEgp, 0);
    expect(summary.balanceEgp, 0);
    expect(summary.maxLimitEgp, 5000);
  });

  for (final type in MoneyTransactionType.values) {
    for (final amount in [0, -500]) {
      test('$type amount $amount is rejected', () {
        expect(
          () => summarizeTransactions(
            maxLimitEgp: 5000,
            transactions: [
              MoneyTransaction(type: type, amountEgp: amount, label: 'Invalid'),
            ],
          ),
          throwsA(
            isA<InvalidTransactionAmountException>()
                .having((error) => error.type, 'type', type)
                .having((error) => error.amountEgp, 'amountEgp', amount),
          ),
        );
      });
    }
  }
}
