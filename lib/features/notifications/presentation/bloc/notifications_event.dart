import 'package:equatable/equatable.dart';

import 'notifications_state.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads (and on first run seeds) the driver's notifications.
final class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

/// The stored notifications changed; reload them.
final class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

final class NotificationsFilterSelected extends NotificationsEvent {
  final NotificationFilter filter;

  const NotificationsFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// The search text changed; an empty query shows every notification of the
/// selected filter.
final class NotificationsSearchChanged extends NotificationsEvent {
  final String query;

  const NotificationsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}
