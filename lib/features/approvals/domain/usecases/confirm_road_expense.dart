import '../repositories/approval_repository.dart';

class ConfirmRoadExpense {
  final ApprovalRepository _repository;

  const ConfirmRoadExpense(this._repository);

  Future<void> call({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) {
    return _repository.confirmRoadExpense(
      driverId: driverId,
      approvalId: approvalId,
      finalizedAt: finalizedAt,
    );
  }
}
