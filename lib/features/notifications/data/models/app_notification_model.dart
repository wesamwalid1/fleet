import '../../../../core/localization/localized_string.dart';
import '../../domain/entities/app_notification.dart';

/// JSON shape for locally stored notifications. Enum values are stored by
/// name so records stay readable across app versions.
abstract final class AppNotificationModel {
  static Map<String, Object?> toJson(AppNotification notification) {
    return {
      'id': notification.id,
      'driverId': notification.driverId,
      'type': notification.type.name,
      'entityType': notification.entityType.name,
      'entityId': notification.entityId,
      'createdAt': notification.createdAt.toIso8601String(),
      'read': notification.read,
      'dedupKey': notification.dedupKey,
      'amountEgp': notification.amountEgp,
      'counterpartyName': notification.counterpartyName.en,
      'counterpartyNameAr': notification.counterpartyName.ar,
      'source': notification.source.name,
    };
  }

  /// Returns null for a record this version cannot read, so one bad entry
  /// never hides the rest.
  static AppNotification? fromJson(Object? json) {
    if (json is! Map) return null;
    final type = _byName(NotificationType.values, json['type']);
    final entityType = _byName(
      NotificationEntityType.values,
      json['entityType'],
    );
    final source = _byName(NotificationSource.values, json['source']);
    final createdAt = DateTime.tryParse('${json['createdAt']}');
    final id = json['id'];
    final driverId = json['driverId'];
    final entityId = json['entityId'];
    final dedupKey = json['dedupKey'];
    if (type == null ||
        entityType == null ||
        source == null ||
        createdAt == null ||
        id is! String ||
        driverId is! String ||
        entityId is! String ||
        dedupKey is! String) {
      return null;
    }
    final amount = json['amountEgp'];
    final counterparty = json['counterpartyName'];
    final counterpartyAr = json['counterpartyNameAr'];
    return AppNotification(
      id: id,
      driverId: driverId,
      type: type,
      entityType: entityType,
      entityId: entityId,
      createdAt: createdAt,
      dedupKey: dedupKey,
      source: source,
      read: json['read'] == true,
      amountEgp: amount is int ? amount : 0,
      counterpartyName: LocalizedString(
        en: counterparty is String ? counterparty : '',
        ar: counterpartyAr is String ? counterpartyAr : '',
      ),
    );
  }

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
