import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_string.dart';

enum NotificationType {
  vaultReceiptPending,
  incomingTransferPending,
  sentTransferApproved,
  sentTransferRejected,
  roadExpensePending,
  expenseRecorded,

  /// The driver sent cash; it waits for the recipient's confirmation.
  transferSent,
  requestCashPending,
  requestCashApproved,
  requestCashRejected,
  withdrawPending,
  withdrawApproved,
  withdrawRejected,
}

enum NotificationEntityType {
  vaultReceipt,
  transfer,
  roadExpense,
  expense,
  cashRequest,
}

/// Where a record came from. Seed records are demo data written once on the
/// driver's first initialization; event records come from business outcomes.
enum NotificationSource { seed, event }

/// A notification addressed to one driver. Display text is derived from
/// [type] and the structured fields; it is never stored or parsed.
class AppNotification extends Equatable {
  final String id;
  final String driverId;
  final NotificationType type;
  final NotificationEntityType entityType;
  final String entityId;
  final DateTime createdAt;
  final bool read;
  final String dedupKey;
  final int amountEgp;
  final LocalizedString counterpartyName;
  final NotificationSource source;

  const AppNotification({
    required this.id,
    required this.driverId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    required this.dedupKey,
    required this.source,
    this.read = false,
    this.amountEgp = 0,
    this.counterpartyName = LocalizedString.empty,
  });

  AppNotification copyWith({
    bool? read,
    NotificationType? type,
    DateTime? createdAt,
    int? amountEgp,
    LocalizedString? counterpartyName,
  }) {
    return AppNotification(
      id: id,
      driverId: driverId,
      type: type ?? this.type,
      entityType: entityType,
      entityId: entityId,
      createdAt: createdAt ?? this.createdAt,
      dedupKey: dedupKey,
      source: source,
      read: read ?? this.read,
      amountEgp: amountEgp ?? this.amountEgp,
      counterpartyName: counterpartyName ?? this.counterpartyName,
    );
  }

  /// Stable across pending → approved/rejected so the same row is updated.
  static String cashRequestDedupKey({
    required String driverId,
    required String entityId,
  }) {
    return '$driverId|cashRequest|$entityId';
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    type,
    entityType,
    entityId,
    createdAt,
    read,
    dedupKey,
    amountEgp,
    counterpartyName,
    source,
  ];
}

/// One key per source event and target driver. [eventAt] is the source
/// record's own timestamp, so the same event always yields the same key while
/// a mock ledger that restarts its id sequence still yields distinct keys.
String notificationDedupKey({
  required String driverId,
  required NotificationType type,
  required String entityId,
  required DateTime eventAt,
}) {
  return '$driverId|${type.name}|$entityId|${eventAt.microsecondsSinceEpoch}';
}

/// Newest first; ties fall back to id so ordering is stable.
List<AppNotification> sortNewestFirst(Iterable<AppNotification> items) {
  return [...items]..sort((a, b) {
    final byTime = b.createdAt.compareTo(a.createdAt);
    if (byTime != 0) return byTime;
    return b.id.compareTo(a.id);
  });
}
