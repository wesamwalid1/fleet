import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';
import '../theme/app_text_styles.dart';

/// Trailing content keeps its natural width up to [maxFraction] of the row
/// and scales down only past that cap; the leading content takes the rest.
class SplitRow extends StatelessWidget {
  final Widget leading;
  final Widget trailing;
  final double maxFraction;
  final CrossAxisAlignment crossAxisAlignment;

  const SplitRow({
    super.key,
    required this.leading,
    required this.trailing,
    this.maxFraction = 0.5,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Expanded(child: leading),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * maxFraction,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: crossAxisAlignment == CrossAxisAlignment.start
                    ? AlignmentDirectional.topEnd
                    : AlignmentDirectional.centerEnd,
                child: trailing,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Section heading with an optional trailing badge or link.
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? leading;

  const SectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    Widget heading = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.sectionTitle.copyWith(
        color: AppSurfaces.of(context).title,
      ),
    );
    if (leading != null) {
      heading = Row(
        children: [
          leading!,
          const SizedBox(width: 8),
          Flexible(child: heading),
        ],
      );
    }
    if (trailing == null) return heading;
    return SplitRow(leading: heading, trailing: trailing!, maxFraction: 0.45);
  }
}
