import '../../domain/entities/assigned_trip.dart';

/// Trips the expense flow can see. The cancelled trip and the other driver's
/// trip stay in the catalog so the ledger can reject them if a caller bypasses
/// the picker.
class MockAssignedTrips {
  static final trips = <AssignedTrip>[
    AssignedTrip(
      id: 'trip-2026-0927',
      code: 'TR-2026-0927',
      driverId: 'DR-001',
      status: TripStatus.active,
      origin: 'Suez',
      destination: 'Cairo',
      date: DateTime(2026, 5, 28),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0904',
      code: 'TR-2026-0904',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: 'Alexandria',
      destination: 'Suez',
      date: DateTime(2026, 5, 14),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0881',
      code: 'TR-2026-0881',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: 'Cairo',
      destination: 'Alexandria',
      date: DateTime(2026, 5, 5),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0856',
      code: 'TR-2026-0856',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: 'Cairo',
      destination: 'Port Said',
      date: DateTime(2026, 4, 22),
      vehicle: 'Lowbed',
    ),
    AssignedTrip(
      id: 'trip-2026-0830',
      code: 'TR-2026-0830',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: 'Aswan',
      destination: 'Cairo',
      date: DateTime(2026, 4, 10),
      vehicle: 'Flatbed',
    ),
    AssignedTrip(
      id: 'trip-2026-0812',
      code: 'TR-2026-0812',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: 'Cairo',
      destination: 'Luxor',
      date: DateTime(2026, 3, 28),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0700',
      code: 'TR-2026-0700',
      driverId: 'DR-009',
      status: TripStatus.completed,
      origin: 'Cairo',
      destination: 'Giza',
      date: DateTime(2026, 3, 1),
      vehicle: 'Flatbed',
    ),
    AssignedTrip(
      id: 'trip-2026-0600',
      code: 'TR-2026-0600',
      driverId: 'DR-001',
      status: TripStatus.cancelled,
      origin: 'Cairo',
      destination: 'Giza',
      date: DateTime(2026, 2, 1),
      vehicle: 'Flatbed',
    ),
  ];
}
