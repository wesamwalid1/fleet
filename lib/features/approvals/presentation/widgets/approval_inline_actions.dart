import 'package:flutter/material.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_item.dart';
import 'approval_sheets.dart';

/// Compact kind-specific decision controls shared by Home and Approvals.
///
/// Dispatches through [runApprovalSheetAction] so list and sheet stay on one
/// ApprovalsBloc path. Buttons sit outside the row ink well.
class ApprovalInlineActions extends StatelessWidget {
  static const double height = 40;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 0,
  );
  static const double gap = 8;
  static final TextStyle labelStyle = AppTextStyles.buttonLarge.copyWith(
    fontSize: 13,
    height: 1.1,
  );

  final ApprovalItem item;
  final bool enabled;
  final bool busy;
  final String keyPrefix;

  const ApprovalInlineActions({
    super.key,
    required this.item,
    required this.enabled,
    required this.busy,
    this.keyPrefix = 'approval',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final id = item.id;

    Future<void> run(ApprovalSheetAction action) =>
        runApprovalSheetAction(context, item, action);

    Widget positive({
      required Key key,
      required String label,
      required VoidCallback onPressed,
    }) {
      return Expanded(
        child: SizedBox(
          height: height,
          child: FilledButton(
            key: key,
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: palette.action,
              foregroundColor: palette.onAction,
              disabledBackgroundColor: palette.action.withValues(alpha: 0.35),
              disabledForegroundColor: palette.onAction.withValues(alpha: 0.7),
              minimumSize: const Size(44, height),
              padding: padding,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: labelStyle,
            ),
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onAction,
                    ),
                  )
                : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }

    Widget negative({
      required Key key,
      required String label,
      required VoidCallback onPressed,
      required Color foreground,
    }) {
      return Expanded(
        child: SizedBox(
          height: height,
          child: OutlinedButton(
            key: key,
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              side: BorderSide(color: foreground.withValues(alpha: 0.55)),
              minimumSize: const Size(44, height),
              padding: padding,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: labelStyle,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }

    // Approvals list keeps legacy `approval-action-<id>` on the primary CTA.
    Key primaryKey(String role) => keyPrefix == 'approval'
        ? Key('approval-action-$id')
        : Key('$keyPrefix-$role-$id');

    return switch (item.kind) {
      ApprovalKind.vault => Row(
        children: [
          positive(
            key: primaryKey('approve'),
            label: l10n.approve,
            onPressed: () => run(ApprovalSheetAction.approve),
          ),
        ],
      ),
      ApprovalKind.driver => Row(
        children: [
          negative(
            key: Key('$keyPrefix-decline-$id'),
            label: l10n.decline,
            onPressed: () => run(ApprovalSheetAction.decline),
            foreground: palette.title,
          ),
          const SizedBox(width: gap),
          positive(
            key: primaryKey('approve'),
            label: l10n.approve,
            onPressed: () => run(ApprovalSheetAction.approve),
          ),
        ],
      ),
      ApprovalKind.roadExpense => Row(
        children: [
          negative(
            key: Key('$keyPrefix-reject-$id'),
            label: l10n.reject,
            onPressed: () => run(ApprovalSheetAction.reject),
            foreground: palette.error,
          ),
          const SizedBox(width: gap),
          positive(
            key: primaryKey('confirm'),
            label: l10n.confirm,
            onPressed: () => run(ApprovalSheetAction.confirm),
          ),
        ],
      ),
    };
  }
}
