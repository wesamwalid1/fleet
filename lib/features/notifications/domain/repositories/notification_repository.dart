import '../entities/app_notification.dart';

/// Notifications per driver. The mock implementation persists locally; a
/// backend implementation can replace it without touching the UI.
abstract class NotificationRepository {
  /// Newest first, for [driverId] only.
  Future<List<AppNotification>> getNotifications(String driverId);

  /// Stores [notification] unless one with the same dedup key already exists
  /// for its driver. Returns whether it was added.
  Future<bool> add(AppNotification notification);

  /// Replaces the notification with the same [AppNotification.dedupKey], or
  /// adds it when none exists. Always marks the stored row unread.
  Future<void> update(AppNotification notification);

  Future<void> markRead({required String driverId, required String id});

  /// Emits the driver id whose notifications changed.
  Stream<String> get changes;
}
