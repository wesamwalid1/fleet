import 'package:equatable/equatable.dart';

import '../../../finance/domain/entities/approval_timing.dart';

enum ApprovalKind { vault, driver, roadExpense }

enum ApprovalOutcome { pending, approved, rejected }

enum ApprovalFilter { all, vault, drivers, roadExpense }

class ApprovalTripLine extends Equatable {
  final String code;
  final String origin;
  final String destination;
  final DateTime date;
  final int amountEgp;
  final int tripNumber;

  const ApprovalTripLine({
    required this.code,
    required this.origin,
    required this.destination,
    required this.date,
    required this.amountEgp,
    required this.tripNumber,
  });

  @override
  List<Object?> get props => [
    code,
    origin,
    destination,
    date,
    amountEgp,
    tripNumber,
  ];
}

class ApprovalItem extends Equatable {
  final String id;
  final ApprovalKind kind;
  final ApprovalOutcome outcome;
  final int amountEgp;
  final DateTime occurredAt;
  final DateTime? finalizedAt;
  final ApprovalRecency? recency;
  final int minutes;
  final String counterpartyName;
  final String counterpartyId;
  final String reference;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String submittedBy;
  final String vehicle;
  final int perTripEgp;
  final List<ApprovalTripLine> lines;

  const ApprovalItem({
    required this.id,
    required this.kind,
    required this.outcome,
    required this.amountEgp,
    required this.occurredAt,
    required this.reference,
    this.finalizedAt,
    this.recency,
    this.minutes = 0,
    this.counterpartyName = '',
    this.counterpartyId = '',
    this.periodStart,
    this.periodEnd,
    this.submittedBy = '',
    this.vehicle = '',
    this.perTripEgp = 0,
    this.lines = const [],
  });

  bool get isPending => outcome == ApprovalOutcome.pending;

  bool matches(ApprovalFilter filter) {
    return switch (filter) {
      ApprovalFilter.all => true,
      ApprovalFilter.vault => kind == ApprovalKind.vault,
      ApprovalFilter.drivers => kind == ApprovalKind.driver,
      ApprovalFilter.roadExpense => kind == ApprovalKind.roadExpense,
    };
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    outcome,
    amountEgp,
    occurredAt,
    finalizedAt,
    recency,
    minutes,
    counterpartyName,
    counterpartyId,
    reference,
    periodStart,
    periodEnd,
    submittedBy,
    vehicle,
    perTripEgp,
    lines,
  ];
}
