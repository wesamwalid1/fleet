import 'package:equatable/equatable.dart';

import '../../domain/entities/approval_item.dart';

class ApprovalsState extends Equatable {
  final bool loading;
  final bool busy;
  final bool failed;
  final int revision;
  final int balanceEgp;
  final ApprovalFilter filter;
  final String query;
  final List<ApprovalItem> items;

  const ApprovalsState({
    this.loading = true,
    this.busy = false,
    this.failed = false,
    this.revision = 0,
    this.balanceEgp = 0,
    this.filter = ApprovalFilter.all,
    this.query = '',
    this.items = const [],
  });

  int get pendingCount => items.where((item) => item.isPending).length;

  bool get hasActiveFilter => filter != ApprovalFilter.all;

  /// Pending items for the selected kind filter, before search.
  List<ApprovalItem> get visiblePending => [
    for (final item in items)
      if (item.isPending && item.matches(filter)) item,
  ];

  /// Completed items (kind filter does not apply), before search.
  List<ApprovalItem> get visibleCompleted => [
    for (final item in items)
      if (!item.isPending) item,
  ];

  ApprovalsState copyWith({
    bool? loading,
    bool? busy,
    bool? failed,
    int? revision,
    int? balanceEgp,
    ApprovalFilter? filter,
    String? query,
    List<ApprovalItem>? items,
  }) {
    return ApprovalsState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      failed: failed ?? this.failed,
      revision: revision ?? this.revision,
      balanceEgp: balanceEgp ?? this.balanceEgp,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    busy,
    failed,
    revision,
    balanceEgp,
    filter,
    query,
    items,
  ];
}
