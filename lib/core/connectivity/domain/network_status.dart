/// App-level connectivity status.
///
/// [offline] means no usable network interface.
/// [unreachable] means an interface is present but Internet reachability
/// could not be confirmed.
/// [online] means the reachability probe succeeded.
/// [checking] is a brief in-flight probe (startup, interface change, Retry).
enum NetworkStatus { offline, unreachable, online, checking }

extension NetworkStatusX on NetworkStatus {
  /// True when financial screens and login may proceed.
  bool get isOnline => this == NetworkStatus.online;

  /// True when the compact offline UX should be shown (not during a probe).
  bool get isUnavailable =>
      this == NetworkStatus.offline || this == NetworkStatus.unreachable;

  /// True when online work must wait or be blocked (offline, unreachable, or probing).
  bool get blocksOnlineWork => this != NetworkStatus.online;
}
