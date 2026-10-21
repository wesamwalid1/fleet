import 'package:equatable/equatable.dart';

class FinanceDriver extends Equatable {
  final String id;
  final String fullName;
  final int balanceEgp;

  const FinanceDriver({
    required this.id,
    required this.fullName,
    required this.balanceEgp,
  });

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';

    String letter(String part) =>
        String.fromCharCode(part.runes.first).toUpperCase();

    if (parts.length == 1) return letter(parts.first);
    return '${letter(parts.first)}${letter(parts.last)}';
  }

  String get givenName {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.isEmpty ? fullName : parts.first;
  }

  @override
  List<Object?> get props => [id, fullName, balanceEgp];
}
