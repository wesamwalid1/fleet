/// On-demand check that the device can reach the public Internet.
///
/// The default implementation probes a well-known external endpoint and only
/// verifies **general Internet access**, not Driver Portal backend
/// availability (the API does not exist yet). Replace this with a backend
/// health endpoint (for example `GET /health`) when the API is available —
/// keep the same interface so [ConnectivityBloc] does not need to change.
abstract class InternetReachability {
  /// Returns true when the probe succeeds within [timeout].
  ///
  /// Timeouts, HTTP errors, and transport exceptions must return false
  /// (never throw to callers).
  Future<bool> check({Duration timeout = const Duration(seconds: 3)});

  /// Releases owned resources. Safe to call more than once.
  ///
  /// [ConnectivityBloc] is the sole owner and calls this from [close] only
  /// after any in-flight probe has finished.
  Future<void> dispose();
}
