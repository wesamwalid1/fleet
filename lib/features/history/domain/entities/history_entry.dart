import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_string.dart';
import '../../../finance/domain/entities/settlement_type.dart';

enum HistoryKind {
  expense,
  roadExpense,
  vault,
  incoming,
  outgoing,
  requestCash,
  withdraw,
}

enum HistoryFilter {
  all,
  expenses,
  vault,
  drivers,
  sent,
  pending,
  cashTransfers,
}

enum HistoryDateMode { all, day, range }

enum HistoryTripMode { all, specific }

enum HistoryDisplayStatus {
  recorded,
  approved,
  confirmed,
  rejected,
  pendingConfirm,
  awaitingApproval,
}

class HistoryEntry extends Equatable {
  final String id;
  final HistoryKind kind;
  final int amountEgp;
  final bool credit;
  final HistoryDisplayStatus status;
  final SettlementType? settlementType;
  final String tripCode;
  final String tripId;
  final LocalizedString counterpartyName;
  final String counterpartyId;
  final String? note;
  final String requestNumber;

  /// Original operation creation time. Never changes after creation.
  final DateTime createdAt;

  /// Latest status-change / activity time. Equals [createdAt] while pending.
  final DateTime updatedAt;

  /// Driver balance immediately before this entry's financial effect.
  /// Null when no effect has occurred yet or legacy data has no snapshot.
  final int? balanceBeforeEgp;

  /// Driver balance immediately after this entry's financial effect.
  /// Null when no effect has occurred yet or legacy data has no snapshot.
  final int? balanceAfterEgp;

  const HistoryEntry({
    required this.id,
    required this.kind,
    required this.amountEgp,
    required this.credit,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.settlementType,
    this.tripCode = '',
    this.tripId = '',
    this.counterpartyName = LocalizedString.empty,
    this.counterpartyId = '',
    this.note,
    this.requestNumber = '',
    this.balanceBeforeEgp,
    this.balanceAfterEgp,
  });

  bool get hasBalanceSnapshot =>
      balanceBeforeEgp != null && balanceAfterEgp != null;

  /// Latest activity timestamp used for list display, grouping, and sorting.
  DateTime get occurredAt => updatedAt;

  bool get isPending =>
      status == HistoryDisplayStatus.pendingConfirm ||
      status == HistoryDisplayStatus.awaitingApproval;

  /// Operations that start Pending and later change status.
  bool get hasPendingLifecycle => switch (kind) {
    HistoryKind.outgoing ||
    HistoryKind.incoming ||
    HistoryKind.vault ||
    HistoryKind.roadExpense ||
    HistoryKind.requestCash ||
    HistoryKind.withdraw => true,
    HistoryKind.expense => false,
  };

  bool get hasStatusUpdate =>
      hasPendingLifecycle && !isPending && updatedAt != createdAt;

  bool matches(HistoryFilter filter) {
    return switch (filter) {
      HistoryFilter.all => true,
      HistoryFilter.expenses =>
        kind == HistoryKind.expense || kind == HistoryKind.roadExpense,
      HistoryFilter.vault =>
        kind == HistoryKind.vault ||
            kind == HistoryKind.requestCash ||
            kind == HistoryKind.withdraw,
      HistoryFilter.drivers => kind == HistoryKind.incoming,
      HistoryFilter.sent => kind == HistoryKind.outgoing,
      HistoryFilter.pending => isPending,
      HistoryFilter.cashTransfers =>
        kind == HistoryKind.incoming || kind == HistoryKind.outgoing,
    };
  }

  bool matchesDate({
    required HistoryDateMode mode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (mode == HistoryDateMode.all) return true;
    final day = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
    if (mode == HistoryDateMode.day) {
      if (startDate == null) return true;
      final selected = DateTime(startDate.year, startDate.month, startDate.day);
      return day == selected;
    }
    if (startDate == null || endDate == null) return true;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool matchesTrip({
    required HistoryFilter filter,
    required HistoryTripMode tripMode,
    String? tripId,
  }) {
    if (filter != HistoryFilter.expenses) return true;
    if (tripMode != HistoryTripMode.specific) return true;
    final id = tripId ?? '';
    if (id.isEmpty) return true;
    return kind == HistoryKind.expense && this.tripId == id;
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    amountEgp,
    credit,
    createdAt,
    updatedAt,
    status,
    settlementType,
    tripCode,
    tripId,
    counterpartyName,
    counterpartyId,
    note,
    requestNumber,
    balanceBeforeEgp,
    balanceAfterEgp,
  ];
}

class HistoryDay extends Equatable {
  final DateTime day;
  final List<HistoryEntry> entries;

  const HistoryDay({required this.day, required this.entries});

  @override
  List<Object?> get props => [day, entries];
}

/// Groups by latest activity day ([HistoryEntry.updatedAt]).
List<HistoryDay> groupHistoryByDay(List<HistoryEntry> newestFirst) {
  final groups = <HistoryDay>[];
  for (final entry in newestFirst) {
    final day = DateTime(
      entry.updatedAt.year,
      entry.updatedAt.month,
      entry.updatedAt.day,
    );
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(HistoryDay(day: day, entries: [entry]));
    } else {
      groups.last.entries.add(entry);
    }
  }
  return groups;
}

/// Latest activity time with safe fallback for legacy/missing update stamps.
DateTime historyActivityAt({required DateTime createdAt, DateTime? updatedAt}) {
  return updatedAt ?? createdAt;
}
