import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Light and Dark roles built from the official palette for redesigned
/// screens. Screens not yet redesigned keep using [AppSurfaces].
///
/// Light: mist ground, white surfaces, ink text and action.
/// Dark: ink ground, lifted navy surfaces, mist text and action.
class AppPalette {
  final bool isDark;

  const AppPalette._(this.isDark);

  factory AppPalette.of(BuildContext context) {
    return AppPalette._(Theme.of(context).brightness == Brightness.dark);
  }

  /// Page background.
  Color get ground => isDark ? AppColors.ink950 : AppColors.mist50;

  /// Raised surfaces such as the sign-in ticket.
  Color get surface => isDark ? AppColors.ink900 : Colors.white;

  /// Hairline outlines and the ticket's perforation.
  Color get hairline => isDark ? AppColors.ink800 : AppColors.slate100;

  /// Text field fill: inset below [surface].
  Color get field => isDark ? AppColors.ink950 : AppColors.mist25;

  /// Resting text field outline (3:1 or more against [field]).
  Color get fieldBorder => isDark ? AppColors.slate600 : AppColors.slate450;

  /// Focus outline, caret, and selection handles.
  Color get focus => isDark ? AppColors.slate100 : AppColors.ink900;

  Color get title => isDark ? AppColors.mist50 : AppColors.ink950;

  Color get body => isDark ? AppColors.slate300 : AppColors.ink800;

  /// Hints and tertiary text (4.5:1 or more on [ground], [surface], [field]).
  Color get muted => isDark ? AppColors.slate350 : AppColors.slate600;

  /// Field labels.
  Color get label => isDark ? AppColors.slate100 : AppColors.ink900;

  /// Primary action fill and its content.
  Color get action => isDark ? AppColors.slate100 : AppColors.ink900;
  Color get onAction => isDark ? AppColors.ink950 : Colors.white;

  /// Brand mark tile and its drawing.
  Color get mark => isDark ? AppColors.slate100 : AppColors.ink900;
  Color get onMark => isDark ? AppColors.ink900 : AppColors.slate100;

  Color get error => isDark ? AppColors.errorDark : AppColors.errorLight;
  Color get errorSurface =>
      isDark ? AppColors.errorSurfaceDark : AppColors.errorSurfaceLight;

  /// One soft offset shadow for raised surfaces.
  List<BoxShadow> get raisedShadow => isDark
      ? const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ]
      : [
          BoxShadow(
            color: AppColors.ink950.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.ink950.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

  /// System bars that match [ground].
  SystemUiOverlayStyle get systemBars => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: ground,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
  );
}

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
