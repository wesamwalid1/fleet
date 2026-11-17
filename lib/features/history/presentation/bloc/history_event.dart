import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../../core/loading/minimum_loading_window.dart';
import '../../domain/entities/history_entry.dart';
import 'history_state.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

/// The session ledger changed; reload entries in place, keeping the filter
/// and highlight.
///
/// [done] completes after the attempt finishes (including refresh failures that
/// keep existing entries). It is not part of [props].
final class HistoryRefreshed extends HistoryEvent {
  final Completer<void>? done;

  /// When set, the result is held until this pull's sections reveal together.
  /// Not part of [props].
  final MinimumLoadingWindow? window;

  const HistoryRefreshed({this.done, this.window});
}

final class HistoryFilterSelected extends HistoryEvent {
  final HistoryFilter filter;

  const HistoryFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
}

final class HistorySearchChanged extends HistoryEvent {
  final String query;

  const HistorySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

final class HistoryFiltersApplied extends HistoryEvent {
  final HistoryFilterDraft draft;

  const HistoryFiltersApplied(this.draft);

  @override
  List<Object?> get props => [draft];
}

final class HistoryFiltersReset extends HistoryEvent {
  const HistoryFiltersReset();
}

final class HistoryEntryHighlighted extends HistoryEvent {
  final String id;

  const HistoryEntryHighlighted(this.id);

  @override
  List<Object?> get props => [id];
}

final class HistoryHighlightCleared extends HistoryEvent {
  const HistoryHighlightCleared();
}
