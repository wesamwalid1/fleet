import '../entities/cash_request_result.dart';
import '../failures/cash_request_exception.dart';
import '../repositories/cash_request_repository.dart';

class WithdrawCash {
  final CashRequestRepository _repository;

  const WithdrawCash(this._repository);

  Future<CashRequestResult> call({
    required String driverId,
    required int amountEgp,
    String? note,
    DateTime? createdAt,
  }) async {
    if (amountEgp <= 0) {
      throw InvalidCashRequestAmountException(amountEgp);
    }

    final request = await _repository.submitWithdraw(
      driverId: driverId,
      amountEgp: amountEgp,
      note: note,
      createdAt: createdAt ?? DateTime.now(),
    );
    final form = await _repository.getWithdrawFormSummary(driverId);
    final capacity = await _repository.getRequestCashFormSummary(driverId);
    return CashRequestResult(
      request: request,
      currentBalanceEgp: form.currentBalanceEgp,
      availableBalanceEgp: form.availableBalanceEgp,
      availableRequestCapacityEgp: capacity.availableRequestCapacityEgp,
    );
  }
}
