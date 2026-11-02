import '../../../approvals/domain/repositories/approval_repository.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../entities/app_notification.dart';
import '../entities/notification_destination.dart';

/// Decides where a tapped notification leads using current data, so a request
/// that was already handled is never shown as actionable.
class ResolveNotificationDestination {
  final ApprovalRepository approvals;
  final HistoryRepository history;

  const ResolveNotificationDestination({
    required this.approvals,
    required this.history,
  });

  Future<NotificationDestination> call(AppNotification notification) async {
    final driverId = notification.driverId;
    final id = notification.entityId;
    switch (notification.type) {
      case NotificationType.vaultReceiptPending ||
          NotificationType.incomingTransferPending ||
          NotificationType.roadExpensePending:
        final items = await approvals.getApprovals(driverId);
        for (final item in items) {
          if (item.id == id && item.isPending) return OpenApprovalRequest(item);
        }
        if (await _inHistory(driverId, id)) {
          return ShowHistoryEntry(id, alreadyHandled: true);
        }
        return const ShowTabFallback(NotificationTab.approvals);
      case NotificationType.transferSent ||
          NotificationType.sentTransferApproved ||
          NotificationType.sentTransferRejected ||
          NotificationType.expenseRecorded ||
          NotificationType.requestCashPending ||
          NotificationType.requestCashApproved ||
          NotificationType.requestCashRejected ||
          NotificationType.withdrawPending ||
          NotificationType.withdrawApproved ||
          NotificationType.withdrawRejected:
        if (await _inHistory(driverId, id)) return ShowHistoryEntry(id);
        return const ShowTabFallback(NotificationTab.history);
    }
  }

  Future<bool> _inHistory(String driverId, String id) async {
    final entries = await history.getHistory(driverId);
    return entries.any((entry) => entry.id == id);
  }
}
