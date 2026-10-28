import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'app_search_field.dart';

/// Search field with a Filter button beside it.
class SearchFilterBar extends StatelessWidget {
  final TextEditingController? controller;
  final String searchHint;
  final String? clearTooltip;
  final String filterLabel;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback onFilterTap;
  final bool showClear;
  final bool filterActive;
  final Key? searchKey;
  final Key? clearKey;
  final Key? filterKey;

  const SearchFilterBar({
    super.key,
    this.controller,
    required this.searchHint,
    this.clearTooltip,
    required this.filterLabel,
    this.onChanged,
    this.onClear,
    required this.onFilterTap,
    this.showClear = false,
    this.filterActive = false,
    this.searchKey,
    this.clearKey,
    this.filterKey,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AppSearchField(
              controller: controller,
              hintText: searchHint,
              clearTooltip: clearTooltip,
              onChanged: onChanged,
              onClear: onClear,
              showClear: showClear,
              fieldKey: searchKey,
              clearKey: clearKey,
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: OutlinedButton.icon(
              key: filterKey,
              onPressed: onFilterTap,
              icon: Icon(
                Icons.tune_rounded,
                size: 18,
                color: filterActive ? AppColors.primary : surfaces.title,
              ),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(filterLabel)),
              style: OutlinedButton.styleFrom(
                foregroundColor: filterActive
                    ? AppColors.primary
                    : surfaces.title,
                side: BorderSide(
                  color: filterActive ? AppColors.primary : surfaces.border,
                ),
                backgroundColor: filterActive
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : surfaces.field,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
