import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware surfaces for screens that still paint with explicit colors.
///
/// Light values match the existing Light Mode look. Dark values reuse the ink
/// tokens already used by [AppTheme.dark]. Prefer this over hardcoding
/// [Colors.white] / [AppColors.background] on page roots, cards, and sheets.
class AppSurfaces {
  final bool isDark;

  const AppSurfaces._(this.isDark);

  factory AppSurfaces.of(BuildContext context) {
    return AppSurfaces._(Theme.of(context).brightness == Brightness.dark);
  }

  /// Page / shell background.
  Color get scaffold => isDark ? AppColors.title : AppColors.background;

  /// Raised cards, menu groups, list tiles.
  Color get card => isDark ? AppColors.inkLift : Colors.white;

  /// Modal bottom sheets and dialogs.
  Color get sheet => isDark ? AppColors.inkLift : Colors.white;

  /// Text field fills.
  Color get field => isDark ? AppColors.inkLift : Colors.white;

  /// Primary body title text on [card] / [scaffold].
  Color get title => isDark ? Colors.white : AppColors.title;

  /// Secondary body text.
  Color get body => isDark ? const Color(0xFFB0B8C4) : AppColors.muted;

  /// Hints and tertiary labels.
  Color get muted => isDark ? const Color(0xFF98A2B3) : AppColors.hint;

  /// Borders and chip outlines.
  Color get border => isDark ? const Color(0xFF3A3F55) : AppColors.border;

  /// Hairline dividers.
  Color get divider => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : AppColors.title.withValues(alpha: 0.08);

  /// Unselected filter chip background.
  Color get chipIdle => isDark ? AppColors.inkLift : Colors.white;

  /// Soft grouped panel (lavender in light, lifted ink in dark).
  Color get panel =>
      isDark ? const Color(0xFF2C3158) : AppColors.primarySurface;

  /// Neutral secondary panel.
  Color get neutral =>
      isDark ? const Color(0xFF2A2F4A) : AppColors.neutralBackground;

  /// Frosted bottom-nav glass fill.
  Color get navGlass => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.92);

  /// Frosted bottom-nav edge.
  Color get navEdge => isDark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.70);

  /// Inactive nav icon color.
  Color get navIcon => isDark
      ? const Color(0xFFB0B8C4)
      : Color.lerp(AppColors.title, AppColors.muted, 0.2)!;
}
