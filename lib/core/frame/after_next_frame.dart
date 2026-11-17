import 'dart:async';

import 'package:flutter/scheduler.dart';

/// Completes after the next frame has been built and painted.
///
/// Call this immediately after emitting a loading state and before awaiting
/// the read or emitting its result. A repository that finishes in a microtask
/// then still leaves one real frame of loading UI on screen.
///
/// This is a frame boundary, not a timer. The callback is registered for a
/// frame that has not built yet, and it completes from that frame's post-frame
/// callback. Completing on the current frame is too early: a refresh that
/// starts during an in-progress frame would otherwise replace loading before
/// Flutter paints it.
///
/// After this returns, the caller must check that its owner is still mounted
/// or that the BLoC is still open before emitting. A newer read that has
/// already superseded this one must drop the result.
Future<void> afterNextFrame() {
  final binding = SchedulerBinding.instance;
  final completer = Completer<void>();
  binding.scheduleFrameCallback((_) {
    binding.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
  });
  return completer.future;
}
