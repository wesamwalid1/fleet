import 'assigned_trip.dart';

/// Which of the driver's trips an expense may be recorded against.
enum ExpenseTripScope {
  /// Only an active trip ([AssignedTrip.isEligible]).
  activeTrip,

  /// Any trip that was not cancelled, including completed ones.
  anyTrip;

  bool allows(AssignedTrip trip) => switch (this) {
    ExpenseTripScope.activeTrip => trip.isEligible,
    ExpenseTripScope.anyTrip => trip.status != TripStatus.cancelled,
  };
}
