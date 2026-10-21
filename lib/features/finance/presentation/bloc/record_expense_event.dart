import '../../domain/entities/expense_attachment.dart';
import '../../domain/entities/settlement_type.dart';

sealed class RecordExpenseEvent {
  const RecordExpenseEvent();
}

final class RecordExpenseStarted extends RecordExpenseEvent {
  const RecordExpenseStarted();
}

final class RecordExpenseTripQueryChanged extends RecordExpenseEvent {
  final String query;

  const RecordExpenseTripQueryChanged(this.query);
}

final class RecordExpenseTripSelected extends RecordExpenseEvent {
  final String tripId;

  const RecordExpenseTripSelected(this.tripId);
}

final class RecordExpenseSettlementSelected extends RecordExpenseEvent {
  final SettlementType settlementType;

  const RecordExpenseSettlementSelected(this.settlementType);
}

final class RecordExpenseAmountChanged extends RecordExpenseEvent {
  final int amountEgp;

  const RecordExpenseAmountChanged(this.amountEgp);
}

final class RecordExpenseNotesChanged extends RecordExpenseEvent {
  final String notes;

  const RecordExpenseNotesChanged(this.notes);
}

final class RecordExpenseAttachmentAdded extends RecordExpenseEvent {
  final ExpenseAttachment attachment;

  const RecordExpenseAttachmentAdded(this.attachment);
}

final class RecordExpenseAttachmentRemoved extends RecordExpenseEvent {
  final String attachmentId;

  const RecordExpenseAttachmentRemoved(this.attachmentId);
}

final class RecordExpenseAttachmentFailed extends RecordExpenseEvent {
  const RecordExpenseAttachmentFailed();
}

final class RecordExpenseReviewRequested extends RecordExpenseEvent {
  const RecordExpenseReviewRequested();
}

final class RecordExpenseReviewCancelled extends RecordExpenseEvent {
  const RecordExpenseReviewCancelled();
}

final class RecordExpenseSubmitted extends RecordExpenseEvent {
  const RecordExpenseSubmitted();
}
