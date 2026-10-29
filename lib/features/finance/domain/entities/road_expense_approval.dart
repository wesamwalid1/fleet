import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_string.dart';

enum RoadExpenseStatus { pending, approved, rejected }

class RoadExpenseLine extends Equatable {
  final String code;
  final LocalizedString origin;
  final LocalizedString destination;
  final DateTime date;
  final int amountEgp;
  final int tripNumber;

  const RoadExpenseLine({
    required this.code,
    required this.origin,
    required this.destination,
    required this.date,
    required this.amountEgp,
    required this.tripNumber,
  });

  String route([Object? localeOrCode, String separator = ' → ']) =>
      '${origin.resolve(localeOrCode)}$separator${destination.resolve(localeOrCode)}';

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

class RoadExpenseApproval extends Equatable {
  final String id;
  final String driverId;
  final int amountEgp;
  final DateTime submittedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String submittedBy;
  final String vehicle;
  final int perTripEgp;
  final List<RoadExpenseLine> lines;
  final RoadExpenseStatus status;
  final DateTime? finalizedAt;

  const RoadExpenseApproval({
    required this.id,
    required this.driverId,
    required this.amountEgp,
    required this.submittedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.submittedBy,
    required this.vehicle,
    required this.perTripEgp,
    required this.lines,
    required this.status,
    this.finalizedAt,
  });

  RoadExpenseApproval copyWith({
    RoadExpenseStatus? status,
    DateTime? finalizedAt,
  }) {
    return RoadExpenseApproval(
      id: id,
      driverId: driverId,
      amountEgp: amountEgp,
      submittedAt: submittedAt,
      periodStart: periodStart,
      periodEnd: periodEnd,
      submittedBy: submittedBy,
      vehicle: vehicle,
      perTripEgp: perTripEgp,
      lines: lines,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    amountEgp,
    submittedAt,
    periodStart,
    periodEnd,
    submittedBy,
    vehicle,
    perTripEgp,
    lines,
    status,
    finalizedAt,
  ];
}
