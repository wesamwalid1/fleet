import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/history_entry.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../history_format.dart';
import '../widgets/expense_detail_sheet.dart';
import '../widgets/history_entry_tile.dart';

class HistoryPage extends StatefulWidget {
  final DateTime Function() now;

  const HistoryPage({super.key, required this.now});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryStarted());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = groupHistoryByDay(state.visible);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Header(count: state.expenseCount),
              const SizedBox(height: 16),
              _Filters(selected: state.filter),
              const SizedBox(height: 8),
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    l10n.noTransactions,
                    key: const Key('history-empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      historyDayHeader(
                        l10n,
                        group.day,
                        widget.now(),
                        Localizations.localeOf(context).toString(),
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final entry in group.entries)
                    HistoryEntryTile(
                      entry: entry,
                      tileKey: Key('history-entry-${entry.id}'),
                      when: historyClock(
                        entry.occurredAt,
                        Localizations.localeOf(context).toString(),
                      ),
                      onTap: entry.kind == HistoryKind.expense
                          ? () => showExpenseDetailSheet(context, entry: entry)
                          : null,
                    ),
                ],
            ],
          );
        },
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
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          key: const Key('history-expense-count'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pinkBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.expenseCount(count),
            style: const TextStyle(
              color: AppColors.pink,
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
  final HistoryFilter selected;

  const _Filters({required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const filters = [
      (HistoryFilter.all, 'history-filter-all'),
      (HistoryFilter.expenses, 'history-filter-expenses'),
      (HistoryFilter.vault, 'history-filter-vault'),
      (HistoryFilter.drivers, 'history-filter-drivers'),
      (HistoryFilter.sent, 'history-filter-sent'),
      (HistoryFilter.pending, 'history-filter-pending'),
    ];
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, filter) in filters.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              ChoiceChip(
                key: Key(filter.$2),
                label: Text(switch (filter.$1) {
                  HistoryFilter.all => l10n.filterAll,
                  HistoryFilter.expenses => l10n.filterExpenses,
                  HistoryFilter.vault => l10n.fromVault,
                  HistoryFilter.drivers => l10n.fromDrivers,
                  HistoryFilter.sent => l10n.filterSent,
                  HistoryFilter.pending => l10n.filterPending,
                }),
                selected: filter.$1 == selected,
                showCheckmark: false,
                onSelected: (_) => context.read<HistoryBloc>().add(
                  HistoryFilterSelected(filter.$1),
                ),
                labelStyle: TextStyle(
                  color: filter.$1 == selected ? Colors.white : AppColors.title,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: filter.$1 == selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
