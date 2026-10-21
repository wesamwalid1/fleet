import '../repositories/approval_repository.dart';

class ApproveIncomingTransfer {
  final ApprovalRepository _repository;

  const ApproveIncomingTransfer(this._repository);

  Future<void> call({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) {
    return _repository.approveIncomingTransfer(
      driverId: driverId,
      transferId: transferId,
      finalizedAt: finalizedAt,
    );
  }
}
