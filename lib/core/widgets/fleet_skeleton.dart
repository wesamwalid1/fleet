import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';

/// Static stand-in for a list row. Uses the palette hairline, with no motion,
/// so a refresh reads the same way in English, Arabic, and reduced motion.
class FleetRowSkeleton extends StatelessWidget {
  final int rows;

  const FleetRowSkeleton({super.key, this.rows = 4});

  @override
  Widget build(BuildContext context) {
    final bar = AppPalette.of(context).hairline;
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                FleetSkeletonBar(width: 22, height: 22, radius: 11, color: bar),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FleetSkeletonBar(width: 150, height: 13, color: bar),
                      const SizedBox(height: 8),
                      FleetSkeletonBar(width: 96, height: 11, color: bar),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                FleetSkeletonBar(width: 70, height: 13, color: bar),
              ],
            ),
          ),
      ],
    );
  }
}

/// A short bar used in place of one refreshed value, such as a balance.
class FleetValueSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const FleetValueSkeleton({
    super.key,
    this.width = 72,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return FleetSkeletonBar(
      width: width,
      height: height,
      color: AppPalette.of(context).hairline,
    );
  }
}

class FleetSkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double radius;

  const FleetSkeletonBar({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
