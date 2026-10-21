import 'package:flutter/material.dart';

import 'attachment_thumbnail_stub.dart'
    if (dart.library.io) 'attachment_thumbnail_io.dart'
    as preview;

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense_attachment.dart';

Widget attachmentThumbnail(ExpenseAttachment attachment) {
  if (attachment.kind != ExpenseAttachmentKind.image) {
    return Icon(Icons.insert_drive_file_outlined, color: AppColors.muted);
  }
  return preview.fileThumbnail(attachment.path);
}
