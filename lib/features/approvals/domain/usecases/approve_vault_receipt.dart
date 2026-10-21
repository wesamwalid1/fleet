import '../repositories/approval_repository.dart';

class ApproveVaultReceipt {
  final ApprovalRepository _repository;

  const ApproveVaultReceipt(this._repository);

  Future<void> call({
    required String driverId,
    required String receiptId,
    DateTime? finalizedAt,
  }) {
    return _repository.approveVaultReceipt(
      driverId: driverId,
      receiptId: receiptId,
      finalizedAt: finalizedAt,
    );
  }
}
