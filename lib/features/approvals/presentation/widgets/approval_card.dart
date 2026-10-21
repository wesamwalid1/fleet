import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    final style = _ApprovalStyle.of(item.kind);
    final pending = item.isPending;
    final background = pending
        ? style.background
        : item.outcome == ApprovalOutcome.rejected
        ? AppColors.neutralBackground
        : AppColors.successBackground;
    final foreground = pending ? style.foreground : AppColors.success;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('approval-card-${item.id}'),
        onTap: pending ? onOpen : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: pending ? style.border : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: style.icon, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(l10n, locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pending
                            ? AppColors.muted
                            : item.outcome == ApprovalOutcome.rejected
                            ? AppColors.error
                            : AppColors.success,
                        fontSize: 12,
                        fontWeight: pending ? FontWeight.w400 : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      signedApprovalAmount(
                        item.amountEgp,
                        locale: locale,
                        currency: l10n.egp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: item.outcome == ApprovalOutcome.rejected
                            ? AppColors.muted
                            : foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pending) ...[
                      const SizedBox(height: 8),
                      _ActionButton(
                        label: item.kind == ApprovalKind.roadExpense
                            ? l10n.confirm
                            : l10n.approve,
                        filled: item.kind != ApprovalKind.roadExpense,
                        onPressed: onOpen,
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

  String _title(AppLocalizations l10n) {
    return switch (item.kind) {
      ApprovalKind.vault => l10n.receivedFromVault,
      ApprovalKind.driver => l10n.receivedFromDriver(item.counterpartyName),
      ApprovalKind.roadExpense => l10n.roadExpenseApproval,
    };
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
    return switch (item.kind) {
      ApprovalKind.vault => '${l10n.driversVault} · ${cardRecency(l10n, item)}',
      ApprovalKind.driver =>
        '${item.counterpartyId} · ${cardRecency(l10n, item)}',
      ApprovalKind.roadExpense =>
        '${item.reference} · ${approvalClock(item.occurredAt, locale)}',
    };
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onPressed;
  final Key buttonKey;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    required this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      backgroundColor: WidgetStatePropertyAll(
        filled ? AppColors.success : AppColors.primary,
      ),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: style,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ApprovalStyle {
  final Color background;
  final Color foreground;
  final Color border;
  final IconData icon;

  const _ApprovalStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
  });

  static _ApprovalStyle of(ApprovalKind kind) {
    return switch (kind) {
      ApprovalKind.vault => const _ApprovalStyle(
        background: AppColors.warningBackground,
        foreground: AppColors.warningText,
        border: AppColors.warningBorder,
        icon: Icons.account_balance_outlined,
      ),
      ApprovalKind.driver => _ApprovalStyle(
        background: AppColors.successBackground,
        foreground: AppColors.success,
        border: AppColors.success.withValues(alpha: 0.28),
        icon: Icons.person_outline,
      ),
      ApprovalKind.roadExpense => _ApprovalStyle(
        background: AppColors.primary.withValues(alpha: 0.08),
        foreground: AppColors.primary,
        border: AppColors.primaryBorder,
        icon: Icons.description_outlined,
      ),
    };
  }
}
