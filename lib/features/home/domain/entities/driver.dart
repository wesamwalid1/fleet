import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  final String id;
  final String fullName;

  const Driver({this.id = 'DR-001', required this.fullName});

  /// First letter of the first word and first letter of the last word.
  /// A single word uses its first letter only.
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';

    String letter(String part) {
      final first = part.runes.first;
      return String.fromCharCode(first).toUpperCase();
    }

    if (parts.length == 1) return letter(parts.first);
    return '${letter(parts.first)}${letter(parts.last)}';
  }

  @override
  List<Object?> get props => [id, fullName];
}
