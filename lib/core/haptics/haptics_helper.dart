import 'package:flutter/services.dart';

/// Fire-and-forget platform haptics for Fleet's restrained feedback policy.
///
/// Never await these from UI or business paths — they must not delay submits,
/// navigation, or snackbars.
class HapticsHelper {
  HapticsHelper._();

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void success() {
    HapticFeedback.mediumImpact();
  }

  static void error() {
    HapticFeedback.heavyImpact();
  }
}
