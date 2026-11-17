import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';

/// Fleet-styled pull-to-refresh wrapper around Material [RefreshIndicator].
///
/// UI-only: each screen supplies its own [onRefresh] Future. This widget does
/// not talk to BLoCs, connectivity, SnackBars, or repositories.
///
/// Place the caller's primary vertical scrollable as [child] and keep that
/// scrollable's [ScrollController] ownership unchanged. For short or empty
/// content, pass [AlwaysScrollableScrollPhysics] on the scrollable itself —
/// this wrapper does not insert an extra scrollable.
///
/// Error contract: failures from [onRefresh] are not caught here. Material's
/// [RefreshIndicator] still dismisses via `whenComplete`; domain/UI feedback
/// belongs to the screen integration. Prefer completing [onRefresh]
/// successfully after handling errors when zone noise is undesirable.
class FleetRefreshIndicator extends StatelessWidget {
  /// Invoked when the user pulls past the refresh threshold.
  ///
  /// The indicator stays visible until this Future completes (success or
  /// error).
  final Future<void> Function() onRefresh;

  /// The scrollable content tree. Must include a vertical [Scrollable]
  /// descendant; typically a [ListView] or [CustomScrollView].
  final Widget child;

  const FleetRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Matches portal-tab [CircularProgressIndicator] stroke used across Fleet.
  static const double strokeWidth = 2.2;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: palette.action,
      backgroundColor: palette.surface,
      strokeWidth: strokeWidth,
      elevation: 0,
      child: child,
    );
  }
}
