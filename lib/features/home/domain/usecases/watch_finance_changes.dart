import '../repositories/finance_repository.dart';

/// Signals that the financial summary may be out of date.
class WatchFinanceChanges {
  final FinanceRepository _repository;

  const WatchFinanceChanges(this._repository);

  Stream<void> call() => _repository.changes;
}
