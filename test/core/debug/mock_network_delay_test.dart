import 'package:driver_portal_app/core/debug/mock_network_delay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolve defaults to zero without an override', () {
    expect(MockNetworkDelay.resolve(), Duration.zero);
  });

  test('resolve honors an explicit override for tests', () {
    expect(
      MockNetworkDelay.resolve(override: const Duration(milliseconds: 250)),
      const Duration(milliseconds: 250),
    );
  });

  test('wait with zero override completes immediately', () async {
    final sw = Stopwatch()..start();
    await MockNetworkDelay.wait(override: Duration.zero);
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(50));
  });
}
