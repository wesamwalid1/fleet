import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Corner radii shared by every surface.
abstract final class AppRadii {
  static const control = 16.0;
  static const field = 14.0;
  static const card = 20.0;
  static const panel = 24.0;
  static const sheet = 28.0;
  static const pill = 20.0;
}

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.title,
      onSurfaceVariant: AppColors.muted,
      error: AppColors.error,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    ),
    scaffold: AppColors.background,
    appBarForeground: AppColors.title,
    fieldFill: Colors.white,
    outlinedForeground: AppColors.title,
    outlinedBackground: Colors.white,
    sheetBackground: Colors.white,
    snackBackground: AppColors.title,
    divider: AppColors.title.withValues(alpha: 0.08),
  );

  /// Dark preference theme using ink tokens. Prefer [AppSurfaces] in feature
  /// widgets so hardcoded light fills follow the active brightness.
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: AppColors.inkLift,
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFFB0B8C4),
          error: AppColors.error,
          outline: const Color(0xFF3A3F55),
          outlineVariant: const Color(0xFF3A3F55),
        ),
    scaffold: AppColors.title,
    appBarForeground: Colors.white,
    fieldFill: AppColors.inkLift,
    outlinedForeground: Colors.white,
    outlinedBackground: AppColors.inkLift,
    sheetBackground: AppColors.inkLift,
    snackBackground: AppColors.inkLift,
    divider: Colors.white.withValues(alpha: 0.12),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffold,
    required Color appBarForeground,
    required Color fieldFill,
    required Color outlinedForeground,
    required Color outlinedBackground,
    required Color sheetBackground,
    required Color snackBackground,
    required Color divider,
  }) {
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    OutlineInputBorder field(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: appBarForeground,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brightness == Brightness.dark
              ? const Color(0xFF2A2F4A)
              : AppColors.neutralBackground,
          disabledForegroundColor: AppColors.hint,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: AppTextStyles.button,
          shape: control,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: outlinedForeground,
          backgroundColor: outlinedBackground,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: AppTextStyles.button,
          shape: control,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.link,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        hintStyle: const TextStyle(color: AppColors.hint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: field(scheme.outline),
        enabledBorder: field(scheme.outline),
        focusedBorder: field(AppColors.primary, 1.5),
        errorBorder: field(AppColors.error),
        focusedErrorBorder: field(AppColors.error, 1.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetBackground,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: sheetBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheetBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
        ),
        titleTextStyle: AppTextStyles.sheetTitle.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.body.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBackground,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.hint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),
    );
  }
}
