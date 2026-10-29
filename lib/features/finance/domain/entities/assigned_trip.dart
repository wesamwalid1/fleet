import 'package:equatable/equatable.dart';

import '../../../../core/localization/localized_string.dart';

enum TripStatus { active, completed, cancelled }

class AssignedTrip extends Equatable {
  final String id;
  final String code;
  final String driverId;
  final TripStatus status;
  final LocalizedString origin;
  final LocalizedString destination;
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

  bool get isEligible => status == TripStatus.active;

  String route([Object? localeOrCode, String separator = ' → ']) =>
      '${origin.resolve(localeOrCode)}$separator${destination.resolve(localeOrCode)}';

  bool matchesQuery(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return code.toLowerCase().contains(needle) ||
        origin.matchesQuery(needle) ||
        destination.matchesQuery(needle);
  }

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
