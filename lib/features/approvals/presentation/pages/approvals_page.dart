import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/approval_item.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../widgets/approval_card.dart';
import '../widgets/approval_sheets.dart';

class ApprovalsPage extends StatelessWidget {
  const ApprovalsPage({super.key});

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
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: BlocBuilder<ApprovalsBloc, ApprovalsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    _Header(count: state.pendingCount),
                    const SizedBox(height: 18),
                    _Filters(selected: state.filter),
                    const SizedBox(height: 24),
                    if (state.visiblePending.isEmpty)
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
                      for (final item in state.visiblePending) ...[
                        ApprovalCard(
                          item: item,
                          onOpen: () => openApprovalRequest(context, item),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    if (state.visibleCompleted.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      SectionTitle(title: l10n.completed),
                      const SizedBox(height: 12),
                      for (final item in state.visibleCompleted) ...[
                        ApprovalCard(item: item),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
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
            style: AppTextStyles.pageTitle,
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

class _Filters extends StatelessWidget {
  final ApprovalFilter selected;

  const _Filters({required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const filters = [
      (ApprovalFilter.all, 'approval-filter-all'),
      (ApprovalFilter.vault, 'approval-filter-vault'),
      (ApprovalFilter.drivers, 'approval-filter-drivers'),
      (ApprovalFilter.roadExpense, 'approval-filter-road'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, key) = filters[index];
          return AppFilterChip(
            key: Key(key),
            label: switch (filter) {
              ApprovalFilter.all => l10n.filterAll,
              ApprovalFilter.vault => l10n.fromVault,
              ApprovalFilter.drivers => l10n.fromDrivers,
              ApprovalFilter.roadExpense => l10n.roadExpenses,
            },
            selected: filter == selected,
            onSelected: () => context.read<ApprovalsBloc>().add(
              ApprovalsFilterSelected(filter),
            ),
          );
        },
      ),
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
