import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

class HistoryState extends Equatable {
  final bool loading;
  final bool failed;
  final HistoryFilter filter;
  final List<HistoryEntry> entries;
  final String? highlightedId;

  const HistoryState({
    this.loading = true,
    this.failed = false,
    this.filter = HistoryFilter.all,
    this.entries = const [],
    this.highlightedId,
  });

  int get expenseCount => entries
      .where(
        (entry) =>
            entry.kind == HistoryKind.expense ||
            entry.kind == HistoryKind.roadExpense,
      )
      .length;

  List<HistoryEntry> get visible => [
    for (final entry in entries)
      if (entry.matches(filter)) entry,
  ];

  HistoryState copyWith({
    bool? loading,
    bool? failed,
    HistoryFilter? filter,
    List<HistoryEntry>? entries,
    Object? highlightedId = _keepHighlight,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      filter: filter ?? this.filter,
      entries: entries ?? this.entries,
      highlightedId: identical(highlightedId, _keepHighlight)
          ? this.highlightedId
          : highlightedId as String?,
    );
  }

  @override
  List<Object?> get props => [loading, failed, filter, entries, highlightedId];
}

const _keepHighlight = Object();
