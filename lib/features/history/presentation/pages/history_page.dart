import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_event.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/connectivity/presentation/widgets/offline_unavailable.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approvals/presentation/bloc/approvals_bloc.dart';
import '../../../approvals/presentation/bloc/approvals_state.dart';
import '../../domain/entities/history_entry.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../history_format.dart';
import '../widgets/expense_detail_sheet.dart';
import '../widgets/history_entry_tile.dart';
import '../widgets/history_filter_sheet.dart';

class HistoryPage extends StatefulWidget {
  final DateTime Function() now;

  const HistoryPage({super.key, required this.now});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _revealAttempts = 20;

  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryStarted());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<HistoryBloc>().add(HistorySearchChanged(value));
  }

  void _clearSearch() {
    _search.clear();
    _onSearchChanged('');
  }

  void _clearFiltersAndSearch() {
    _clearSearch();
    context.read<HistoryBloc>().add(const HistoryFiltersReset());
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(0));
  }

  /// Scrolls the highlighted row into view. Rows far below the viewport are
  /// not built yet, so this pages down until the row exists or the list ends.
  void _reveal(int attempt) {
    if (!mounted) return;
    final target = _highlightKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_scroll.hasClients || attempt >= _revealAttempts) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent) return;
    _scroll.jumpTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(attempt + 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return BlocListener<HistoryBloc, HistoryState>(
      listenWhen: (previous, current) =>
          current.highlightedId != null &&
          !current.loading &&
          (previous.highlightedId != current.highlightedId ||
              previous.loading != current.loading ||
              previous.query != current.query),
      listener: (context, state) {
        if (state.query.isEmpty && _search.text.isNotEmpty) {
          _search.clear();
        }
        _scheduleReveal();
      },
      child: _historyBody(context, l10n, locale),
    );
  }

  Widget _historyBody(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HistoryBloc>().add(const HistoryStarted());
      },
      child: ColoredBox(
        color: AppSurfaces.of(context).scaffold,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
            buildWhen: (previous, current) =>
                previous.isUnavailable != current.isUnavailable,
            builder: (context, connectivity) {
              if (connectivity.isUnavailable) {
                final l10n = AppLocalizations.of(context);
                return Center(
                  child: OfflineUnavailable(
                    title: l10n.offlineUnavailableTitle,
                    hint: l10n.offlineUnavailableHint,
                    retryLabel: l10n.offlineRetry,
                    onRetry: () => context.read<ConnectivityBloc>().add(
                      const ConnectivityRetryRequested(),
                    ),
                  ),
                );
              }
              return BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filtered = [
                    for (final entry in state.visible)
                      if (historyMatches(l10n, entry, state.query)) entry,
                  ];
                  final groups = groupHistoryByDay(filtered);
                  final hasQueryOrFilters =
                      state.query.trim().isNotEmpty || state.hasActiveFilter;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _Header(count: state.expenseCount),
                      ),
                      SearchFilterBar(
                        controller: _search,
                        searchHint: l10n.historySearchHint,
                        clearTooltip: l10n.clearSearch,
                        filterLabel: l10n.filter,
                        onChanged: _onSearchChanged,
                        onClear: _clearSearch,
                        showClear: state.query.isNotEmpty,
                        filterActive: state.hasActiveFilter,
                        onFilterTap: () => showHistoryFilterSheet(context),
                        searchKey: const Key('history-search'),
                        clearKey: const Key('history-search-clear'),
                        filterKey: const Key('history-filter-button'),
                      ),
                      Expanded(
                        child: ListView(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            32 + MediaQuery.paddingOf(context).bottom,
                          ),
                          children: [
                            if (groups.isEmpty)
                              EmptyState(
                                key: hasQueryOrFilters
                                    ? const Key('history-no-results')
                                    : const Key('history-empty'),
                                icon: hasQueryOrFilters
                                    ? Icons.search_off_rounded
                                    : Icons.receipt_long_outlined,
                                title: hasQueryOrFilters
                                    ? l10n.historyNoResults
                                    : l10n.noTransactions,
                                hint: hasQueryOrFilters
                                    ? l10n.historyNoResultsHint
                                    : null,
                                action: hasQueryOrFilters
                                    ? TextButton(
                                        key: const Key('history-clear-filters'),
                                        onPressed: _clearFiltersAndSearch,
                                        child: Text(l10n.clearFilters),
                                      )
                                    : null,
                              )
                            else
                              for (final group in groups) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    historyDayHeader(
                                      l10n,
                                      group.day,
                                      widget.now(),
                                      locale,
                                    ),
                                    style: AppTextStyles.groupLabel,
                                  ),
                                ),
                                for (final entry in group.entries)
                                  HistoryEntryTile(
                                    key: state.highlightedId == entry.id
                                        ? _highlightKey
                                        : null,
                                    entry: entry,
                                    showDivider: true,
                                    highlighted:
                                        state.highlightedId == entry.id,
                                    when: historyClock(
                                      entry.occurredAt,
                                      locale,
                                    ),
                                    onTap: entry.kind == HistoryKind.expense
                                        ? () => showExpenseDetailSheet(
                                            context,
                                            entry: entry,
                                          )
                                        : null,
                                  ),
                              ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;

  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.navHistory,
            key: const Key('history-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageTitle.copyWith(
              color: AppSurfaces.of(context).title,
            ),
          ),
        ),
        StatusBadge(
          key: const Key('history-expense-count'),
          label: l10n.expenseCount(count),
          foreground: AppSurfaces.of(context).title,
          background: AppSurfaces.of(context).neutral,
        ),
      ],
    );
  }
}
