import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_notification.dart';
import '../models/app_notification_model.dart';

/// Local storage for one driver's notifications and their seed marker.
abstract class NotificationLocalDataSource {
  Future<List<AppNotification>> read(String driverId);

  Future<void> write(String driverId, List<AppNotification> notifications);

  Future<bool> isSeeded(String driverId);

  Future<void> markSeeded(String driverId);
}

/// Stores each driver's records under its own keys, so one driver's data is
/// never read for another. Falls back to memory when the platform store is
/// unavailable, matching the locale repository.
class SharedPreferencesNotificationDataSource
    implements NotificationLocalDataSource {
  static String recordsKey(String driverId) =>
      'notifications_v1_records_$driverId';

  static String seededKey(String driverId) =>
      'notifications_v1_seeded_$driverId';

  final Map<String, String> _memoryRecords = {};
  final Set<String> _memorySeeded = {};

  @override
  Future<List<AppNotification>> read(String driverId) async {
    final preferences = await _preferences();
    final raw = preferences == null
        ? _memoryRecords[driverId]
        : preferences.getString(recordsKey(driverId));
    if (raw == null || raw.isEmpty) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (AppNotificationModel.fromJson(item) case final notification?)
          if (notification.driverId == driverId) notification,
    ];
  }

  @override
  Future<void> write(
    String driverId,
    List<AppNotification> notifications,
  ) async {
    final raw = jsonEncode([
      for (final notification in notifications)
        AppNotificationModel.toJson(notification),
    ]);
    final preferences = await _preferences();
    if (preferences == null) {
      _memoryRecords[driverId] = raw;
      return;
    }
    await preferences.setString(recordsKey(driverId), raw);
  }

  @override
  Future<bool> isSeeded(String driverId) async {
    final preferences = await _preferences();
    if (preferences == null) return _memorySeeded.contains(driverId);
    return preferences.getBool(seededKey(driverId)) ?? false;
  }

  @override
  Future<void> markSeeded(String driverId) async {
    final preferences = await _preferences();
    if (preferences == null) {
      _memorySeeded.add(driverId);
      return;
    }
    await preferences.setBool(seededKey(driverId), true);
  }

  Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
