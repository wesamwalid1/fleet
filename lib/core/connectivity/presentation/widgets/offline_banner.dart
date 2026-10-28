import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../domain/network_status.dart';

/// Compact offline strip shown above authenticated shell content.
class OfflineBanner extends StatelessWidget {
  final NetworkStatus status;
  final String title;
  final String hint;
  final String retryLabel;
  final VoidCallback? onRetry;
  final bool retrying;

  const OfflineBanner({
    super.key,
    required this.status,
    required this.title,
    required this.hint,
    required this.retryLabel,
    this.onRetry,
    this.retrying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isOnline) return const SizedBox.shrink();

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $hint',
      child: Material(
        key: const Key('offline-banner'),
        color: AppColors.warningBackground,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.warningText,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.rowTitle.copyWith(
                          color: AppColors.warningText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.pendingText,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('offline-banner-retry'),
                  onPressed: retrying ? null : onRetry,
                  child: retrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
