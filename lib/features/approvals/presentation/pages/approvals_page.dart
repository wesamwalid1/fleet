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
import '../../../../core/widgets/section_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/approval_item.dart';
import '../approval_format.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../widgets/approval_inbox_row.dart';
import '../widgets/approval_sheets.dart';

/// Action Inbox — The Desk: pending decisions first, finalized quieter below.
class ApprovalsPage extends StatefulWidget {
  final ScrollController? scrollController;

  /// Clock for a manual pull's minimum loading window. Defaults to wall time.
  final DateTime Function()? loadingNow;

  const ApprovalsPage({super.key, this.scrollController, this.loadingNow});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  final _search = TextEditingController();
  Future<void>? _pullInFlight;
  var _pulling = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<ApprovalsBloc>().add(ApprovalsSearchChanged(value));
  }

  void _clearSearch() {
    _search.clear();
    _onSearchChanged('');
  }

  void _selectFilter(ApprovalFilter filter) {
    context.read<ApprovalsBloc>().add(ApprovalsFilterSelected(filter));
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
      context.read<ApprovalsBloc>().add(
        ApprovalsRefreshed(done: done, window: window),
      );
      await done.future;
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HomeBloc>().add(const HomeSummaryRefreshed());
      },
      child: BlocListener<ApprovalsBloc, ApprovalsState>(
        listenWhen: (previous, current) => current.failed && !previous.failed,
        listener: (context, state) {
          if (state.items.isNotEmpty) {
            HapticsHelper.error();
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.approvalFailed)));
          }
        },
        child: Material(
          color: palette.ground,
          child: SafeArea(
            bottom: false,
            child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status,
              builder: (context, connectivity) {
                if (connectivity.isUnavailable) {
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
                final actionsLocked = connectivity.blocksOnlineWork;
                return BlocBuilder<ApprovalsBloc, ApprovalsState>(
                  builder: (context, state) {
                    if (state.loading && state.items.isEmpty && !_pulling) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: palette.action,
                          strokeWidth: 2.2,
                        ),
                      );
                    }
                    if (state.failed && state.items.isEmpty) {
                      return _LoadError(
                        onRetry: () => context.read<ApprovalsBloc>().add(
                          const ApprovalsStarted(),
                        ),
                      );
                    }

                    final pending = [
                      for (final item in state.visiblePending)
                        if (approvalMatches(l10n, item, state.query)) item,
                    ];
                    final completed = [
                      for (final item in state.visibleCompleted)
                        if (approvalMatches(l10n, item, state.query)) item,
                    ];
                    final searching = state.query.trim().isNotEmpty;
                    final noSearchHits =
                        searching && pending.isEmpty && completed.isEmpty;
                    final allCaughtUp =
                        !searching && pending.isEmpty && completed.isEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _Header(count: pending.length),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _ApprovalsSearchField(
                            controller: _search,
                            hintText: l10n.approvalsSearchHint,
                            clearTooltip: l10n.clearSearch,
                            onChanged: _onSearchChanged,
                            onClear: _clearSearch,
                            showClear: state.query.isNotEmpty,
                          ),
                        ),
                        _FilterRow(
                          filter: state.filter,
                          onSelected: _selectFilter,
                        ),
                        Expanded(
                          child: FleetRefreshIndicator(
                            onRefresh: _onPullToRefresh,
                            child: CustomScrollView(
                              controller: widget.scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                if (state.loading)
                                  const SliverPadding(
                                    padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                                    sliver: SliverToBoxAdapter(
                                      child: FleetRowSkeleton(
                                        key: Key('approvals-loading'),
                                      ),
                                    ),
                                  )
                                else if (noSearchHits)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _MessageState(
                                      key: const Key('approvals-no-results'),
                                      title: l10n.approvalsNoResults,
                                      hint: l10n.approvalsNoResultsHint,
                                    ),
                                  )
                                else if (allCaughtUp)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _MessageState(
                                      key: const Key('approvals-empty'),
                                      title: l10n.approvalsAllCaughtUp,
                                    ),
                                  )
                                else ...[
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      16,
                                      20,
                                      0,
                                    ),
                                    sliver: SliverToBoxAdapter(
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          l10n.approvalsNeedsDecision,
                                          style: AppTextStyles.label.copyWith(
                                            color: palette.muted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (pending.isEmpty)
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        8,
                                        20,
                                        8,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: Text(
                                          key: const Key(
                                            'approvals-no-pending-hint',
                                          ),
                                          l10n.approvalsNoPendingHint,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(color: palette.muted),
                                        ),
                                      ),
                                    )
                                  else
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      sliver: SliverList.separated(
                                        itemCount: pending.length,
                                        separatorBuilder: (_, _) =>
                                            const ApprovalInboxDivider(),
                                        itemBuilder: (context, index) {
                                          final item = pending[index];
                                          return ApprovalInboxRow(
                                            item: item,
                                            busy: state.busy,
                                            actionsLocked: actionsLocked,
                                            onOpen: () => openApprovalRequest(
                                              context,
                                              item,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  if (completed.isNotEmpty) ...[
                                    // Already decided section.
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        28,
                                        20,
                                        0,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            l10n.approvalsAlreadyDecided,
                                            style: AppTextStyles.label
                                                .copyWith(
                                                  color: palette.muted,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Completed list.
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        20,
                                        32 +
                                            MediaQuery.paddingOf(context)
                                                .bottom,
                                      ),
                                      sliver: SliverList.separated(
                                        itemCount: completed.length,
                                        separatorBuilder: (_, _) =>
                                            const ApprovalInboxDivider(),
                                        itemBuilder: (context, index) {
                                          final item = completed[index];
                                          return ApprovalInboxRow(
                                            item: item,
                                            busy: state.busy,
                                            onOpen: () => openApprovalRequest(
                                              context,
                                              item,
                                              readOnly: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ] else
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height:
                                            32 +
                                            MediaQuery.paddingOf(context)
                                                .bottom,
                                      ),
                                    ),
                                ],
                              ],
                            ),
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
    final palette = AppPalette.of(context);
    final title = Semantics(
      header: true,
      child: Text(
        l10n.approvals,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.display.copyWith(color: palette.title),
      ),
    );
    if (count <= 0) return title;
    // SplitRow keeps the count readable at large text scales without
    // overflowing the narrow header row (see text-scale audit).
    return SplitRow(
      leading: title,
      trailing: Text(
        key: const Key('pending-count'),
        l10n.pendingCount(count),
        maxLines: 1,
        softWrap: false,
        style: AppTextStyles.label.copyWith(color: palette.muted),
      ),
      maxFraction: 0.5,
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String? hint;

  const _MessageState({super.key, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                hint!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
            ],
          ],
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
      key: const Key('approvals-load-error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.approvalsLoadError,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: palette.body),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('approvals-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: palette.action,
                minimumSize: const Size(48, 48),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.merge(AppTextStyles.buttonLarge),
              ),
              child: Text(l10n.approvalsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches History search: AppPalette field fill, fieldBorder, focus ring.
class _ApprovalsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _ApprovalsSearchField({
    required this.controller,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
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
      key: const Key('approvals-search'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: palette.focus,
      style: AppTextStyles.input.copyWith(color: palette.title),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.input.copyWith(color: palette.muted),
        prefixIcon: Icon(Icons.search_rounded, color: palette.muted, size: 20),
        suffixIcon: showClear
            ? IconButton(
                key: const Key('approvals-search-clear'),
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

/// Single horizontal, non-wrapping filter row (scrolls when needed).
class _FilterRow extends StatelessWidget {
  final ApprovalFilter filter;
  final ValueChanged<ApprovalFilter> onSelected;

  const _FilterRow({required this.filter, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <(Key, String, ApprovalFilter)>[
      (const Key('approval-filter-all'), l10n.filterAll, ApprovalFilter.all),
      (
        const Key('approval-filter-vault'),
        l10n.fromVault,
        ApprovalFilter.vault,
      ),
      (
        const Key('approval-filter-drivers'),
        l10n.fromDrivers,
        ApprovalFilter.drivers,
      ),
      (
        const Key('approval-filter-road'),
        l10n.roadExpenses,
        ApprovalFilter.roadExpense,
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _FilterChip(
              chipKey: chips[i].$1,
              label: chips[i].$2,
              selected: filter == chips[i].$3,
              onSelected: () => onSelected(chips[i].$3),
            ),
          ],
        ],
      ),
    );
  }
}

/// History-style choice pill: ink when selected, outlined surface at rest.
class _FilterChip extends StatelessWidget {
  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? palette.action : palette.hairline),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.action : palette.surface,
        shape: shape,
        child: InkWell(
          key: chipKey,
          onTap: onSelected,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: selected ? palette.onAction : palette.body,
                  ),
                ),
              ),
            ),
          ),
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
