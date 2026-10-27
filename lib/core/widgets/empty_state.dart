import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Centered message for an empty or failed list: a tinted icon circle, a
/// title, and an optional hint.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Color iconColor;
  final Color iconBackground;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySurface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, textAlign: TextAlign.center, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}
