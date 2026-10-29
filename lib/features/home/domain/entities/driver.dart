import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/localization/localized_string.dart';

class Driver extends Equatable {
  final String id;
  final LocalizedString fullName;

  const Driver({this.id = 'DR-001', required this.fullName});

  String displayName([Object? localeOrCode]) => fullName.resolve(localeOrCode);

  String displayNameOf(BuildContext context) => fullName.of(context);

  /// First letter of the first word and first letter of the last word for the
  /// resolved locale. A single word uses its first letter only.
  String initials([Object? localeOrCode]) {
    final parts = fullName
        .resolve(localeOrCode)
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
