import '../../domain/entities/cash_transfer.dart';
import '../../domain/entities/finance_driver.dart';
import '../../domain/repositories/cash_transfer_repository.dart';
import '../datasources/mock_cash_ledger.dart';

class CashTransferRepositoryImpl implements CashTransferRepository {
  final MockCashLedger _ledger;

  const CashTransferRepositoryImpl(this._ledger);

  @override
  Future<List<FinanceDriver>> getRecipients(String senderId) async {
    return _ledger.recipients(senderId);
  }

  @override
  Future<int> getAvailableBalance(String senderId) async {
    return _ledger.availableBalance(senderId);
  }

  @override
  Future<int> getCurrentBalance(String senderId) async {
    return _ledger.currentBalance(senderId);
  }

  @override
  Future<CashTransfer> createPendingTransfer({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    required DateTime createdAt,
  }) async {
    return _ledger.createPendingTransfer(
      senderId: senderId,
      recipientId: recipientId,
      amountEgp: amountEgp,
      createdAt: createdAt,
    );
  }

  @override
  Future<CashTransfer> approve(String transferId) async {
    return _ledger.approve(transferId);
  }

  @override
  Future<CashTransfer> reject(String transferId) async {
    return _ledger.reject(transferId);
  }

  @override
  Future<List<CashTransfer>> getTransfers() async {
    return _ledger.transfers;
  }
}
