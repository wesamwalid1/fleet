import '../../../approvals/domain/entities/approval_item.dart';

enum NotificationTab { approvals, history }

/// Where tapping a notification should lead, resolved against current data.
sealed class NotificationDestination {
  const NotificationDestination();
}

/// The request is still pending: open it for action.
final class OpenApprovalRequest extends NotificationDestination {
  final ApprovalItem item;

  const OpenApprovalRequest(this.item);
}

/// The record exists in History. [alreadyHandled] is true when the
/// notification asked for an action that has since been taken.
final class ShowHistoryEntry extends NotificationDestination {
  final String entryId;
  final bool alreadyHandled;

  const ShowHistoryEntry(this.entryId, {this.alreadyHandled = false});
}

/// The record cannot be found; open the tab it belongs to instead.
final class ShowTabFallback extends NotificationDestination {
  final NotificationTab tab;

  const ShowTabFallback(this.tab);
}
