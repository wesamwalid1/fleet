import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification.dart';

enum NotificationFilter { all, unread, read }

class NotificationsState extends Equatable {
  final bool loading;
  final bool failed;
  final NotificationFilter filter;

  /// Search text. Matching runs against the localized title and body, so the
  /// screen applies it with the current localizations.
  final String query;
  final List<AppNotification> items;

  const NotificationsState({
    this.loading = true,
    this.failed = false,
    this.filter = NotificationFilter.all,
    this.query = '',
    this.items = const [],
  });

  int get unreadCount => items.where((item) => !item.read).length;

  bool get hasUnread => items.any((item) => !item.read);

  bool get hasActiveFilter => filter != NotificationFilter.all;

  /// Items of the selected filter, before search.
  List<AppNotification> get visible => switch (filter) {
    NotificationFilter.all => items,
    NotificationFilter.unread => [
      for (final item in items)
        if (!item.read) item,
    ],
    NotificationFilter.read => [
      for (final item in items)
        if (item.read) item,
    ],
  };

  NotificationsState copyWith({
    bool? loading,
    bool? failed,
    NotificationFilter? filter,
    String? query,
    List<AppNotification>? items,
  }) {
    return NotificationsState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [loading, failed, filter, query, items];
}
