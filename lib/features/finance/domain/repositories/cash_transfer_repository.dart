import '../entities/cash_transfer.dart';
import '../entities/finance_driver.dart';

abstract class CashTransferRepository {
  Future<List<FinanceDriver>> getRecipients(String senderId);

  /// Spendable cash after pending Withdraw reservations.
  Future<int> getAvailableBalance(String senderId);

  /// Cash currently held; ignores pending Withdraw reservations.
  Future<int> getCurrentBalance(String senderId);

  Future<CashTransfer> createPendingTransfer({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    required DateTime createdAt,
  });

  Future<CashTransfer> approve(String transferId);

  Future<CashTransfer> reject(String transferId);

  Future<List<CashTransfer>> getTransfers();
}
