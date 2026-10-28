import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';

/// Theme-aware search field shared by list screens.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? clearTooltip;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showClear;
  final Key? fieldKey;
  final Key? clearKey;

  const AppSearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.clearTooltip,
    this.onChanged,
    this.onClear,
    this.showClear = false,
    this.fieldKey,
    this.clearKey,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: surfaces.title, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: surfaces.muted),
        prefixIcon: Icon(Icons.search_rounded, color: surfaces.muted),
        suffixIcon: showClear
            ? IconButton(
                key: clearKey,
                tooltip: clearTooltip,
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, color: surfaces.body),
              )
            : null,
        filled: true,
        fillColor: surfaces.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: _border(surfaces.border),
        enabledBorder: _border(surfaces.border),
        focusedBorder: _border(AppColors.primary, 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
