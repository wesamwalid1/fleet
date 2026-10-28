import '../domain/internet_reachability.dart';
import '../domain/network_interface_monitor.dart';

/// Deterministic online sources for widget trees that omit app-level
/// connectivity (typical HomeScope-only tests). Production uses
/// [ConnectivityPlusMonitor] and [HttpInternetReachability] from
/// [DriverPortalApp].
class AlwaysOnlineNetworkMonitor implements NetworkInterfaceMonitor {
  const AlwaysOnlineNetworkMonitor();

  @override
  Future<bool> get hasInterface async => true;

  @override
  Stream<bool> get onChanged => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

class AlwaysReachableInternet implements InternetReachability {
  const AlwaysReachableInternet();

  @override
  Future<bool> check({Duration timeout = const Duration(seconds: 3)}) async =>
      true;

  @override
  Future<void> dispose() async {}
}
