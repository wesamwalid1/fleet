import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approvals/presentation/bloc/approvals_bloc.dart';
import '../../../approvals/presentation/bloc/approvals_state.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/domain/latest_history.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../history/presentation/history_format.dart';
import '../../../history/presentation/widgets/expense_detail_sheet.dart';
import '../../../history/presentation/widgets/history_entry_tile.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';

class RecentTransactionsSection extends StatelessWidget {
  final DateTime Function() now;
  final VoidCallback? onSeeAll;

  const RecentTransactionsSection({
    super.key,
    required this.now,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HistoryBloc>().add(const HistoryStarted());
      },
      child: BlocListener<HomeBloc, HomeState>(
        listenWhen: (previous, current) {
          if (previous is! HomeReady || current is! HomeReady) return false;
          return previous.summary != current.summary;
        },
        listener: (context, state) {
          context.read<HistoryBloc>().add(const HistoryStarted());
        },
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state.loading && state.entries.isEmpty) {
              return const SizedBox.shrink();
            }
            final latest = latestHistoryEntries(state.entries);
            final locale = Localizations.localeOf(context).toString();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recent,
                        key: const Key('home-recent-title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.title,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      key: const Key('home-recent-see-all'),
                      onPressed: onSeeAll,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.pink,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.seeAll,
                            maxLines: 1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (latest.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.noTransactions,
                      key: const Key('home-recent-empty'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  for (final entry in latest)
                    HistoryEntryTile(
                      entry: entry,
                      tileKey: Key('recent-entry-${entry.id}'),
                      when: recentWhenLabel(
                        l10n,
                        entry.occurredAt,
                        now(),
                        locale,
                      ),
                      onTap: entry.kind == HistoryKind.expense
                          ? () => showExpenseDetailSheet(context, entry: entry)
                          : null,
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
