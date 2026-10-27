import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/empty_state.dart';
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

class HistoryPage extends StatefulWidget {
  final DateTime Function() now;

  const HistoryPage({super.key, required this.now});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _revealAttempts = 20;

  final _scroll = ScrollController();
  final _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryStarted());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
              previous.loading != current.loading),
      listener: (context, state) => _scheduleReveal(),
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
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              final groups = groupHistoryByDay(state.visible);
              return ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _Header(count: state.expenseCount),
                  const SizedBox(height: 18),
                  _Filters(selected: state.filter),
                  const SizedBox(height: 8),
                  if (groups.isEmpty)
                    EmptyState(
                      key: const Key('history-empty'),
                      icon: Icons.receipt_long_outlined,
                      title: l10n.noTransactions,
                    )
                  else
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 4),
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
                          highlighted: state.highlightedId == entry.id,
                          when: historyClock(entry.occurredAt, locale),
                          onTap: entry.kind == HistoryKind.expense
                              ? () => showExpenseDetailSheet(
                                  context,
                                  entry: entry,
                                )
                              : null,
                        ),
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
            l10n.navHistory,
            key: const Key('history-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageTitle,
          ),
        ),
        StatusBadge(
          key: const Key('history-expense-count'),
          label: l10n.expenseCount(count),
          foreground: AppColors.title,
          background: AppColors.neutralBackground,
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
            for (final (index, (filter, key)) in filters.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              AppFilterChip(
                key: Key(key),
                label: switch (filter) {
                  HistoryFilter.all => l10n.filterAll,
                  HistoryFilter.expenses => l10n.filterExpenses,
                  HistoryFilter.vault => l10n.fromVault,
                  HistoryFilter.drivers => l10n.fromDrivers,
                  HistoryFilter.sent => l10n.filterSent,
                  HistoryFilter.pending => l10n.filterPending,
                },
                selected: filter == selected,
                onSelected: () => context.read<HistoryBloc>().add(
                  HistoryFilterSelected(filter),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
