import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// One money row: type avatar, a title over a status line, and the amount
/// over its time (and an optional action) on the trailing edge. The trailing
/// column keeps its natural width up to [maxTrailingFraction] of the row and
/// scales down past it, so long titles never push the amount off screen.
class ActivityRow extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final String amount;
  final Color amountColor;
  final String? when;
  final Widget? action;
  final Key? detailsKey;
  final Key? valuesKey;
  final double maxTrailingFraction;

  const ActivityRow({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.amount,
    required this.amountColor,
    this.when,
    this.action,
    this.detailsKey,
    this.valuesKey,
    this.maxTrailingFraction = 0.42,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                key: detailsKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowSubtitle.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * maxTrailingFraction,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.topEnd,
                child: Column(
                  key: valuesKey,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.amount.copyWith(color: amountColor),
                    ),
                    if (when != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        when!,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.caption,
                      ),
                    ],
                    if (action != null) ...[const SizedBox(height: 8), action!],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
