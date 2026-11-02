import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

class HistoryState extends Equatable {
  final bool loading;
  final bool failed;
  final HistoryFilter filter;
  final String query;
  final HistoryDateMode dateMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final HistoryTripMode tripMode;
  final String? tripId;
  final List<HistoryEntry> entries;
  final String? highlightedId;

  const HistoryState({
    this.loading = true,
    this.failed = false,
    this.filter = HistoryFilter.all,
    this.query = '',
    this.dateMode = HistoryDateMode.all,
    this.startDate,
    this.endDate,
    this.tripMode = HistoryTripMode.all,
    this.tripId,
    this.entries = const [],
    this.highlightedId,
  });

  /// Confirmed expense totals: recorded expenses + approved road expenses only.
  int get expenseCount => entries
      .where(
        (entry) =>
            entry.kind == HistoryKind.expense ||
            (entry.kind == HistoryKind.roadExpense &&
                entry.status == HistoryDisplayStatus.approved),
      )
      .length;

  bool get hasActiveFilter =>
      filter != HistoryFilter.all ||
      dateMode != HistoryDateMode.all ||
      (filter == HistoryFilter.expenses && tripMode != HistoryTripMode.all);

  /// Type / date / trip filters applied; search is applied on the page.
  List<HistoryEntry> get visible => [
    for (final entry in entries)
      if (entry.matches(filter) &&
          entry.matchesDate(
            mode: dateMode,
            startDate: startDate,
            endDate: endDate,
          ) &&
          entry.matchesTrip(filter: filter, tripMode: tripMode, tripId: tripId))
        entry,
  ];

  HistoryState copyWith({
    bool? loading,
    bool? failed,
    HistoryFilter? filter,
    String? query,
    HistoryDateMode? dateMode,
    Object? startDate = _keep,
    Object? endDate = _keep,
    HistoryTripMode? tripMode,
    Object? tripId = _keep,
    List<HistoryEntry>? entries,
    Object? highlightedId = _keep,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      dateMode: dateMode ?? this.dateMode,
      startDate: identical(startDate, _keep)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
      tripMode: tripMode ?? this.tripMode,
      tripId: identical(tripId, _keep) ? this.tripId : tripId as String?,
      entries: entries ?? this.entries,
      highlightedId: identical(highlightedId, _keep)
          ? this.highlightedId
          : highlightedId as String?,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    failed,
    filter,
    query,
    dateMode,
    startDate,
    endDate,
    tripMode,
    tripId,
    entries,
    highlightedId,
  ];
}

const _keep = Object();

/// Draft value edited inside the History filter bottom sheet.
class HistoryFilterDraft extends Equatable {
  final HistoryFilter filter;
  final HistoryDateMode dateMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final HistoryTripMode tripMode;
  final String? tripId;

  const HistoryFilterDraft({
    this.filter = HistoryFilter.all,
    this.dateMode = HistoryDateMode.all,
    this.startDate,
    this.endDate,
    this.tripMode = HistoryTripMode.all,
    this.tripId,
  });

  factory HistoryFilterDraft.fromState(HistoryState state) {
    return HistoryFilterDraft(
      filter:
          state.filter == HistoryFilter.drivers ||
              state.filter == HistoryFilter.sent ||
              state.filter == HistoryFilter.pending
          ? HistoryFilter.all
          : state.filter,
      dateMode: state.dateMode,
      startDate: state.startDate,
      endDate: state.endDate,
      tripMode: state.tripMode,
      tripId: state.tripId,
    );
  }

  static const defaults = HistoryFilterDraft();

  HistoryFilterDraft copyWith({
    HistoryFilter? filter,
    HistoryDateMode? dateMode,
    Object? startDate = _keep,
    Object? endDate = _keep,
    HistoryTripMode? tripMode,
    Object? tripId = _keep,
  }) {
    return HistoryFilterDraft(
      filter: filter ?? this.filter,
      dateMode: dateMode ?? this.dateMode,
      startDate: identical(startDate, _keep)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
      tripMode: tripMode ?? this.tripMode,
      tripId: identical(tripId, _keep) ? this.tripId : tripId as String?,
    );
  }

  @override
  List<Object?> get props => [
    filter,
    dateMode,
    startDate,
    endDate,
    tripMode,
    tripId,
  ];
}
