import 'package:equatable/equatable.dart';

import '../../../finance/domain/entities/settlement_type.dart';

enum HistoryKind { expense, roadExpense, vault, incoming, outgoing }

enum HistoryFilter { all, expenses, vault, drivers, sent, pending }

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
  final DateTime occurredAt;
  final HistoryDisplayStatus status;
  final SettlementType? settlementType;
  final String tripCode;
  final String counterpartyName;
  final String counterpartyId;

  const HistoryEntry({
    required this.id,
    required this.kind,
    required this.amountEgp,
    required this.credit,
    required this.occurredAt,
    required this.status,
    this.settlementType,
    this.tripCode = '',
    this.counterpartyName = '',
    this.counterpartyId = '',
  });

  bool get isPending =>
      status == HistoryDisplayStatus.pendingConfirm ||
      status == HistoryDisplayStatus.awaitingApproval;

  bool matches(HistoryFilter filter) {
    return switch (filter) {
      HistoryFilter.all => true,
      HistoryFilter.expenses =>
        kind == HistoryKind.expense || kind == HistoryKind.roadExpense,
      HistoryFilter.vault => kind == HistoryKind.vault,
      HistoryFilter.drivers => kind == HistoryKind.incoming,
      HistoryFilter.sent => kind == HistoryKind.outgoing,
      HistoryFilter.pending => isPending,
    };
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    amountEgp,
    credit,
    occurredAt,
    status,
    settlementType,
    tripCode,
    counterpartyName,
    counterpartyId,
  ];
}

class HistoryDay extends Equatable {
  final DateTime day;
  final List<HistoryEntry> entries;

  const HistoryDay({required this.day, required this.entries});

  @override
  List<Object?> get props => [day, entries];
}

List<HistoryDay> groupHistoryByDay(List<HistoryEntry> newestFirst) {
  final groups = <HistoryDay>[];
  for (final entry in newestFirst) {
    final day = DateTime(
      entry.occurredAt.year,
      entry.occurredAt.month,
      entry.occurredAt.day,
    );
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.entries.add(entry);
      continue;
    }
    groups.add(HistoryDay(day: day, entries: [entry]));
  }
  return groups;
}
