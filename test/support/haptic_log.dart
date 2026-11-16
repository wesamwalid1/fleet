import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures [HapticFeedback] platform calls without vibrating a device.
class HapticLog {
  HapticLog._(this.calls);

  final List<MethodCall> calls;

  static HapticLog install() {
    final log = HapticLog._(<MethodCall>[]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            log.calls.add(call);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    return log;
  }

  List<String> get feedbackTypes => calls
      .map((call) => call.arguments)
      .whereType<String>()
      .toList(growable: false);

  void clear() => calls.clear();

  void expectOnly(List<String> types) {
    expect(feedbackTypes, types);
  }

  void expectNone() {
    expect(feedbackTypes, isEmpty);
  }
}
