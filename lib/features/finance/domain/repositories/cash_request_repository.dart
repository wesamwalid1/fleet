import '../../../home/domain/entities/money_transaction.dart';
import '../entities/cash_request.dart';
import '../entities/cash_request_result.dart';

abstract class CashRequestRepository {
  Future<RequestCashFormSummary> getRequestCashFormSummary(String driverId);

  Future<WithdrawFormSummary> getWithdrawFormSummary(String driverId);

  Future<int> getCurrentBalance(String driverId);

  Future<int> getAvailableBalance(String driverId);

  Future<CashRequest> submitRequestCash({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  });

  Future<CashRequest> submitWithdraw({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  });

  /// Domain/test processing for future company approval.
  Future<CashRequest> approve(String requestId, {DateTime? processedAt});

  /// Domain/test processing for future company rejection.
  Future<CashRequest> reject(String requestId, {DateTime? processedAt});

  Future<List<CashRequest>> getCashRequests();

  Future<List<MoneyTransaction>> getTransactions();
}
