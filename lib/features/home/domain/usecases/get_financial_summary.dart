import '../entities/financial_summary.dart';
import '../repositories/finance_repository.dart';

class GetFinancialSummary {
  final FinanceRepository _repository;

  const GetFinancialSummary(this._repository);

  Future<FinancialSummary> call() => _repository.getFinancialSummary();
}
