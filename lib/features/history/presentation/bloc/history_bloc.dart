import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final String driverId;
  final HistoryRepository repository;

  HistoryBloc({required this.driverId, required this.repository})
    : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryFilterSelected>(_onFilterSelected);
  }

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(loading: true, failed: false));
    try {
      final entries = await repository.getHistory(driverId);
      emit(state.copyWith(loading: false, failed: false, entries: entries));
    } catch (_) {
      emit(state.copyWith(loading: false, failed: true));
    }
  }

  void _onFilterSelected(
    HistoryFilterSelected event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }
}
