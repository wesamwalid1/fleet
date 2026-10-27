import '../../../finance/data/datasources/mock_cash_ledger.dart';
import '../../domain/entities/app_notification.dart';

/// Demo notifications written once per driver on first initialization. They
/// point at the requests seeded by [MockCashLedger.seedDriverApprovals]: three
/// still need the driver (unread) and one was already handled (read).
abstract final class MockNotificationSeed {
  static List<AppNotification> forDriver(String driverId) {
    if (driverId != MockCashLedger.senderId) return const [];
    return [
      _seed(
        driverId: driverId,
        type: NotificationType.roadExpensePending,
        entityType: NotificationEntityType.roadExpense,
        entityId: 'RE-2026-1041',
        createdAt: DateTime(2026, 6, 22, 10, 15),
        amountEgp: 300,
      ),
      _seed(
        driverId: driverId,
        type: NotificationType.vaultReceiptPending,
        entityType: NotificationEntityType.vaultReceipt,
        entityId: 'DSB-2025-0441',
        createdAt: DateTime(2025, 5, 13, 9),
        amountEgp: 2000,
      ),
      _seed(
        driverId: driverId,
        type: NotificationType.incomingTransferPending,
        entityType: NotificationEntityType.transfer,
        entityId: 'TRF-2025-0123',
        createdAt: DateTime(2025, 5, 13, 8, 55),
        amountEgp: 500,
        counterpartyName: 'Khaled Ramadan',
      ),
      _seed(
        driverId: driverId,
        type: NotificationType.vaultReceiptPending,
        entityType: NotificationEntityType.vaultReceipt,
        entityId: 'DSB-2025-0301',
        createdAt: DateTime(2025, 5, 10, 10),
        amountEgp: 3000,
        read: true,
      ),
    ];
  }

  static List<AppNotification> none(String driverId) => const [];

  static AppNotification _seed({
    required String driverId,
    required NotificationType type,
    required NotificationEntityType entityType,
    required String entityId,
    required DateTime createdAt,
    required int amountEgp,
    String counterpartyName = '',
    bool read = false,
  }) {
    final key = '$driverId|${type.name}|$entityId|seed';
    return AppNotification(
      id: key,
      driverId: driverId,
      type: type,
      entityType: entityType,
      entityId: entityId,
      createdAt: createdAt,
      dedupKey: key,
      source: NotificationSource.seed,
      read: read,
      amountEgp: amountEgp,
      counterpartyName: counterpartyName,
    );
  }
}
