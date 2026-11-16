import 'package:driver_portal_app/core/haptics/haptics_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/haptic_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selection maps to selectionClick', () {
    final log = HapticLog.install();
    HapticsHelper.selection();
    log.expectOnly(['HapticFeedbackType.selectionClick']);
  });

  test('success maps to mediumImpact', () {
    final log = HapticLog.install();
    HapticsHelper.success();
    log.expectOnly(['HapticFeedbackType.mediumImpact']);
  });

  test('error maps to heavyImpact', () {
    final log = HapticLog.install();
    HapticsHelper.error();
    log.expectOnly(['HapticFeedbackType.heavyImpact']);
  });
}
