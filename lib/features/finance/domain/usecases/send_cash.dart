import '../entities/send_cash_result.dart';
import '../failures/send_cash_exception.dart';
import '../repositories/cash_transfer_repository.dart';

class SendCash {
  final CashTransferRepository _repository;

  const SendCash(this._repository);

  Future<SendCashResult> call({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    DateTime? createdAt,
  }) async {
    if (senderId == recipientId) {
      throw const SendCashToSelfException();
    }
    if (amountEgp <= 0) {
      throw InvalidTransferAmountException(amountEgp);
    }

    final transfer = await _repository.createPendingTransfer(
      senderId: senderId,
      recipientId: recipientId,
      amountEgp: amountEgp,
      createdAt: createdAt ?? DateTime.now(),
    );
    final balance = await _repository.getAvailableBalance(senderId);
    return SendCashResult(transfer: transfer, senderBalanceEgp: balance);
  }
}
