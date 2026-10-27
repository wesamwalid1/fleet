import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  NotificationsBloc({required this.driverId, required this.repository})
    : super(const NotificationsState()) {
    on<NotificationsStarted>(_onLoad, transformer: restartable());
    on<NotificationsRefreshed>(_onLoad, transformer: restartable());
    on<NotificationsFilterSelected>(_onFilterSelected);
    on<NotificationsSearchChanged>(_onSearchChanged);
    _changes = repository.changes
        .where((changed) => changed == driverId)
        .listen((_) => add(const NotificationsRefreshed()));
  }

  Future<void> _onLoad(
    NotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final items = await repository.getNotifications(driverId);
      emit(state.copyWith(loading: false, failed: false, items: items));
    } catch (_) {
      emit(state.copyWith(loading: false, failed: true));
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
