import 'package:flutter/foundation.dart';

/// Optional artificial latency for mock repositories during development.
///
/// Release/profile builds always resolve to [Duration.zero] unless an explicit
/// [override] is passed (tests only).
///
/// Debug builds honor `--dart-define=MOCK_NETWORK_DELAY_MS=<ms>` (default 0).
/// Use the VS Code/Cursor launch config **driver_portal_app (mock latency)**
/// (`MOCK_NETWORK_DELAY_MS=1200`) or:
/// `flutter run --dart-define=MOCK_NETWORK_DELAY_MS=1200`
abstract final class MockNetworkDelay {
  static const _ms = int.fromEnvironment(
    'MOCK_NETWORK_DELAY_MS',
    defaultValue: 0,
  );

  /// Resolved delay for mock I/O. Prefer injecting [override] in tests.
  static Duration resolve({Duration? override}) {
    if (override != null) return override;
    if (!kDebugMode || _ms <= 0) return Duration.zero;
    return Duration(milliseconds: _ms);
  }

  static Future<void> wait({Duration? override}) async {
    // [override] is the already-resolved delay from the repository constructor.
    final delay = override ?? resolve();
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }
}
