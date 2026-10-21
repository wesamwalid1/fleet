import '../repositories/approval_repository.dart';

class RejectRoadExpense {
  final ApprovalRepository _repository;

  const RejectRoadExpense(this._repository);

  Future<void> call({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) {
    return _repository.rejectRoadExpense(
      driverId: driverId,
      approvalId: approvalId,
      finalizedAt: finalizedAt,
    );
  }
}
