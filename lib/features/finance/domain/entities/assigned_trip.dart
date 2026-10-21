import 'package:equatable/equatable.dart';

enum TripStatus { active, completed, cancelled }

class AssignedTrip extends Equatable {
  final String id;
  final String code;
  final String driverId;
  final TripStatus status;
  final String origin;
  final String destination;
  final DateTime date;
  final String vehicle;

  const AssignedTrip({
    required this.id,
    required this.code,
    required this.driverId,
    required this.status,
    required this.origin,
    required this.destination,
    required this.date,
    required this.vehicle,
  });

  bool get isEligible =>
      status == TripStatus.active || status == TripStatus.completed;

  @override
  List<Object?> get props => [
    id,
    code,
    driverId,
    status,
    origin,
    destination,
    date,
    vehicle,
  ];
}
