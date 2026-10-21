import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

Widget fileThumbnail(String path) {
  return Icon(
    Icons.image_outlined,
    color: AppColors.muted,
    semanticLabel: path,
  );
}
