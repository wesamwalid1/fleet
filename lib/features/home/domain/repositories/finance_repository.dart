import '../entities/financial_summary.dart';

abstract class FinanceRepository {
  Future<FinancialSummary> getFinancialSummary();
}
