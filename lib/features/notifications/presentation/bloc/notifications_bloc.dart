import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/frame/after_next_frame.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// Holds the signed-in driver's notifications for the header bell and the
/// Notifications screen. It only reads; it never creates notifications, so
/// loading or reloading cannot add any.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final String driverId;
  final NotificationRepository repository;
  late final StreamSubscription<String> _changes;

  /// Numbers each load so a slower, older load never overwrites newer data.
  int _loads = 0;

  NotificationsBloc({required this.driverId, required this.repository})
    : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationsFilterSelected>(_onFilterSelected);
    on<NotificationsSearchChanged>(_onSearchChanged);
    _changes = repository.changes
        .where((changed) => changed == driverId)
        .listen((_) => add(const NotificationsRefreshed()));
  }

  /// Initial / Retry load. Shows loading only when there is no content yet,
  /// and paints that frame before an immediate read can replace it.
  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    final load = ++_loads;
    if (state.items.isEmpty) {
      emit(state.copyWith(loading: true, failed: false));
      await afterNextFrame();
      if (isClosed || load != _loads) return;
    } else {
      emit(state.copyWith(failed: false));
    }
    try {
      final items = await repository.getNotifications(driverId);
      if (isClosed || load != _loads) return;
      emit(state.copyWith(loading: false, failed: false, items: items));
    } catch (_) {
      if (isClosed || load != _loads) return;
      emit(state.copyWith(loading: false, failed: true));
    }
  }

  /// Content-preserving reload for pull-to-refresh and repository changes.
  /// Items stay in state so a failure can put them back. A [window] is set
  /// only for a manual pull.
  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    final load = ++_loads;
    final window = event.window;
    emit(state.copyWith(loading: true, failed: false));
    try {
      await afterNextFrame();
      window?.markPainted();
      if (isClosed || load != _loads) {
        await window?.participantFinished();
        return;
      }
      final items = await repository.getNotifications(driverId);
      if (isClosed || load != _loads) {
        await window?.participantFinished();
        return;
      }
      await window?.participantFinished();
      emit(state.copyWith(loading: false, failed: false, items: items));
    } catch (_) {
      if (isClosed || load != _loads) {
        await window?.participantFinished();
        return;
      }
      await window?.participantFinished();
      emit(state.copyWith(loading: false, failed: true));
    } finally {
      final done = event.done;
      if (done != null && !done.isCompleted) {
        done.complete();
      }
    }
  }

  void _onFilterSelected(
    NotificationsFilterSelected event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onSearchChanged(
    NotificationsSearchChanged event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
