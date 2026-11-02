import '../entities/cash_request.dart';
import '../repositories/cash_request_repository.dart';

/// Rejects a pending cash request for tests and future company integration.
class RejectCashRequest {
  final CashRequestRepository _repository;

  const RejectCashRequest(this._repository);

  Future<CashRequest> call(String requestId, {DateTime? processedAt}) {
    return _repository.reject(requestId, processedAt: processedAt);
  }
}
