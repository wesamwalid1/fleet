/// Watches whether the device has any usable network interface.
///
/// This does **not** prove Internet access — pair with [InternetReachability].
abstract class NetworkInterfaceMonitor {
  /// Current snapshot: true when Wi-Fi, mobile, ethernet, etc. is available.
  Future<bool> get hasInterface;

  /// Emits whenever the set of interfaces changes.
  Stream<bool> get onChanged;

  /// Releases native listeners. Safe to call more than once.
  Future<void> dispose();
}
