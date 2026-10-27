import '../../domain/entities/financial_summary.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/summarize_transactions.dart';
import '../datasources/mock_finance_data_source.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final MockFinanceDataSource _dataSource;

  const FinanceRepositoryImpl(this._dataSource);

  /// The static mock account never changes.
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    final account = await _dataSource.loadAccount();
    return summarizeTransactions(
      maxLimitEgp: account.maxLimitEgp,
      transactions: [
        for (final transaction in account.transactions) transaction.toEntity(),
      ],
    );
  }
}
