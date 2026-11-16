import 'package:flutter/material.dart';

/// App-wide scroll behavior that paints a transient [Scrollbar] on vertical
/// scrollables only.
///
/// Horizontal content (filter chips, portal [PageView]) is left unchanged.
/// Thumb visibility follows Material defaults — never forced permanent.
class AlwaysScrollbarBehavior extends MaterialScrollBehavior {
  const AlwaysScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (details.direction) {
      case AxisDirection.up:
      case AxisDirection.down:
        return Scrollbar(
          controller: details.controller,
          child: child,
        );
      case AxisDirection.left:
      case AxisDirection.right:
        return child;
    }
  }
}
