import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_event.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/connectivity/presentation/widgets/offline_unavailable.dart';
import '../../../../core/haptics/haptics_helper.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/loading/minimum_loading_window.dart';
import '../../../../core/widgets/fleet_refresh_indicator.dart';
import '../../../../core/widgets/fleet_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approvals/presentation/bloc/approvals_bloc.dart';
import '../../../approvals/presentation/bloc/approvals_state.dart';
import '../../domain/entities/history_entry.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../history_format.dart';
import '../widgets/history_filter_sheet.dart';
import '../widgets/history_ledger_row.dart';
import '../widgets/transaction_detail_sheet.dart';

/// The driver's ledger: active filters stay visible as removable pills above
/// one list of days, each day's label pinned while its rows scroll beneath.
class HistoryPage extends StatefulWidget {
  final DateTime Function() now;
  final ScrollController? scrollController;

  /// Clock for a manual pull's minimum loading window. Defaults to wall time.
  final DateTime Function()? loadingNow;

  const HistoryPage({
    super.key,
    required this.now,
    this.scrollController,
    this.loadingNow,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static const _revealAttempts = 20;

  late final ScrollController _scroll;
  late final bool _ownsScroll;
  final _search = TextEditingController();
  final _highlightKey = GlobalKey();
  Future<void>? _pullInFlight;
  var _pulling = false;

  @override
  void initState() {
    super.initState();
    _ownsScroll = widget.scrollController == null;
    _scroll = widget.scrollController ?? ScrollController();
    final history = context.read<HistoryBloc>().state;
    if (history.highlightedId != null && !history.loading) {
      _scheduleReveal();
    }
  }

  @override
  void dispose() {
    if (_ownsScroll) _scroll.dispose();
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

  void _applyDraft(HistoryFilterDraft draft) {
    context.read<HistoryBloc>().add(HistoryFiltersApplied(draft));
  }

  Future<void> _onPullToRefresh() {
    final connectivity = context.read<ConnectivityBloc>().state;
    if (connectivity.blocksOnlineWork) {
      _showOfflineActionNotice(context);
      return Future<void>.value();
    }
    return _pullInFlight ??= _performPull().whenComplete(() {
      _pullInFlight = null;
    });
  }

  Future<void> _performPull() async {
    if (mounted) setState(() => _pulling = true);
    final window = MinimumLoadingWindow(
      participants: 1,
      now: widget.loadingNow,
    );
    final done = Completer<void>();
    try {
      context.read<HistoryBloc>().add(
        HistoryRefreshed(done: done, window: window),
      );
      await done.future;
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
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
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
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
    super.build(context);
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
      child: BlocListener<ApprovalsBloc, ApprovalsState>(
        listenWhen: (previous, current) =>
            current.revision != previous.revision,
        listener: (context, state) {
          context.read<HistoryBloc>().add(const HistoryRefreshed());
        },
        child: Material(
          color: AppPalette.of(context).ground,
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
                  builder: _content,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, HistoryState state) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (state.loading && state.entries.isEmpty && !_pulling) {
      return Center(
        child: CircularProgressIndicator(
          color: palette.action,
          strokeWidth: 2.2,
        ),
      );
    }
    if (state.failed && state.entries.isEmpty) {
      return _LoadError(
        onRetry: () => context.read<HistoryBloc>().add(const HistoryStarted()),
      );
    }
    final filtered = [
      for (final entry in state.visible)
        if (historyMatches(l10n, entry, state.query)) entry,
    ];
    final groups = groupHistoryByDay(filtered);
    final hasQueryOrFilters =
        state.query.trim().isNotEmpty || state.hasActiveFilter;
    final dayLabelExtent =
        (MediaQuery.textScalerOf(context).scale(14) * 1.3 + 22).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Semantics(
            header: true,
            child: Text(
              l10n.navHistory,
              key: const Key('history-title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.display.copyWith(color: palette.title),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _SearchField(
            controller: _search,
            hint: l10n.historySearchHint,
            clearTooltip: l10n.clearSearch,
            showClear: state.query.isNotEmpty,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
        ),
        if (state.refreshFailed)
          _RefreshFailedBanner(
            onRetry: () =>
                context.read<HistoryBloc>().add(const HistoryRefreshed()),
          ),
        _FilterPills(state: state, onApply: _applyDraft),
        Expanded(
          child: FleetRefreshIndicator(
            onRefresh: _onPullToRefresh,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.loading)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: FleetRowSkeleton(key: Key('history-loading')),
                    ),
                  )
                else if (groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
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
                              style: TextButton.styleFrom(
                                foregroundColor: palette.action,
                                minimumSize: const Size(48, 48),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.merge(AppTextStyles.buttonLarge),
                              ),
                              child: Text(l10n.clearFilters),
                            )
                          : null,
                    ),
                  )
                else
                  for (final group in groups)
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _DayLabel(
                            label: historyDayHeader(
                              l10n,
                              group.day,
                              widget.now(),
                              locale,
                            ),
                            extent: dayLabelExtent,
                            ground: palette.ground,
                            color: palette.muted,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList.builder(
                            itemCount: group.entries.length,
                            itemBuilder: (context, index) {
                              final entry = group.entries[index];
                              final highlighted =
                                  state.highlightedId == entry.id;
                              return HistoryLedgerRow(
                                key: highlighted ? _highlightKey : null,
                                entry: entry,
                                highlighted: highlighted,
                                when: historyClock(entry.updatedAt, locale),
                                onTap: () => showTransactionDetailSheet(
                                  context,
                                  entry: entry,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: 32 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A day label that stays pinned while that day's rows scroll beneath it.
class _DayLabel extends SliverPersistentHeaderDelegate {
  final String label;
  final double extent;
  final Color ground;
  final Color color;

  const _DayLabel({
    required this.label,
    required this.extent,
    required this.ground,
    required this.color,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: extent,
      child: ColoredBox(
        color: ground,
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Semantics(
              header: true,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DayLabel oldDelegate) =>
      oldDelegate.label != label ||
      oldDelegate.extent != extent ||
      oldDelegate.ground != ground ||
      oldDelegate.color != color;
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String clearTooltip;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      key: const Key('history-search'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: palette.focus,
      style: AppTextStyles.input.copyWith(color: palette.title),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.input.copyWith(color: palette.muted),
        prefixIcon: Icon(Icons.search_rounded, color: palette.muted, size: 20),
        suffixIcon: showClear
            ? IconButton(
                key: const Key('history-search-clear'),
                tooltip: clearTooltip,
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, color: palette.body),
              )
            : null,
        filled: true,
        fillColor: palette.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: border(palette.fieldBorder),
        focusedBorder: border(palette.focus, 1.6),
      ),
    );
  }
}

/// The Filter button followed by one removable pill per active filter.
class _FilterPills extends StatelessWidget {
  final HistoryState state;
  final ValueChanged<HistoryFilterDraft> onApply;

  const _FilterPills({required this.state, required this.onApply});

  String _typeLabel(AppLocalizations l10n) {
    return switch (state.filter) {
      HistoryFilter.all => l10n.filterAllTransactions,
      HistoryFilter.expenses => l10n.filterExpenses,
      HistoryFilter.cashTransfers ||
      HistoryFilter.drivers => l10n.filterCashTransfers,
      HistoryFilter.vault => l10n.filterVaultTransactions,
      HistoryFilter.sent => l10n.filterSent,
      HistoryFilter.pending => l10n.filterPending,
    };
  }

  String _tripLabel(AppLocalizations l10n) {
    final ids = state.tripIds;
    if (ids.length > 1) return l10n.historyTripCount(ids.length);
    final id = ids.single;
    for (final entry in state.entries) {
      if (entry.tripId == id && entry.tripCode.isNotEmpty) {
        return entry.tripCode;
      }
    }
    return id;
  }

  String _dateLabel(AppLocalizations l10n, String locale) {
    final start = state.startDate;
    final end = state.endDate;
    if (start == null) return l10n.filterDate;
    if (state.dateMode == HistoryDateMode.day || end == null) {
      return historyDayLabel(start, locale);
    }
    return l10n.historyDateRangeValue(
      historyDayLabel(start, locale),
      historyDayLabel(end, locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final draft = HistoryFilterDraft.fromState(state);
    final showTrip =
        state.filter == HistoryFilter.expenses && state.tripIds.isNotEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          _FilterButton(label: l10n.filter),
          _PillSlot(
            child: state.filter == HistoryFilter.all
                ? null
                : _ActivePill(
                    pillKey: const Key('history-pill-type'),
                    label: _typeLabel(l10n),
                    onRemove: () => onApply(
                      draft.copyWith(
                        filter: HistoryFilter.all,
                        tripIds: const <String>{},
                      ),
                    ),
                  ),
          ),
          _PillSlot(
            child: !showTrip
                ? null
                : _ActivePill(
                    pillKey: const Key('history-pill-trip'),
                    label: _tripLabel(l10n),
                    onRemove: () =>
                        onApply(draft.copyWith(tripIds: const <String>{})),
                  ),
          ),
          _PillSlot(
            child: state.dateMode == HistoryDateMode.all
                ? null
                : _ActivePill(
                    pillKey: const Key('history-pill-date'),
                    label: _dateLabel(l10n, locale),
                    onRemove: () => onApply(
                      draft.copyWith(
                        dateMode: HistoryDateMode.all,
                        startDate: null,
                        endDate: null,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Room for one filter pill: it fades and opens in place when the filter is
/// applied and closes when it is removed, at once under reduced motion.
class _PillSlot extends StatelessWidget {
  final Widget? child;

  const _PillSlot({required this.child});

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          alignment: AlignmentDirectional.centerStart,
          child: child,
        ),
      ),
      child: child == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: child,
            ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;

  const _FilterButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: palette.fieldBorder),
    );
    return Material(
      color: palette.surface,
      shape: shape,
      child: InkWell(
        key: const Key('history-filter-button'),
        onTap: () => showHistoryFilterSheet(context),
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: palette.title),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(color: palette.title),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An applied filter in ink: tapping it removes that filter alone.
class _ActivePill extends StatelessWidget {
  final Key pillKey;
  final String label;
  final VoidCallback onRemove;

  const _ActivePill({
    required this.pillKey,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: l10n.historyRemoveFilter(label),
      excludeSemantics: true,
      child: Material(
        color: palette.action,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: pillKey,
          onTap: onRemove,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 10, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: palette.onAction,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: palette.onAction,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final hint = this.hint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: palette.muted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: palette.title,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

class _RefreshFailedBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _RefreshFailedBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: DecoratedBox(
        key: const Key('history-refresh-failed'),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.hairline),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.historyRefreshFailed,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.body,
                    ),
                  ),
                ),
              ),
              TextButton(
                key: const Key('history-refresh-retry'),
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: palette.action,
                  minimumSize: const Size(48, 40),
                  textStyle: Theme.of(context).textTheme.labelLarge
                      ?.merge(AppTextStyles.buttonLarge),
                ),
                child: Text(l10n.historyRefreshRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Center(
      key: const Key('history-load-error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.historyLoadError,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: palette.body),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('history-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: palette.action,
                minimumSize: const Size(48, 48),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.merge(AppTextStyles.buttonLarge),
              ),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

void _showOfflineActionNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  HapticsHelper.error();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
}
