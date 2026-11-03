import '../../../home/domain/entities/money_transaction.dart';
import '../../domain/entities/cash_request.dart';
import '../../domain/entities/cash_request_result.dart';
import '../../domain/repositories/cash_request_repository.dart';
import '../datasources/mock_cash_ledger.dart';

class CashRequestRepositoryImpl implements CashRequestRepository {
  final MockCashLedger _ledger;

  const CashRequestRepositoryImpl(this._ledger);

  @override
  Future<RequestCashFormSummary> getRequestCashFormSummary(
    String driverId,
  ) async {
    return RequestCashFormSummary(
      currentBalanceEgp: _ledger.currentBalance(driverId),
      totalBalanceEgp: _ledger.totalBalance(driverId),
      maxLimitEgp: _ledger.maxLimitEgp,
      pendingRequestCashEgp: _ledger.pendingRequestCash(driverId),
      availableRequestCapacityEgp: _ledger.availableRequestCapacity(driverId),
    );
  }

  @override
  Future<WithdrawFormSummary> getWithdrawFormSummary(String driverId) async {
    return WithdrawFormSummary(
      currentBalanceEgp: _ledger.currentBalance(driverId),
      availableBalanceEgp: _ledger.availableBalance(driverId),
    );
  }

  @override
  Future<int> getCurrentBalance(String driverId) async {
    return _ledger.currentBalance(driverId);
  }

  @override
  Future<int> getAvailableBalance(String driverId) async {
    return _ledger.availableBalance(driverId);
  }

  @override
  Future<CashRequest> submitRequestCash({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  }) async {
    return _ledger.submitRequestCash(
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      note: note,
    );
  }

  @override
  Future<CashRequest> submitWithdraw({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  }) async {
    return _ledger.submitWithdraw(
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      note: note,
    );
  }

  @override
  Future<CashRequest> approve(String requestId, {DateTime? processedAt}) async {
    return _ledger.approveCashRequest(requestId, processedAt: processedAt);
  }

  @override
  Future<CashRequest> reject(String requestId, {DateTime? processedAt}) async {
    return _ledger.rejectCashRequest(requestId, processedAt: processedAt);
  }

  @override
  Future<List<CashRequest>> getCashRequests() async {
    return _ledger.cashRequests;
  }

  @override
  Future<List<MoneyTransaction>> getTransactions() async {
    return _ledger.transactions;
  }
}
