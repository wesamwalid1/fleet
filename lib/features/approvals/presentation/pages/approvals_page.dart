import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_event.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/connectivity/presentation/widgets/offline_unavailable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/approval_item.dart';
import '../approval_format.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../widgets/approval_card.dart';
import '../widgets/approval_sheets.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  final _search = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HomeBloc>().add(const HomeSummaryRefreshed());
      },
      child: BlocListener<ApprovalsBloc, ApprovalsState>(
        listenWhen: (previous, current) => current.failed && !previous.failed,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.approvalFailed)));
        },
        child: ColoredBox(
          color: AppSurfaces.of(context).scaffold,
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
                // Keep the list during a brief probe; only disable actions.
                final actionsLocked = connectivity.blocksOnlineWork;
                return BlocBuilder<ApprovalsBloc, ApprovalsState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final pending = [
                      for (final item in state.visiblePending)
                        if (approvalMatches(l10n, item, state.query)) item,
                    ];
                    final completed = [
                      for (final item in state.visibleCompleted)
                        if (approvalMatches(l10n, item, state.query)) item,
                    ];
                    final noSearchHits =
                        state.query.trim().isNotEmpty &&
                        pending.isEmpty &&
                        completed.isEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _Header(count: state.pendingCount),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppSearchField(
                                controller: _search,
                                hintText: l10n.approvalsSearchHint,
                                clearTooltip: l10n.clearSearch,
                                onChanged: _onSearchChanged,
                                onClear: _clearSearch,
                                showClear: state.query.isNotEmpty,
                                fieldKey: const Key('approvals-search'),
                                clearKey: const Key('approvals-search-clear'),
                              ),
                              const SizedBox(height: 12),
                              FilterChipWrap(
                                children: [
                                  AppFilterChip(
                                    key: const Key('approval-filter-all'),
                                    label: l10n.filterAll,
                                    selected:
                                        state.filter == ApprovalFilter.all,
                                    onSelected: () =>
                                        _selectFilter(ApprovalFilter.all),
                                  ),
                                  AppFilterChip(
                                    key: const Key('approval-filter-vault'),
                                    label: l10n.fromVault,
                                    selected:
                                        state.filter == ApprovalFilter.vault,
                                    onSelected: () =>
                                        _selectFilter(ApprovalFilter.vault),
                                  ),
                                  AppFilterChip(
                                    key: const Key('approval-filter-drivers'),
                                    label: l10n.fromDrivers,
                                    selected:
                                        state.filter == ApprovalFilter.drivers,
                                    onSelected: () =>
                                        _selectFilter(ApprovalFilter.drivers),
                                  ),
                                  AppFilterChip(
                                    key: const Key('approval-filter-road'),
                                    label: l10n.roadExpenses,
                                    selected:
                                        state.filter ==
                                        ApprovalFilter.roadExpense,
                                    onSelected: () => _selectFilter(
                                      ApprovalFilter.roadExpense,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              4,
                              20,
                              32 + MediaQuery.paddingOf(context).bottom,
                            ),
                            children: [
                              if (noSearchHits)
                                EmptyState(
                                  key: const Key('approvals-no-results'),
                                  icon: Icons.search_off_rounded,
                                  title: l10n.approvalsNoResults,
                                  hint: l10n.approvalsNoResultsHint,
                                )
                              else if (pending.isEmpty)
                                EmptyState(
                                  key: const Key('approvals-empty'),
                                  icon: Icons.check_rounded,
                                  iconColor: AppColors.success,
                                  iconBackground: AppColors.successBackground,
                                  title: l10n.noPendingApprovals,
                                )
                              else ...[
                                SectionTitle(
                                  title: l10n.actionRequired,
                                  leading: const _Dot(),
                                ),
                                const SizedBox(height: 12),
                                for (final item in pending) ...[
                                  ApprovalCard(
                                    item: item,
                                    onOpen: actionsLocked
                                        ? null
                                        : () => openApprovalRequest(
                                            context,
                                            item,
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                              if (completed.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                SectionTitle(title: l10n.completed),
                                const SizedBox(height: 12),
                                for (final item in completed) ...[
                                  ApprovalCard(item: item),
                                  const SizedBox(height: 10),
                                ],
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
            l10n.approvals,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageTitle.copyWith(
              color: AppSurfaces.of(context).title,
            ),
          ),
        ),
        if (count > 0)
          StatusBadge.pending(
            key: const Key('pending-count'),
            label: l10n.pendingCount(count),
          ),
      ],
    );
  }
}

/// Marks the section that needs the driver's action.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
