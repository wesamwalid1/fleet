import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

class HistoryState extends Equatable {
  final bool loading;
  final bool failed;

  /// Background refresh failed while existing entries remain visible.
  final bool refreshFailed;

  final HistoryFilter filter;
  final String query;
  final HistoryDateMode dateMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> tripIds;
  final List<HistoryEntry> entries;
  final String? highlightedId;

  const HistoryState({
    this.loading = true,
    this.failed = false,
    this.refreshFailed = false,
    this.filter = HistoryFilter.all,
    this.query = '',
    this.dateMode = HistoryDateMode.all,
    this.startDate,
    this.endDate,
    this.tripIds = const {},
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
      (filter == HistoryFilter.expenses && tripIds.isNotEmpty);

  /// Type / date / trip filters applied; search is applied on the page.
  List<HistoryEntry> get visible => [
    for (final entry in entries)
      if (entry.matches(filter) &&
          entry.matchesDate(
            mode: dateMode,
            startDate: startDate,
            endDate: endDate,
          ) &&
          entry.matchesTrip(filter: filter, tripIds: tripIds))
        entry,
  ];

  HistoryState copyWith({
    bool? loading,
    bool? failed,
    bool? refreshFailed,
    HistoryFilter? filter,
    String? query,
    HistoryDateMode? dateMode,
    Object? startDate = _keep,
    Object? endDate = _keep,
    Set<String>? tripIds,
    List<HistoryEntry>? entries,
    Object? highlightedId = _keep,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      refreshFailed: refreshFailed ?? this.refreshFailed,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      dateMode: dateMode ?? this.dateMode,
      startDate: identical(startDate, _keep)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
      tripIds: tripIds ?? this.tripIds,
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
    refreshFailed,
    filter,
    query,
    dateMode,
    startDate,
    endDate,
    tripIds,
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
  final Set<String> tripIds;

  const HistoryFilterDraft({
    this.filter = HistoryFilter.all,
    this.dateMode = HistoryDateMode.all,
    this.startDate,
    this.endDate,
    this.tripIds = const {},
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
      tripIds: state.tripIds,
    );
  }

  static const defaults = HistoryFilterDraft();

  HistoryFilterDraft copyWith({
    HistoryFilter? filter,
    HistoryDateMode? dateMode,
    Object? startDate = _keep,
    Object? endDate = _keep,
    Set<String>? tripIds,
  }) {
    return HistoryFilterDraft(
      filter: filter ?? this.filter,
      dateMode: dateMode ?? this.dateMode,
      startDate: identical(startDate, _keep)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _keep) ? this.endDate : endDate as DateTime?,
      tripIds: tripIds ?? this.tripIds,
    );
  }

  @override
  List<Object?> get props => [filter, dateMode, startDate, endDate, tripIds];
}
