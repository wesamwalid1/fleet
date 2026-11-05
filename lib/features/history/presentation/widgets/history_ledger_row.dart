import 'package:flutter/material.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/history_entry.dart';
import '../history_format.dart';

enum HistoryMarkState { settled, pending, rejected }

HistoryMarkState historyMarkState(HistoryDisplayStatus status) {
  return switch (status) {
    HistoryDisplayStatus.pendingConfirm ||
    HistoryDisplayStatus.awaitingApproval => HistoryMarkState.pending,
    HistoryDisplayStatus.rejected => HistoryMarkState.rejected,
    _ => HistoryMarkState.settled,
  };
}

/// Status as a shape rather than a colour: a filled check when settled, a
/// hollow ring while pending, and a cross in the error role when rejected.
class HistoryStateMark extends StatelessWidget {
  final HistoryMarkState state;
  final double size;

  const HistoryStateMark(this.state, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: switch (state) {
          HistoryMarkState.settled => DecoratedBox(
            decoration: BoxDecoration(
              color: palette.action,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: size * 0.68,
              color: palette.onAction,
            ),
          ),
          HistoryMarkState.pending => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.fieldBorder, width: 2),
            ),
          ),
          HistoryMarkState.rejected => DecoratedBox(
            decoration: BoxDecoration(
              color: palette.errorSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: size * 0.64,
              color: palette.error,
            ),
          ),
        },
      ),
    );
  }
}

/// One History ledger line: a state mark, the title over its reference and
/// status, and the signed amount over its time in one end-aligned column.
/// A pending amount is set quieter, as money that is reserved, not settled.
class HistoryLedgerRow extends StatelessWidget {
  /// Share of the row the amount column may take before it scales down. At
  /// large text sizes it gives way so a reference such as a trip code keeps
  /// to one line.
  static double maxTrailingFraction(TextScaler scaler) =>
      scaler.scale(1) >= 1.3 ? 0.34 : 0.42;

  final HistoryEntry entry;
  final String when;
  final bool highlighted;
  final VoidCallback onTap;

  const HistoryLedgerRow({
    super.key,
    required this.entry,
    required this.when,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final id = entry.id;
    final mark = historyMarkState(entry.status);
    final subtitle = historySubtitleParts(l10n, entry, markSettled: false);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: HistoryStateMark(mark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  key: Key('history-entry-details-$id'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historyTitle(l10n, entry),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    HistoryReferenceLine(
                      reference: subtitle.reference,
                      status: subtitle.status,
                      rejected: mark == HistoryMarkState.rejected,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      constraints.maxWidth *
                      maxTrailingFraction(MediaQuery.textScalerOf(context)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.topEnd,
                  child: Column(
                    key: Key('history-entry-values-$id'),
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        signedHistoryAmount(
                          entry,
                          locale: locale,
                          currency: l10n.egp,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: entry.isPending
                              ? palette.muted
                              : palette.title,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        when,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.helper.copyWith(
                          color: palette.muted,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: Key('history-entry-$id'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          highlightColor: palette.title.withValues(alpha: 0.06),
          splashColor: palette.title.withValues(alpha: 0.08),
          focusColor: palette.focus.withValues(alpha: 0.12),
          child: DecoratedBox(
            key: highlighted ? Key('history-highlight-$id') : null,
            decoration: BoxDecoration(
              color: highlighted
                  ? palette.action.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: row,
          ),
        ),
        const HistoryLedgerDivider(),
      ],
    );
  }
}

/// A row's reference and status. The reference, such as a trip code, never
/// breaks across lines; at large text sizes it scales down, and the status
/// moves to the next line. Only a rejected status takes the error role.
class HistoryReferenceLine extends StatelessWidget {
  final String? reference;
  final String status;
  final bool rejected;

  const HistoryReferenceLine({
    super.key,
    required this.reference,
    required this.status,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final style = AppTextStyles.bodyMedium.copyWith(
      color: palette.muted,
      fontSize: 13,
    );
    final statusText = Text(
      status,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: rejected ? style.copyWith(color: palette.error) : style,
    );
    final reference = this.reference;
    if (reference == null) return statusText;
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  reference,
                  maxLines: 1,
                  softWrap: false,
                  style: style.copyWith(fontFeatures: AppTextStyles.tabular),
                ),
              ),
            ),
            Text(' ·', style: style),
          ],
        ),
        statusText,
      ],
    );
  }
}

class HistoryLedgerDivider extends StatelessWidget {
  const HistoryLedgerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppPalette.of(context).hairline,
    );
  }
}
