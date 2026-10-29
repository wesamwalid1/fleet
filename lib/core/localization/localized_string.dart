import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Bilingual display text stored on domain entities (people, places).
///
/// [en] is required. [ar] may be empty; [resolve] then falls back to [en]
/// so UI never shows a blank name.
class LocalizedString extends Equatable {
  final String en;
  final String ar;

  const LocalizedString({required this.en, this.ar = ''});

  static const empty = LocalizedString(en: '');

  /// Picks Arabic when the language code is `ar`, otherwise English.
  /// Empty Arabic falls back to English.
  String resolve([Object? localeOrCode]) {
    final code = _languageCode(localeOrCode);
    if (code.startsWith('ar')) {
      final trimmed = ar.trim();
      return trimmed.isEmpty ? en : ar;
    }
    return en;
  }

  static String _languageCode(Object? localeOrCode) {
    return switch (localeOrCode) {
      Locale(:final languageCode) => languageCode,
      String value => value,
      AppLocalizations(:final localeName) => localeName,
      _ => 'en',
    };
  }

  bool get isEmpty => en.trim().isEmpty && ar.trim().isEmpty;

  /// Case-insensitive match against either language (for search).
  bool matchesQuery(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return en.toLowerCase().contains(needle) ||
        ar.toLowerCase().contains(needle);
  }

  @override
  List<Object?> get props => [en, ar];
}

extension LocalizedStringContext on LocalizedString {
  String of(BuildContext context) => resolve(Localizations.localeOf(context));

  String tr(AppLocalizations l10n) => resolve(l10n.localeName);
}
