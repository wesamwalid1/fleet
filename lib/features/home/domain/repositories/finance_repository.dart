import '../entities/financial_summary.dart';

abstract class FinanceRepository {
  Future<FinancialSummary> getFinancialSummary();

  /// Fires whenever the data behind [getFinancialSummary] may have changed.
  Stream<void> get changes;
}
