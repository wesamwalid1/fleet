import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

Widget fileThumbnail(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const Icon(Icons.image_outlined, color: AppColors.muted);
  }
  return Image.file(file, fit: BoxFit.cover, width: 72, height: 72);
}
