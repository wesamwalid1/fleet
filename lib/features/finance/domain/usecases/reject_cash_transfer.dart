import '../entities/cash_transfer.dart';
import '../repositories/cash_transfer_repository.dart';

class RejectCashTransfer {
  final CashTransferRepository _repository;

  const RejectCashTransfer(this._repository);

  Future<CashTransfer> call(String transferId) =>
      _repository.reject(transferId);
}
