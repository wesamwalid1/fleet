import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';

/// Filter pill used above lists and inside filter sheets.
///
/// When [multiSelect] is true, uses [FilterChip] with a checkmark so several
/// chips can stay selected together.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool multiSelect;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.multiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final labelStyle = TextStyle(
      color: selected ? Colors.white : surfaces.title,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.pill),
    );
    final side = BorderSide(
      color: selected ? AppColors.primary : surfaces.border,
    );
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (multiSelect) {
      return FilterChip(
        label: labelWidget,
        selected: selected,
        showCheckmark: true,
        checkmarkColor: Colors.white,
        onSelected: (_) => onSelected(),
        labelStyle: labelStyle,
        selectedColor: AppColors.primary,
        backgroundColor: surfaces.chipIdle,
        side: side,
        shape: shape,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return ChoiceChip(
      label: labelWidget,
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      labelStyle: labelStyle,
      selectedColor: AppColors.primary,
      backgroundColor: surfaces.chipIdle,
      side: side,
      shape: shape,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Wrapping row of labeled filter chips with shared spacing.
class FilterChipWrap extends StatelessWidget {
  final List<Widget> children;

  const FilterChipWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}
