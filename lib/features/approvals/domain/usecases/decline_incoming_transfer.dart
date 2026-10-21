import '../repositories/approval_repository.dart';

class DeclineIncomingTransfer {
  final ApprovalRepository _repository;

  const DeclineIncomingTransfer(this._repository);

  Future<void> call({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) {
    return _repository.declineIncomingTransfer(
      driverId: driverId,
      transferId: transferId,
      finalizedAt: finalizedAt,
    );
  }
}
