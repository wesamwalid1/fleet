import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_theme.dart';
import 'app_sheet.dart';

/// Opens a themed filter sheet with Reset and Apply.
///
/// [bodyBuilder] edits a draft value. Reset restores [defaults]. Apply pops
/// the current draft (after optional [validate] returns null).
Future<T?> showFilterBottomSheet<T>({
  required BuildContext context,
  required String title,
  required T initial,
  required T defaults,
  required Widget Function(
    BuildContext context,
    T draft,
    ValueChanged<T> onChanged,
  )
  bodyBuilder,
  String? Function(T draft)? validate,
  String? resetLabel,
  String? applyLabel,
  Key? resetKey,
  Key? applyKey,
  double maxHeightFactor = 0.85,
}) {
  return showAppSheet<T>(
    context: context,
    maxHeightFactor: maxHeightFactor,
    builder: (context) {
      return _FilterBottomSheetHost<T>(
        title: title,
        initial: initial,
        defaults: defaults,
        bodyBuilder: bodyBuilder,
        validate: validate,
        resetLabel: resetLabel,
        applyLabel: applyLabel,
        resetKey: resetKey,
        applyKey: applyKey,
        maxHeightFactor: maxHeightFactor,
      );
    },
  );
}

class _FilterBottomSheetHost<T> extends StatefulWidget {
  final String title;
  final T initial;
  final T defaults;
  final Widget Function(
    BuildContext context,
    T draft,
    ValueChanged<T> onChanged,
  )
  bodyBuilder;
  final String? Function(T draft)? validate;
  final String? resetLabel;
  final String? applyLabel;
  final Key? resetKey;
  final Key? applyKey;
  final double maxHeightFactor;

  const _FilterBottomSheetHost({
    required this.title,
    required this.initial,
    required this.defaults,
    required this.bodyBuilder,
    this.validate,
    this.resetLabel,
    this.applyLabel,
    this.resetKey,
    this.applyKey,
    required this.maxHeightFactor,
  });

  @override
  State<_FilterBottomSheetHost<T>> createState() =>
      _FilterBottomSheetHostState<T>();
}

class _FilterBottomSheetHostState<T> extends State<_FilterBottomSheetHost<T>> {
  late T _draft;
  String? _error;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _onChanged(T value) {
    setState(() {
      _draft = value;
      _error = null;
    });
  }

  void _reset() {
    setState(() {
      _draft = widget.defaults;
      _error = null;
    });
  }

  void _apply() {
    final error = widget.validate?.call(_draft);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    final media = MediaQuery.of(context);
    final maxHeight =
        (media.size.height * widget.maxHeightFactor - media.viewInsets.bottom)
            .clamp(0.0, double.infinity);
    return Padding(
      key: const Key('filter-bottom-sheet'),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 14),
                SheetHeader(title: widget.title),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: widget.bodyBuilder(context, _draft, _onChanged),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    key: const Key('filter-sheet-error'),
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: widget.resetKey,
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: surfaces.title,
                          side: BorderSide(color: surfaces.border),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadii.control,
                            ),
                          ),
                        ),
                        child: Text(widget.resetLabel ?? l10n.reset),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        key: widget.applyKey,
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadii.control,
                            ),
                          ),
                        ),
                        child: Text(widget.applyLabel ?? l10n.apply),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-select option row used inside filter sheets.
class FilterOptionTile extends StatelessWidget {
  final Key? optionKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterOptionTile({
    super.key,
    this.optionKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final color = selected ? AppColors.primary : surfaces.title;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : surfaces.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: optionKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : surfaces.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
