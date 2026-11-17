import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/frame/after_next_frame.dart';

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
    emit(state.copyWith(loading: true, failed: false, refreshFailed: false));
    await afterNextFrame();
    if (isClosed || load != _loads) return;
    try {
      final entries = await repository.getHistory(driverId);
      if (load != _loads) return;
      emit(
        state.copyWith(
          loading: false,
          failed: false,
          refreshFailed: false,
          entries: entries,
        ),
      );
    } catch (_) {
      if (load != _loads) return;
      emit(state.copyWith(loading: false, failed: true, refreshFailed: false));
    }
  }

  Future<void> _onRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) async {
    final load = ++_loads;
    final window = event.window;
    // Keep the current entries in state for failure restore. Home and History
    // paint skeletons from [loading]; a manual pull passes [window].
    emit(state.copyWith(loading: true, refreshFailed: false));
    try {
      await afterNextFrame();
      window?.markPainted();
      if (isClosed || load != _loads) {
        await window?.participantFinished();
        return;
      }
      final entries = await repository.getHistory(driverId);
      if (load != _loads) {
        await window?.participantFinished();
        return;
      }
      await window?.participantFinished();
      emit(
        state.copyWith(
          loading: false,
          failed: false,
          refreshFailed: false,
          entries: entries,
        ),
      );
    } catch (_) {
      if (load != _loads) {
        await window?.participantFinished();
        return;
      }
      await window?.participantFinished();
      // Keep the current entries; surface a compact retry banner.
      emit(state.copyWith(loading: false, refreshFailed: true));
    } finally {
      final done = event.done;
      if (done != null && !done.isCompleted) {
        done.complete();
      }
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
        tripIds: expenses ? Set<String>.unmodifiable(draft.tripIds) : const {},
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
        tripIds: const {},
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
        tripIds: const {},
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
