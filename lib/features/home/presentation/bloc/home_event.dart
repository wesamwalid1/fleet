import 'dart:async';

import '../../../../core/loading/minimum_loading_window.dart';

sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeFinanceRetried extends HomeEvent {
  const HomeFinanceRetried();
}

/// Content-preserving finance summary reload.
///
/// When [done] is provided (manual pull-to-refresh), it completes after this
/// refresh attempt finishes — including domain failures that keep [HomeReady].
final class HomeSummaryRefreshed extends HomeEvent {
  final Completer<void>? done;

  /// When set, the result is held until this pull's sections reveal together.
  final MinimumLoadingWindow? window;

  const HomeSummaryRefreshed({this.done, this.window});
}
