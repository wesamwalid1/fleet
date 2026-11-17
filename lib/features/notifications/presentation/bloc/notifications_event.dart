import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../../core/loading/minimum_loading_window.dart';
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

/// The stored notifications changed; reload them in place.
///
/// [done] completes after the attempt finishes (including failures that keep
/// existing items). It is not part of [props].
final class NotificationsRefreshed extends NotificationsEvent {
  final Completer<void>? done;

  /// Set only for a manual pull, so the result waits with that pull's frame.
  /// Not part of [props].
  final MinimumLoadingWindow? window;

  const NotificationsRefreshed({this.done, this.window});
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
