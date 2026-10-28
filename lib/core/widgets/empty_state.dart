import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text_styles.dart';

/// Centered message for an empty or failed list: a tinted icon circle, a
/// title, and an optional hint.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Color? iconColor;
  final Color? iconBackground;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.iconColor,
    this.iconBackground,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground ?? AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 16,
              color: surfaces.title,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: surfaces.body),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
