import '../../../../core/localization/localized_string.dart';
import '../../domain/entities/assigned_trip.dart';

/// Shared bilingual place names used by the mock trip catalog.
abstract final class MockPlaces {
  static const cairo = LocalizedString(en: 'Cairo', ar: 'القاهرة');
  static const alexandria = LocalizedString(en: 'Alexandria', ar: 'الإسكندرية');
  static const suez = LocalizedString(en: 'Suez', ar: 'السويس');
  static const portSaid = LocalizedString(en: 'Port Said', ar: 'بورسعيد');
  static const aswan = LocalizedString(en: 'Aswan', ar: 'أسوان');
  static const luxor = LocalizedString(en: 'Luxor', ar: 'الأقصر');
  static const giza = LocalizedString(en: 'Giza', ar: 'الجيزة');
}

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
      origin: MockPlaces.suez,
      destination: MockPlaces.cairo,
      date: DateTime(2026, 5, 28),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0904',
      code: 'TR-2026-0904',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: MockPlaces.alexandria,
      destination: MockPlaces.suez,
      date: DateTime(2026, 5, 14),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0881',
      code: 'TR-2026-0881',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: MockPlaces.cairo,
      destination: MockPlaces.alexandria,
      date: DateTime(2026, 5, 5),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0856',
      code: 'TR-2026-0856',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: MockPlaces.cairo,
      destination: MockPlaces.portSaid,
      date: DateTime(2026, 4, 22),
      vehicle: 'Lowbed',
    ),
    AssignedTrip(
      id: 'trip-2026-0830',
      code: 'TR-2026-0830',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: MockPlaces.aswan,
      destination: MockPlaces.cairo,
      date: DateTime(2026, 4, 10),
      vehicle: 'Flatbed',
    ),
    AssignedTrip(
      id: 'trip-2026-0812',
      code: 'TR-2026-0812',
      driverId: 'DR-001',
      status: TripStatus.completed,
      origin: MockPlaces.cairo,
      destination: MockPlaces.luxor,
      date: DateTime(2026, 3, 28),
      vehicle: 'Telescope',
    ),
    AssignedTrip(
      id: 'trip-2026-0700',
      code: 'TR-2026-0700',
      driverId: 'DR-009',
      status: TripStatus.completed,
      origin: MockPlaces.cairo,
      destination: MockPlaces.giza,
      date: DateTime(2026, 3, 1),
      vehicle: 'Flatbed',
    ),
    AssignedTrip(
      id: 'trip-2026-0600',
      code: 'TR-2026-0600',
      driverId: 'DR-001',
      status: TripStatus.cancelled,
      origin: MockPlaces.cairo,
      destination: MockPlaces.giza,
      date: DateTime(2026, 2, 1),
      vehicle: 'Flatbed',
    ),
  ];
}
