import '../entities/cash_transfer.dart';
import '../repositories/cash_transfer_repository.dart';

class ApproveCashTransfer {
  final CashTransferRepository _repository;

  const ApproveCashTransfer(this._repository);

  Future<CashTransfer> call(String transferId) =>
      _repository.approve(transferId);
}
