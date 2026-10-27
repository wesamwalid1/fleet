import 'package:flutter/material.dart';

import '../../../../core/assets/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/activity_row.dart';
import '../../../../core/widgets/type_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_item.dart';
import '../approval_format.dart';

class ApprovalCard extends StatelessWidget {
  final ApprovalItem item;
  final VoidCallback? onOpen;

  const ApprovalCard({super.key, required this.item, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pending = item.isPending;
    final rejected = item.outcome == ApprovalOutcome.rejected;
    final radius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        key: Key('approval-card-${item.id}'),
        onTap: pending ? onOpen : null,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: pending ? AppColors.primaryBorder : AppColors.border,
            ),
          ),
          child: ActivityRow(
            avatar: approvalAvatar(item, faded: !pending),
            title: approvalTitle(l10n, item),
            subtitle: _subtitle(l10n, locale),
            subtitleColor: pending
                ? AppColors.pendingText
                : rejected
                ? AppColors.rejectedText
                : AppColors.creditText,
            amount: signedApprovalAmount(
              item.amountEgp,
              locale: locale,
              currency: l10n.egp,
            ),
            amountColor: pending
                ? AppColors.title
                : rejected
                ? AppColors.muted
                : AppColors.creditText,
            detailsKey: Key('approval-details-${item.id}'),
            valuesKey: Key('approval-values-${item.id}'),
            action: pending
                ? _ActionButton(
                    label: item.kind == ApprovalKind.roadExpense
                        ? l10n.confirm
                        : l10n.approve,
                    onPressed: onOpen,
                    buttonKey: Key('approval-action-${item.id}'),
                  )
                : null,
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
      final mark = item.outcome == ApprovalOutcome.rejected ? '' : ' ✓';
      return '$outcome$mark · $when';
    }
    final when = item.kind == ApprovalKind.roadExpense
        ? approvalClock(item.occurredAt, locale)
        : cardRecency(l10n, item);
    return '${approvalSource(l10n, item)} · $when';
  }
}

/// Type mark for an approval request, shared by Home and Approvals.
TypeAvatar approvalAvatar(ApprovalItem item, {bool faded = false}) {
  final (asset, tint) = switch (item.kind) {
    ApprovalKind.vault => (AppIcons.vault, AppColors.warningBackground),
    ApprovalKind.driver => (AppIcons.person, AppColors.successBackground),
    ApprovalKind.roadExpense => (AppIcons.invoice, AppColors.primarySurface),
  };
  return TypeAvatar.asset(
    asset,
    tint: faded ? AppColors.neutralBackground : tint,
    opacity: faded ? 0.6 : 1,
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Key buttonKey;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
