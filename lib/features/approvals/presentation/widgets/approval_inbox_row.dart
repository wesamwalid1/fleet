import 'package:flutter/material.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_item.dart';
import '../approval_format.dart';

enum ApprovalMarkState { pending, approved, rejected }

ApprovalMarkState approvalMarkState(ApprovalOutcome outcome) {
  return switch (outcome) {
    ApprovalOutcome.pending => ApprovalMarkState.pending,
    ApprovalOutcome.approved => ApprovalMarkState.approved,
    ApprovalOutcome.rejected => ApprovalMarkState.rejected,
  };
}

/// Shape mark for Approvals: ring while pending, check when approved, cross
/// when rejected. Error color is used only for rejection.
class ApprovalKindMark extends StatelessWidget {
  final ApprovalMarkState state;
  final double size;

  const ApprovalKindMark(this.state, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: switch (state) {
          ApprovalMarkState.approved => DecoratedBox(
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
          ApprovalMarkState.pending => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.fieldBorder, width: 2),
            ),
          ),
          ApprovalMarkState.rejected => DecoratedBox(
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

/// Approvals-local inbox row for The Desk. Pending rows open the review sheet
/// via [onOpen]; the CTA does the same and never dispatches a ledger action.
class ApprovalInboxRow extends StatelessWidget {
  final ApprovalItem item;
  final VoidCallback? onOpen;
  final bool busy;

  const ApprovalInboxRow({
    super.key,
    required this.item,
    this.onOpen,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pending = item.isPending;
    final mark = approvalMarkState(item.outcome);
    final enabled = pending && onOpen != null && !busy;
    final amount = approvalAmount(
      item.amountEgp,
      locale: locale,
      currency: l10n.egp,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('approval-card-${item.id}'),
        onTap: enabled
            ? onOpen
            : (!pending && onOpen != null && !busy ? onOpen : null),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: ApprovalKindMark(mark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  key: Key('approval-details-${item.id}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approvalTitle(l10n, item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(l10n, locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: mark == ApprovalMarkState.rejected
                            ? palette.error
                            : palette.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 148),
                child: Column(
                  key: Key('approval-values-${item.id}'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        amount,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: palette.title,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                      ),
                    ),
                    if (pending) ...[
                      const SizedBox(height: 8),
                      _InboxAction(
                        label: item.kind == ApprovalKind.roadExpense
                            ? l10n.confirm
                            : l10n.approve,
                        onPressed: enabled ? onOpen : null,
                        buttonKey: Key('approval-action-${item.id}'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, String locale) {
    if (!item.isPending) {
      final when = approvalStamp(item.finalizedAt ?? item.occurredAt, locale);
      final outcome = item.outcome == ApprovalOutcome.rejected
          ? l10n.rejected
          : l10n.approved;
      return '$outcome · $when';
    }
    final when = item.kind == ApprovalKind.roadExpense
        ? approvalClock(item.occurredAt, locale)
        : cardRecency(l10n, item);
    return '${approvalSource(l10n, item)} · $when';
  }
}

class _InboxAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Key buttonKey;

  const _InboxAction({
    required this.label,
    required this.onPressed,
    required this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      height: 48,
      child: FilledButton(
        key: buttonKey,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.action,
          foregroundColor: palette.onAction,
          disabledBackgroundColor: palette.action.withValues(alpha: 0.4),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonLarge,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Hairline under an inbox row.
class ApprovalInboxDivider extends StatelessWidget {
  const ApprovalInboxDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppPalette.of(context).hairline,
    );
  }
}
