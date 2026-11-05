import 'package:flutter/material.dart';

import '../../../../core/localization/localized_string.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/presentation/settlement_style.dart';
import '../../../home/presentation/amount_format.dart';
import '../../domain/entities/history_entry.dart';
import '../history_format.dart';
import 'history_ledger_row.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context, {
  required HistoryEntry entry,
}) {
  final height = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).surface,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => TransactionDetailSheet(entry: entry),
  );
}

/// Details for every History operation: the amount and where it stands, a
/// short timeline of its real events, its details, and the balance change
/// exactly as the ledger recorded it.
class TransactionDetailSheet extends StatelessWidget {
  final HistoryEntry entry;

  const TransactionDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final mark = historyMarkState(entry.status);
    final buttonText = Theme.of(context).textTheme.labelLarge
        ?.merge(AppTextStyles.buttonLarge);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.transactionDetails,
                          style: AppTextStyles.title.copyWith(
                            color: palette.title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        historyTitle(l10n, entry),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('history-transaction-dismiss'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: palette.muted),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Semantics(
                      label:
                          '${entry.credit ? l10n.historyCredit : l10n.historyDebit} '
                          '${signedHistoryAmount(entry, locale: locale, currency: l10n.egp)}',
                      excludeSemantics: true,
                      child: Text(
                        key: const Key('history-detail-amount'),
                        signedHistoryAmount(
                          entry,
                          locale: locale,
                          currency: l10n.egp,
                        ),
                        style: TextStyle(
                          color: entry.isPending
                              ? palette.muted
                              : palette.title,
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        HistoryStateMark(mark, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            key: const Key('history-detail-status'),
                            historyStatusText(l10n, entry.status),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: mark == HistoryMarkState.rejected
                                  ? palette.error
                                  : palette.body,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _SectionLabel(l10n.historyTimeline),
                    _Timeline(entry: entry, locale: locale),
                    const SizedBox(height: 20),
                    ..._detailRows(l10n),
                    _BalanceChange(entry: entry, locale: locale),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              key: entry.kind == HistoryKind.expense
                  ? const Key('history-expense-close')
                  : const Key('history-transaction-close'),
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.title,
                backgroundColor: palette.surface,
                side: BorderSide(color: palette.fieldBorder),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: buttonText,
              ),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _detailRows(AppLocalizations l10n) {
    final rows = <Widget>[];

    void add(String label, String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      rows.add(_DetailRow(label: label, value: text));
    }

    switch (entry.kind) {
      case HistoryKind.outgoing:
        add(l10n.reference, entry.id);
        add(l10n.recipient, entry.counterpartyName.tr(l10n));
        add(l10n.driverId, entry.counterpartyId);
        add(l10n.note, entry.note);
      case HistoryKind.incoming:
        add(l10n.reference, entry.id);
        add(l10n.from, entry.counterpartyName.tr(l10n));
        add(l10n.driverId, entry.counterpartyId);
      case HistoryKind.requestCash:
      case HistoryKind.withdraw:
        add(
          l10n.requestNumber,
          entry.requestNumber.isEmpty ? entry.id : entry.requestNumber,
        );
        add(l10n.note, entry.note);
      case HistoryKind.expense:
        if (entry.settlementType != null) {
          add(l10n.settlementType, settlementName(l10n, entry.settlementType!));
        }
        add(l10n.tripCode, entry.tripCode);
        add(l10n.reference, entry.id);
        add(l10n.note, entry.note);
      case HistoryKind.vault:
        add(l10n.reference, entry.id);
        add(l10n.source, l10n.driversVault);
      case HistoryKind.roadExpense:
        add(l10n.expenseType, l10n.roadExpenseApproval);
        add(l10n.submittedBy, entry.note);
        add(l10n.reference, entry.id);
        if (entry.relatedTripCodes.isNotEmpty) {
          rows.add(_SectionLabel(l10n.historyRelatedTrips));
          for (final (index, code) in entry.relatedTripCodes.indexed) {
            rows.add(
              _DetailRow(
                label: l10n.tripCode,
                value: code,
                valueKey: Key('history-detail-related-trip-$index'),
              ),
            );
          }
        }
    }
    return rows;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppPalette.of(context).muted,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Key? valueKey;

  const _DetailRow({required this.label, required this.value, this.valueKey});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.hairline)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.muted,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  key: valueKey,
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.title,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTextStyles.tabular,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One real event of a transaction. [current] marks the pending state the
/// transaction is in now, which has no timestamp of its own.
class _TimelineEvent {
  final String title;
  final String detail;
  final HistoryMarkState mark;
  final bool current;
  final String? note;

  const _TimelineEvent({
    required this.title,
    required this.detail,
    this.mark = HistoryMarkState.settled,
    this.current = false,
    this.note,
  });
}

class _Timeline extends StatelessWidget {
  final HistoryEntry entry;
  final String locale;

  const _Timeline({required this.entry, required this.locale});

  List<_TimelineEvent> _events(AppLocalizations l10n) {
    final status = historyStatusText(l10n, entry.status);
    final created = historyStamp(entry.createdAt, locale);
    if (!entry.hasPendingLifecycle) {
      return [_TimelineEvent(title: status, detail: created)];
    }
    final createdEvent = _TimelineEvent(
      title: l10n.timelineCreated,
      detail: created,
    );
    if (entry.isPending) {
      return [
        createdEvent,
        _TimelineEvent(
          title: l10n.timelineStillPending,
          detail: l10n.historyTimelineSince(status, created),
          current: true,
        ),
      ];
    }
    final rejected = entry.status == HistoryDisplayStatus.rejected;
    final returned =
        rejected &&
        (entry.kind == HistoryKind.outgoing ||
            entry.kind == HistoryKind.withdraw);
    return [
      createdEvent,
      _TimelineEvent(
        title: status,
        detail: historyStamp(entry.updatedAt, locale),
        mark: rejected ? HistoryMarkState.rejected : HistoryMarkState.settled,
        note: returned ? l10n.historyAmountReturned : null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final events = _events(l10n);
    return Column(
      key: const Key('history-detail-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, event) in events.indexed)
          _TimelineTile(
            event: event,
            connector: index == events.length - 1
                ? null
                : (events[index + 1].current
                      ? _Connector.dashed
                      : _Connector.solid),
          ),
      ],
    );
  }
}

enum _Connector { solid, dashed }

class _TimelineTile extends StatelessWidget {
  final _TimelineEvent event;
  final _Connector? connector;

  const _TimelineTile({required this.event, required this.connector});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final connector = this.connector;
    final note = event.note;
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  HistoryStateMark(
                    event.current ? HistoryMarkState.pending : event.mark,
                  ),
                  if (connector != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: CustomPaint(
                          size: const Size(2, double.infinity),
                          painter: _ConnectorPainter(
                            color: connector == _Connector.solid
                                ? palette.action
                                : palette.fieldBorder,
                            dashed: connector == _Connector.dashed,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: connector == null ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: event.mark == HistoryMarkState.rejected
                            ? palette.error
                            : palette.title,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.detail,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: palette.muted,
                        fontSize: 13,
                        fontFeatures: AppTextStyles.tabular,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        key: const Key('history-detail-amount-returned'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (event.current) ...[
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: palette.hairline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            l10n.historyTimelineCurrent,
                            style: AppTextStyles.helper.copyWith(
                              color: palette.body,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool dashed;

  const _ConnectorPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final x = size.width / 2;
    if (!dashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + 4).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

/// The balance figures the ledger stored for this operation, and a note on
/// when its money moves. Missing figures read Not recorded; nothing here is
/// ever calculated or reconstructed.
class _BalanceChange extends StatelessWidget {
  final HistoryEntry entry;
  final String locale;

  const _BalanceChange({required this.entry, required this.locale});

  ({bool figures, String? value, String note}) _copy(AppLocalizations l10n) {
    final pending = entry.isPending;
    final rejected = entry.status == HistoryDisplayStatus.rejected;
    return switch (entry.kind) {
      HistoryKind.expense => (
        figures: true,
        value: null,
        note: l10n.historyBalanceExpenseNote,
      ),
      HistoryKind.roadExpense => (
        figures: false,
        value: l10n.historyBalanceNoChange,
        note: l10n.historyBalanceRoadNote,
      ),
      HistoryKind.vault =>
        pending
            ? (
                figures: false,
                value: l10n.historyBalanceNotCreditedYet,
                note: l10n.historyBalanceCreditAfterYouApprove,
              )
            : (
                figures: true,
                value: null,
                note: l10n.historyBalanceCreditedWhenApproved,
              ),
      HistoryKind.incoming =>
        pending
            ? (
                figures: false,
                value: l10n.historyBalanceNotCreditedYet,
                note: l10n.historyBalanceCreditAfterYouApprove,
              )
            : rejected
            ? (
                figures: false,
                value: l10n.historyBalanceNoChange,
                note: l10n.historyBalanceNeverCredited,
              )
            : (
                figures: true,
                value: null,
                note: l10n.historyBalanceCreditedWhenApproved,
              ),
      HistoryKind.outgoing => (
        figures: true,
        value: null,
        note: pending
            ? l10n.historyBalanceSentPending
            : rejected
            ? l10n.historyBalanceSentReturned
            : l10n.historyBalanceSent,
      ),
      HistoryKind.requestCash =>
        pending
            ? (
                figures: false,
                value: l10n.historyBalanceNotCreditedYet,
                note: l10n.historyBalanceCreditAfterApproval,
              )
            : rejected
            ? (
                figures: false,
                value: l10n.historyBalanceNoChange,
                note: l10n.historyBalanceNeverCredited,
              )
            : (
                figures: true,
                value: null,
                note: l10n.historyBalanceCreditedWhenApproved,
              ),
      HistoryKind.withdraw => (
        figures: true,
        value: null,
        note: pending
            ? l10n.historyBalanceWithdrawPending
            : rejected
            ? l10n.historyBalanceWithdrawReturned
            : l10n.historyBalanceWithdraw,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final copy = _copy(l10n);
    final before = entry.balanceBeforeEgp;
    final after = entry.balanceAfterEgp;

    String figure(int? amount) => amount == null
        ? l10n.historyBalanceNotRecorded
        : formatHomeAmount(
            amount,
            locale: locale,
            withCurrency: true,
            currency: l10n.egp,
          );

    return Column(
      key: const Key('history-detail-balance-snapshot'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(l10n.balanceSnapshotTitle),
        if (copy.figures) ...[
          _FigureRow(
            label: l10n.historyBalanceBefore,
            value: figure(before),
            valueKey: const Key('history-detail-balance-before'),
            recorded: before != null,
          ),
          _FigureRow(
            label: l10n.historyBalanceAfter,
            value: figure(after),
            valueKey: const Key('history-detail-balance-after'),
            recorded: after != null,
          ),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                copy.value!,
                key: const Key('history-detail-balance-value'),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: palette.title,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.hairline)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              copy.note,
              key: const Key('history-detail-balance-note'),
              style: AppTextStyles.bodyMedium.copyWith(color: palette.body),
            ),
          ),
        ),
      ],
    );
  }
}

class _FigureRow extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  final bool recorded;

  const _FigureRow({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.recorded,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.hairline)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.muted,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                value,
                key: valueKey,
                style: recorded
                    ? AppTextStyles.bodyMedium.copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppTextStyles.tabular,
                      )
                    : AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
