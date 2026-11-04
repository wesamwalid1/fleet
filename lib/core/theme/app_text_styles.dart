import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale shared by every screen. Amounts and times use tabular
/// figures so columns of numbers line up.
abstract final class AppTextStyles {
  static const tabular = [FontFeature.tabularFigures()];

  /// Title of a tab page (Approvals, History).
  static const pageTitle = TextStyle(
    color: AppColors.title,
    fontSize: 26,
    height: 1.15,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w800,
  );

  /// Title of a pushed page's app bar.
  static const appBarTitle = TextStyle(
    color: AppColors.title,
    fontSize: 22,
    height: 1.2,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w800,
  );

  /// Title of a bottom sheet or dialog.
  static const sheetTitle = TextStyle(
    color: AppColors.title,
    fontSize: 20,
    height: 1.25,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w800,
  );

  /// Heading of a section within a page or sheet.
  static const sectionTitle = TextStyle(
    color: AppColors.title,
    fontSize: 18,
    height: 1.2,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w800,
  );

  /// Small heading above a group of rows, such as a day in History.
  static const groupLabel = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w700,
  );

  static const rowTitle = TextStyle(
    color: AppColors.title,
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  /// Second line of a row; callers set the status color.
  static const rowSubtitle = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static const amount = TextStyle(
    color: AppColors.title,
    fontSize: 15.5,
    height: 1.25,
    fontWeight: FontWeight.w800,
    fontFeatures: tabular,
  );

  static const caption = TextStyle(
    color: AppColors.muted,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    fontFeatures: tabular,
  );

  static const body = TextStyle(
    color: AppColors.muted,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Label above a form field.
  static const fieldLabel = TextStyle(
    color: AppColors.title,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const button = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800);

  static const badge = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    fontFeatures: tabular,
  );

  static const link = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

  // Redesign type scale for screens on [AppPalette], mapped to Material 3
  // roles; callers set the color. No negative tracking, so Arabic letters
  // stay joined.

  /// headlineMedium: screen headline, such as the sign-in welcome.
  static const display = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  /// titleLarge: a person's name or a sheet title.
  static const title = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  /// titleMedium: product name in a brand row.
  static const brand = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  /// bodyLarge.
  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// bodyMedium: notices and help lines.
  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// labelLarge: label above a field.
  static const label = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Text typed into a field.
  static const input = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  /// bodySmall: field errors and small data fields.
  static const helper = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// labelLarge, emphasised: primary action text.
  static const buttonLarge = TextStyle(
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
}
