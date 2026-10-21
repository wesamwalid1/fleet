import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
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
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<ApprovalsBloc, ApprovalsState>(
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _Header(count: state.pendingCount),
                  const SizedBox(height: 16),
                  _Filters(selected: state.filter),
                  const SizedBox(height: 20),
                  if (state.visiblePending.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        l10n.noPendingApprovals,
                        key: const Key('approvals-empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    _SectionTitle(title: l10n.actionRequired, marked: true),
                    const SizedBox(height: 10),
                    for (final item in state.visiblePending) ...[
                      ApprovalCard(
                        item: item,
                        onOpen: () => openApprovalRequest(context, item),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (state.visibleCompleted.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SectionTitle(title: l10n.completed),
                    const SizedBox(height: 10),
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
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (count > 0)
          Container(
            key: const Key('pending-count'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.pendingCount(count),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          final filter = filters[index].$1;
          final label = switch (filter) {
            ApprovalFilter.all => l10n.filterAll,
            ApprovalFilter.vault => l10n.fromVault,
            ApprovalFilter.drivers => l10n.fromDrivers,
            ApprovalFilter.roadExpense => l10n.roadExpenses,
          };
          final active = filter == selected;
          return ChoiceChip(
            key: Key(filters[index].$2),
            label: Text(label),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => context.read<ApprovalsBloc>().add(
              ApprovalsFilterSelected(filter),
            ),
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.title,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool marked;

  const _SectionTitle({required this.title, this.marked = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (marked) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            color: AppColors.title,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
