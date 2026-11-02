import '../entities/cash_request.dart';
import '../repositories/cash_request_repository.dart';

/// Processes a pending cash request for tests and future company integration.
class ApproveCashRequest {
  final CashRequestRepository _repository;

  const ApproveCashRequest(this._repository);

  Future<CashRequest> call(String requestId, {DateTime? processedAt}) {
    return _repository.approve(requestId, processedAt: processedAt);
  }
}
