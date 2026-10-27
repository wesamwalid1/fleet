import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Rounded label for counts and statuses. Use the tinted background with the
/// matching status text color, for example [AppColors.warningBackground]
/// with [AppColors.pendingText].
class StatusBadge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final Widget? leading;

  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.leading,
  });

  const StatusBadge.pending({super.key, required this.label})
    : foreground = AppColors.pendingText,
      background = AppColors.warningBackground,
      leading = null;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              maxLines: 1,
              style: AppTextStyles.badge.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
