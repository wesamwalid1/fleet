import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws the frame a bloc read is waiting on.
///
/// Plain unit tests are not inside [WidgetTester.pump], and
/// [AutomatedTestWidgetsFlutterBinding.pump] refuses to run there. Drawing
/// through the scheduler still runs the production [SchedulerBinding.endOfFrame]
/// callback, so the read is not skipped.
Future<void> paintFrame() async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await Future<void>.delayed(Duration.zero);
  binding.handleBeginFrame(Duration.zero);
  binding.handleDrawFrame();
  await Future<void>.delayed(Duration.zero);
}

/// Paints frames until [future] completes.
///
/// Subscribe to the bloc stream first, then call this. Pumping before the
/// subscription would drop the event [Stream.firstWhere] is waiting for.
Future<T> withFrames<T>(Future<T> future) async {
  var done = false;
  final guarded = future.whenComplete(() => done = true);
  for (var i = 0; i < 8 && !done; i++) {
    await paintFrame();
  }
  if (!done) {
    throw StateError('the read did not finish after waiting for frames');
  }
  return guarded;
}
