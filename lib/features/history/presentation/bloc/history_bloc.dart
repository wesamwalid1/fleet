import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

const historyHighlightDuration = Duration(milliseconds: 1000);

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final String driverId;
  final HistoryRepository repository;
  Timer? _highlightTimer;
  late final StreamSubscription<void> _ledgerChanges;

  /// Numbers each load so a slower, older load never overwrites newer data.
  /// Refreshes run side by side and only the newest one emits.
  int _loads = 0;

  HistoryBloc({required this.driverId, required this.repository})
    : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryRefreshed>(_onRefreshed);
    on<HistoryFilterSelected>(_onFilterSelected);
    on<HistorySearchChanged>(_onSearchChanged);
    on<HistoryFiltersApplied>(_onFiltersApplied);
    on<HistoryFiltersReset>(_onFiltersReset);
    on<HistoryEntryHighlighted>(_onHighlighted);
    on<HistoryHighlightCleared>(_onHighlightCleared);
    _ledgerChanges = repository.changes.listen(
      (_) => add(const HistoryRefreshed()),
    );
  }

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    final load = ++_loads;
    emit(state.copyWith(loading: true, failed: false));
    try {
      final entries = await repository.getHistory(driverId);
      if (load != _loads) return;
      emit(state.copyWith(loading: false, failed: false, entries: entries));
    } catch (_) {
      if (load != _loads) return;
      emit(state.copyWith(loading: false, failed: true));
    }
  }

  Future<void> _onRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) async {
    final load = ++_loads;
    try {
      final entries = await repository.getHistory(driverId);
      if (load != _loads) return;
      emit(state.copyWith(loading: false, failed: false, entries: entries));
    } catch (_) {
      // Keep the current entries; the next ledger change reloads again.
    }
  }

  void _onFilterSelected(
    HistoryFilterSelected event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onSearchChanged(
    HistorySearchChanged event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  void _onFiltersApplied(
    HistoryFiltersApplied event,
    Emitter<HistoryState> emit,
  ) {
    final draft = event.draft;
    final expenses = draft.filter == HistoryFilter.expenses;
    emit(
      state.copyWith(
        filter: draft.filter,
        dateMode: draft.dateMode,
        startDate: draft.startDate,
        endDate: draft.endDate,
        tripMode: expenses ? draft.tripMode : HistoryTripMode.all,
        tripId: expenses ? draft.tripId : null,
      ),
    );
  }

  void _onFiltersReset(HistoryFiltersReset event, Emitter<HistoryState> emit) {
    emit(
      state.copyWith(
        filter: HistoryFilter.all,
        dateMode: HistoryDateMode.all,
        startDate: null,
        endDate: null,
        tripMode: HistoryTripMode.all,
        tripId: null,
      ),
    );
  }

  void _onHighlighted(
    HistoryEntryHighlighted event,
    Emitter<HistoryState> emit,
  ) {
    _highlightTimer?.cancel();
    emit(
      state.copyWith(
        highlightedId: event.id,
        filter: HistoryFilter.all,
        query: '',
        dateMode: HistoryDateMode.all,
        startDate: null,
        endDate: null,
        tripMode: HistoryTripMode.all,
        tripId: null,
      ),
    );
    _highlightTimer = Timer(historyHighlightDuration, () {
      if (!isClosed) add(const HistoryHighlightCleared());
    });
  }

  void _onHighlightCleared(
    HistoryHighlightCleared event,
    Emitter<HistoryState> emit,
  ) {
    _highlightTimer?.cancel();
    _highlightTimer = null;
    emit(state.copyWith(highlightedId: null));
  }

  @override
  Future<void> close() async {
    _highlightTimer?.cancel();
    await _ledgerChanges.cancel();
    return super.close();
  }
}
