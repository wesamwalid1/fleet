import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

class HistoryState extends Equatable {
  final bool loading;
  final bool failed;
  final HistoryFilter filter;
  final List<HistoryEntry> entries;

  const HistoryState({
    this.loading = true,
    this.failed = false,
    this.filter = HistoryFilter.all,
    this.entries = const [],
  });

  int get expenseCount =>
      entries.where((entry) => entry.kind == HistoryKind.expense).length;

  List<HistoryEntry> get visible => [
    for (final entry in entries)
      if (entry.matches(filter)) entry,
  ];

  HistoryState copyWith({
    bool? loading,
    bool? failed,
    HistoryFilter? filter,
    List<HistoryEntry>? entries,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      filter: filter ?? this.filter,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [loading, failed, filter, entries];
}
