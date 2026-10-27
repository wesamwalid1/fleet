import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const background = Color(0xFFF3F4F6);
  static const title = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const hint = Color(0xFF98A2B3);
  static const border = Color(0xFFE4E7EC);
  static const primaryBorder = Color(0xFFD6D3F5);
  static const error = Color(0xFFF04438);
  static const success = Color(0xFF12B76A);
  static const successBackground = Color(0xFFECFDF3);
  static const warningBackground = Color(0xFFFFF7ED);
  static const warningBorder = Color(0xFFFEC84B);
  static const warningText = Color(0xFFDC6803);
  static const dangerBackground = Color(0xFFFFF1F3);
  static const dangerBorder = Color(0xFFFECDCA);
  static const info = Color(0xFF1570EF);
  static const infoBackground = Color(0xFFEFF8FF);
  static const pink = Color(0xFFEE46BC);
  static const pinkBackground = Color(0xFFFDF2FA);
  static const neutralBackground = Color(0xFFF2F4F7);

  /// Top of the dark wallet plane: [title] lifted 22% toward [primary].
  static const inkLift = Color(0xFF242752);

  /// [primary] lightened for accents on the dark plane (8:1 on [title]).
  static const primaryOnInk = Color(0xFFAEA5F2);

  /// Lavender surface for grouped content inside white sheets.
  static const primarySurface = Color(0xFFF5F4FD);

  /// Status text shades that keep 4.5:1 on white and on their tinted
  /// backgrounds: credited or approved, waiting, and rejected.
  static const creditText = Color(0xFF116F4C);
  static const pendingText = Color(0xFF954C10);
  static const rejectedText = Color(0xFFAD3733);
}
