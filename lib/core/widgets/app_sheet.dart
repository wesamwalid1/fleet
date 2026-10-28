import 'package:flutter/material.dart';

import '../theme/app_surfaces.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Presents [builder] as the app's standard bottom sheet: themed surface,
/// rounded top corners, at most 640 wide and [maxHeightFactor] of the screen tall.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFactor = 0.92,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final height = MediaQuery.sizeOf(context).height;
  final surfaces = AppSurfaces.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: height * maxHeightFactor,
    ),
    backgroundColor: surfaces.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: builder,
  );
}

/// Drag affordance at the top of every sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: surfaces.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Title row of a sheet: an optional leading mark, the title over an
/// optional subtitle, and an optional close button at the trailing edge.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool showClose;
  final VoidCallback? onClose;
  final Key? closeKey;

  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showClose = false,
    this.onClose,
    this.closeKey,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final subtitle = this.subtitle;
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sheetTitle.copyWith(color: surfaces.title),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13.5,
                    color: surfaces.body,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showClose)
          IconButton(
            key: closeKey,
            onPressed: onClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(Icons.close_rounded, color: surfaces.muted),
          ),
      ],
    );
  }
}
