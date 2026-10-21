sealed class ApprovalException implements Exception {
  const ApprovalException();
}

final class ApprovalNotFoundException extends ApprovalException {
  const ApprovalNotFoundException();
}

final class ApprovalAlreadyFinalizedException extends ApprovalException {
  const ApprovalAlreadyFinalizedException();
}
