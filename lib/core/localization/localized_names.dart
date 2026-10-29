import 'package:flutter/widgets.dart';

import '../../features/finance/domain/entities/assigned_trip.dart';
import '../../l10n/app_localizations.dart';
import 'localized_string.dart';

/// Shared display helpers for bilingual driver and trip names.
abstract final class LocalizedNames {
  static String driver(LocalizedString name, [Object? localeOrCode]) =>
      name.resolve(localeOrCode);

  static String tripOrigin(AssignedTrip trip, [Object? localeOrCode]) =>
      trip.origin.resolve(localeOrCode);

  static String tripDestination(AssignedTrip trip, [Object? localeOrCode]) =>
      trip.destination.resolve(localeOrCode);

  /// Route label using the existing "origin → destination" pattern.
  static String tripRoute(
    AssignedTrip trip, [
    Object? localeOrCode,
    String separator = ' → ',
  ]) =>
      '${trip.origin.resolve(localeOrCode)}'
      '$separator'
      '${trip.destination.resolve(localeOrCode)}';

  static String placeRoute(
    LocalizedString origin,
    LocalizedString destination, [
    Object? localeOrCode,
    String separator = ' → ',
  ]) =>
      '${origin.resolve(localeOrCode)}'
      '$separator'
      '${destination.resolve(localeOrCode)}';

  static String ofContext(LocalizedString name, BuildContext context) =>
      name.of(context);

  static String ofL10n(LocalizedString name, AppLocalizations l10n) =>
      name.tr(l10n);
}
