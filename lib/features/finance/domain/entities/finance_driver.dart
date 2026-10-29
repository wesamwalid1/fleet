import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/localization/localized_string.dart';

class FinanceDriver extends Equatable {
  final String id;
  final LocalizedString fullName;
  final int balanceEgp;

  const FinanceDriver({
    required this.id,
    required this.fullName,
    required this.balanceEgp,
  });

  String displayName([Object? localeOrCode]) => fullName.resolve(localeOrCode);

  String displayNameOf(BuildContext context) => fullName.of(context);

  String initials([Object? localeOrCode]) {
    final parts = fullName
        .resolve(localeOrCode)
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

  String givenName([Object? localeOrCode]) {
    final resolved = fullName.resolve(localeOrCode);
    final parts = resolved
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.isEmpty ? resolved : parts.first;
  }

  @override
  List<Object?> get props => [id, fullName, balanceEgp];
}
