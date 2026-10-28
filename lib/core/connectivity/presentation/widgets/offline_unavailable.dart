import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/empty_state.dart';

/// Empty/unavailable state for list screens while offline, with Retry.
class OfflineUnavailable extends StatelessWidget {
  final String title;
  final String hint;
  final String retryLabel;
  final VoidCallback? onRetry;
  final bool retrying;

  const OfflineUnavailable({
    super.key,
    required this.title,
    required this.hint,
    required this.retryLabel,
    this.onRetry,
    this.retrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            key: const Key('offline-unavailable'),
            icon: Icons.cloud_off_outlined,
            title: title,
            hint: hint,
            iconColor: AppColors.warningText,
            iconBackground: AppColors.warningBackground,
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('offline-unavailable-retry'),
            onPressed: retrying ? null : onRetry,
            child: retrying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(retryLabel, style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
