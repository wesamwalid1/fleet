import 'package:equatable/equatable.dart';

enum ExpenseAttachmentKind { image, file }

class ExpenseAttachment extends Equatable {
  final String id;
  final String name;
  final String path;
  final ExpenseAttachmentKind kind;

  const ExpenseAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.kind,
  });

  @override
  List<Object?> get props => [id, name, path, kind];
}
