import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/expense_attachment.dart';
import '../domain/expense_attachment_picker.dart';
import '../domain/failures/expense_exception.dart';

class DeviceExpenseAttachmentPicker implements ExpenseAttachmentPicker {
  final ImagePicker _images;

  DeviceExpenseAttachmentPicker({ImagePicker? images})
    : _images = images ?? ImagePicker();

  @override
  Future<ExpenseAttachment?> pickCamera() {
    return _pickImage(ImageSource.camera);
  }

  @override
  Future<ExpenseAttachment?> pickGallery() {
    return _pickImage(ImageSource.gallery);
  }

  @override
  Future<ExpenseAttachment?> pickFile() async {
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return null;
      final path = file.path;
      if (path == null || path.isEmpty) {
        throw const ExpenseAttachmentFailedException();
      }
      return ExpenseAttachment(
        id: 'ATT-${DateTime.now().microsecondsSinceEpoch}',
        name: file.name,
        path: path,
        kind: ExpenseAttachmentKind.file,
      );
    } on ExpenseAttachmentFailedException {
      rethrow;
    } catch (_) {
      throw const ExpenseAttachmentFailedException();
    }
  }

  Future<ExpenseAttachment?> _pickImage(ImageSource source) async {
    try {
      final file = await _images.pickImage(source: source);
      if (file == null) return null;
      final name = file.name.trim().isEmpty ? 'photo' : file.name;
      return ExpenseAttachment(
        id: 'ATT-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        path: file.path,
        kind: ExpenseAttachmentKind.image,
      );
    } catch (_) {
      throw const ExpenseAttachmentFailedException();
    }
  }
}
