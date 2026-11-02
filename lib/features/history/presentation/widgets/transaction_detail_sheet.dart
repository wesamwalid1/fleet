import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localized_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/presentation/settlement_style.dart';
import '../../../home/presentation/amount_format.dart';
import '../../domain/entities/history_entry.dart';
import '../history_format.dart';
import 'history_entry_tile.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context, {
  required HistoryEntry entry,
}) {
  final height = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppSurfaces.of(context).sheet,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => TransactionDetailSheet(entry: entry),
  );
}

/// Reusable History details sheet for every operation type.
class TransactionDetailSheet extends StatelessWidget {
  final HistoryEntry entry;

  const TransactionDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amountColor = historyAmountColor(entry);
    final amountBg = entry.credit
        ? AppColors.successBackground
        : AppColors.dangerBackground;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: surfaces.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transactionDetails,
                        style: TextStyle(
                          color: surfaces.title,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        historyTitle(l10n, entry),
                        style: TextStyle(color: surfaces.body, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('history-transaction-dismiss'),
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: surfaces.muted),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: amountBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            entry.credit
                                ? l10n.historyCredit
                                : l10n.historyDebit,
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            key: const Key('history-detail-amount'),
                            signedHistoryAmount(
                              entry,
                              locale: locale,
                              currency: l10n.egp,
                            ),
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            key: const Key('history-detail-status'),
                            historyStatusText(l10n, entry.status),
                            style: TextStyle(
                              color: historyStatusColor(entry.status),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutralBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [..._detailRows(l10n, locale)]),
                    ),
                    const SizedBox(height: 14),
                    _BalanceSnapshotCard(entry: entry, locale: locale),
                    if (entry.hasPendingLifecycle) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.historyTimeline,
                        style: TextStyle(
                          color: surfaces.title,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.neutralBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(children: _timelineRows(l10n, locale)),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: entry.kind == HistoryKind.expense
                    ? const Key('history-expense-close')
                    : const Key('history-transaction-close'),
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: surfaces.title,
                  side: BorderSide(color: surfaces.border),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _detailRows(AppLocalizations l10n, String locale) {
    final rows = <Widget>[];

    void add(String label, String? value, {Color? valueColor, IconData? icon}) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      rows.add(
        _DetailRow(
          icon: icon ?? Icons.info_outline,
          label: label,
          value: text,
          valueColor: valueColor,
        ),
      );
    }

    switch (entry.kind) {
      case HistoryKind.outgoing:
        add(l10n.reference, entry.id, icon: Icons.tag);
        add(
          l10n.recipient,
          entry.counterpartyName.tr(l10n),
          icon: Icons.person_outline,
        );
        add(l10n.driverId, entry.counterpartyId, icon: Icons.badge_outlined);
        add(l10n.note, entry.note, icon: Icons.notes_outlined);
      case HistoryKind.incoming:
        add(l10n.reference, entry.id, icon: Icons.tag);
        add(
          l10n.from,
          entry.counterpartyName.tr(l10n),
          icon: Icons.person_outline,
        );
        add(l10n.driverId, entry.counterpartyId, icon: Icons.badge_outlined);
      case HistoryKind.requestCash:
      case HistoryKind.withdraw:
        add(
          l10n.requestNumber,
          entry.requestNumber.isEmpty ? entry.id : entry.requestNumber,
          icon: Icons.tag,
        );
        add(l10n.note, entry.note, icon: Icons.notes_outlined);
      case HistoryKind.expense:
        if (entry.settlementType != null) {
          add(
            l10n.settlementType,
            settlementName(l10n, entry.settlementType!),
            valueColor: AppColors.info,
            icon: Icons.sell_outlined,
          );
        }
        add(l10n.tripCode, entry.tripCode, icon: Icons.route_outlined);
        add(l10n.reference, entry.id, icon: Icons.tag);
        add(l10n.note, entry.note, icon: Icons.notes_outlined);
      case HistoryKind.vault:
        add(l10n.reference, entry.id, icon: Icons.tag);
        add(l10n.source, l10n.driversVault, icon: Icons.account_balance);
      case HistoryKind.roadExpense:
        add(
          l10n.expenseType,
          l10n.roadExpenseApproval,
          icon: Icons.description,
        );
        add(l10n.tripCode, entry.tripCode, icon: Icons.route_outlined);
        add(l10n.submittedBy, entry.note, icon: Icons.person_outline);
        add(l10n.reference, entry.id, icon: Icons.tag);
    }

    add(
      l10n.status,
      historyStatusText(l10n, entry.status),
      valueColor: historyStatusColor(entry.status),
      icon: Icons.flag_outlined,
    );
    add(
      l10n.createdAtLabel,
      _stamp(entry.createdAt, locale),
      icon: Icons.calendar_today_outlined,
    );
    if (entry.hasStatusUpdate) {
      add(
        l10n.updatedAtLabel,
        _stamp(entry.updatedAt, locale),
        icon: Icons.update,
      );
    }

    return rows;
  }

  List<Widget> _timelineRows(AppLocalizations l10n, String locale) {
    final rows = <Widget>[
      _TimelineRow(
        title: l10n.timelineCreated,
        stamp: _stamp(entry.createdAt, locale),
        isFirst: true,
        isLast: entry.isPending && !entry.hasStatusUpdate,
      ),
    ];
    if (entry.isPending) {
      rows.add(
        _TimelineRow(
          title: l10n.timelineStillPending,
          stamp: historyStatusText(l10n, entry.status),
          isLast: true,
          accent: AppColors.pendingText,
        ),
      );
    } else if (entry.hasPendingLifecycle) {
      rows.add(
        _TimelineRow(
          title: l10n.timelineStatusUpdated(
            historyStatusText(l10n, entry.status),
          ),
          stamp: _stamp(entry.updatedAt, locale),
          isLast: true,
          accent: historyStatusColor(entry.status),
        ),
      );
    }
    return rows;
  }

  String _stamp(DateTime at, String locale) {
    return '${DateFormat('d MMM y', locale).format(at)} · ${historyClock(at, locale)}';
  }
}

class _BalanceSnapshotCard extends StatelessWidget {
  final HistoryEntry entry;
  final String locale;

  const _BalanceSnapshotCard({required this.entry, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    final before = entry.balanceBeforeEgp;
    final after = entry.balanceAfterEgp;
    final available = entry.hasBalanceSnapshot;

    String money(int amount) => formatHomeAmount(
      amount,
      locale: locale,
      withCurrency: true,
      currency: l10n.egp,
    );

    return Container(
      key: const Key('history-detail-balance-snapshot'),
      decoration: BoxDecoration(
        color: AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.balanceSnapshotTitle,
            style: TextStyle(
              color: surfaces.title,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _BalanceSnapshotLine(
            label: l10n.balanceBefore,
            value: available ? money(before!) : l10n.balanceSnapshotUnavailable,
            valueKey: const Key('history-detail-balance-before'),
            muted: !available,
          ),
          const SizedBox(height: 8),
          _BalanceSnapshotLine(
            label: l10n.balanceAfter,
            value: available ? money(after!) : l10n.balanceSnapshotUnavailable,
            valueKey: const Key('history-detail-balance-after'),
            muted: !available,
          ),
        ],
      ),
    );
  }
}

class _BalanceSnapshotLine extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  final bool muted;

  const _BalanceSnapshotLine({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: surfaces.body, fontSize: 14),
          ),
        ),
        Text(
          key: valueKey,
          value,
          style: TextStyle(
            color: muted ? surfaces.muted : surfaces.title,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: surfaces.muted),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: surfaces.body, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? surfaces.title,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String stamp;
  final bool isFirst;
  final bool isLast;
  final Color? accent;

  const _TimelineRow({
    required this.title,
    required this.stamp,
    this.isFirst = false,
    this.isLast = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final color = accent ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 28, color: surfaces.border),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: surfaces.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stamp,
                  style: TextStyle(color: surfaces.body, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
