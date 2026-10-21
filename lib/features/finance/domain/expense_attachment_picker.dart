import 'entities/expense_attachment.dart';

abstract class ExpenseAttachmentPicker {
  Future<ExpenseAttachment?> pickCamera();

  Future<ExpenseAttachment?> pickGallery();

  Future<ExpenseAttachment?> pickFile();
}
