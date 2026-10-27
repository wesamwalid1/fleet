import '../../../finance/data/datasources/mock_cash_ledger.dart';
import '../../domain/entities/financial_summary.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/summarize_transactions.dart';
import '../datasources/mock_finance_data_source.dart';

/// Available balance comes from the shared cash ledger.
/// Charge and max limit stay on the transaction summary.
class SessionFinanceRepository implements FinanceRepository {
  final MockFinanceDataSource _dataSource;
  final MockCashLedger _ledger;

  const SessionFinanceRepository(this._dataSource, this._ledger);

  @override
  Stream<void> get changes => _ledger.changes;

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    final account = await _dataSource.loadAccount();
    final base = summarizeTransactions(
      maxLimitEgp: account.maxLimitEgp,
      transactions: [
        for (final transaction in account.transactions) transaction.toEntity(),
      ],
    );
    return FinancialSummary(
      balanceEgp: _ledger.balanceOf(MockCashLedger.senderId),
      chargeEgp: base.chargeEgp,
      maxLimitEgp: base.maxLimitEgp,
    );
  }
}
