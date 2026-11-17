import 'dart:async';

/// Keeps one coordinated refresh in its loading state until every participant
/// has finished and [minimum] has elapsed since the loading frame was painted.
///
/// Each participant starts its repository read immediately, then waits here
/// before revealing. A read that already took longer than [minimum] adds no
/// further delay. The first [markPainted] call sets the clock.
class MinimumLoadingWindow {
  MinimumLoadingWindow({
    required this.participants,
    this.minimum = duration,
    DateTime Function()? now,
    Future<void> Function(Duration delay)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  /// Floor for a manual pull. Initial load and reconnect do not use it.
  static const duration = Duration(milliseconds: 800);

  final int participants;
  final Duration minimum;
  final DateTime Function() _now;
  final Future<void> Function(Duration delay) _wait;

  DateTime? _paintedAt;
  var _finished = 0;
  Completer<void>? _release;

  /// Records the painted loading frame. The first call wins.
  void markPainted() {
    _paintedAt ??= _now();
  }

  /// Marks this participant finished. The returned future completes when
  /// every participant has finished and the minimum visibility has elapsed.
  Future<void> participantFinished() {
    final release = _release ??= Completer<void>();
    _finished += 1;
    if (_finished == participants) {
      unawaited(_open(release));
    }
    return release.future;
  }

  Future<void> _open(Completer<void> release) async {
    try {
      final painted = _paintedAt ?? _now();
      final remaining = minimum - _now().difference(painted);
      if (remaining > Duration.zero) {
        await _wait(remaining);
      }
    } finally {
      if (!release.isCompleted) release.complete();
    }
  }
}
