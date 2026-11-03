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

  // Official Driver Portal palette, the foundation of the redesign. Redesigned
  // screens read it through [AppPalette]; the rest keep the tokens above until
  // their turn.
  static const ink950 = Color(0xFF111522);
  static const ink900 = Color(0xFF1E263B);
  static const ink800 = Color(0xFF303D59);
  static const slate600 = Color(0xFF536684);
  static const slate300 = Color(0xFF98A9C4);
  static const slate100 = Color(0xFFDCE3EF);

  /// [slate100] halfway to white: the light page ground.
  static const mist50 = Color(0xFFEEF1F7);

  /// [slate100] a quarter of the way to white: light field fill.
  static const mist25 = Color(0xFFF6F8FB);

  /// Between [slate600] and [slate300]: light field outline, 3.4:1 or more on
  /// [mist25] and white.
  static const slate450 = Color(0xFF7687A4);

  /// [slate300] 30% toward [slate600]: dark-mode hints, 4.9:1 or more on
  /// [ink900] and [ink950].
  static const slate350 = Color(0xFF8395B1);

  /// Muted error text on light surfaces (5.7:1 on [errorSurfaceLight]).
  static const errorLight = Color(0xFFB42318);
  static const errorSurfaceLight = Color(0xFFFBEEEC);

  /// Error text on dark surfaces (6.4:1 on [errorSurfaceDark]).
  static const errorDark = Color(0xFFFDA29B);
  static const errorSurfaceDark = Color(0xFF3D3041);
}
