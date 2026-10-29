import '../../../core/localization/localized_string.dart';
import '../../finance/domain/entities/finance_event.dart';
import 'entities/app_notification.dart';

/// Maps a completed finance outcome to the notifications its affected drivers
/// should receive.
///
/// The driver who approves or declines is not notified about their own
/// decision: approving an incoming transfer notifies the sender. A new
/// transfer notifies both drivers: the recipient that it awaits them, and the
/// sender that it was sent and awaits confirmation.
List<AppNotification> notificationsForFinanceEvent(
  FinanceEvent event, {
  required LocalizedString Function(String driverId) nameOf,
}) {
  return switch (event) {
    TransferCreated(:final transfer) => [
      _event(
        driverId: transfer.recipientId,
        type: NotificationType.incomingTransferPending,
        entityType: NotificationEntityType.transfer,
        entityId: transfer.id,
        eventAt: transfer.createdAt,
        createdAt: transfer.createdAt,
        amountEgp: transfer.amountEgp,
        counterpartyName: nameOf(transfer.senderId),
      ),
      _event(
        driverId: transfer.senderId,
        type: NotificationType.transferSent,
        entityType: NotificationEntityType.transfer,
        entityId: transfer.id,
        eventAt: transfer.createdAt,
        createdAt: transfer.createdAt,
        amountEgp: transfer.amountEgp,
        counterpartyName: nameOf(transfer.recipientId),
      ),
    ],
    TransferApproved(:final transfer) => [
      _event(
        driverId: transfer.senderId,
        type: NotificationType.sentTransferApproved,
        entityType: NotificationEntityType.transfer,
        entityId: transfer.id,
        eventAt: transfer.createdAt,
        createdAt: transfer.finalizedAt ?? transfer.createdAt,
        amountEgp: transfer.amountEgp,
        counterpartyName: nameOf(transfer.recipientId),
      ),
    ],
    TransferRejected(:final transfer) => [
      _event(
        driverId: transfer.senderId,
        type: NotificationType.sentTransferRejected,
        entityType: NotificationEntityType.transfer,
        entityId: transfer.id,
        eventAt: transfer.createdAt,
        createdAt: transfer.finalizedAt ?? transfer.createdAt,
        amountEgp: transfer.amountEgp,
        counterpartyName: nameOf(transfer.recipientId),
      ),
    ],
    ExpenseRecorded(:final expense) => [
      _event(
        driverId: expense.driverId,
        type: NotificationType.expenseRecorded,
        entityType: NotificationEntityType.expense,
        entityId: expense.id,
        eventAt: expense.createdAt,
        createdAt: expense.createdAt,
        amountEgp: expense.amountEgp,
      ),
    ],
    VaultReceiptCreated(:final receipt) => [
      _event(
        driverId: receipt.driverId,
        type: NotificationType.vaultReceiptPending,
        entityType: NotificationEntityType.vaultReceipt,
        entityId: receipt.id,
        eventAt: receipt.createdAt,
        createdAt: receipt.createdAt,
        amountEgp: receipt.amountEgp,
      ),
    ],
  };
}

AppNotification _event({
  required String driverId,
  required NotificationType type,
  required NotificationEntityType entityType,
  required String entityId,
  required DateTime eventAt,
  required DateTime createdAt,
  required int amountEgp,
  LocalizedString counterpartyName = LocalizedString.empty,
}) {
  final key = notificationDedupKey(
    driverId: driverId,
    type: type,
    entityId: entityId,
    eventAt: eventAt,
  );
  return AppNotification(
    id: key,
    driverId: driverId,
    type: type,
    entityType: entityType,
    entityId: entityId,
    createdAt: createdAt,
    dedupKey: key,
    source: NotificationSource.event,
    amountEgp: amountEgp,
    counterpartyName: counterpartyName,
  );
}
