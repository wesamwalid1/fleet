import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/presentation/settlement_style.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final arabic = RegExp(r'[\u0600-\u06FF]');
  final latin = RegExp(r'[A-Za-z]');

  test('settlement labels stay in the selected language', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final arabicLocale = await AppLocalizations.delegate.load(
      const Locale('ar'),
    );

    for (final type in SettlementType.values) {
      final englishLabel = settlementName(english, type);
      final arabicLabel = settlementName(arabicLocale, type);

      expect(englishLabel, isNotEmpty);
      expect(arabicLabel, isNotEmpty);
      expect(arabic.hasMatch(englishLabel), isFalse);
      expect(latin.hasMatch(arabicLabel), isFalse);
      expect(settlementTitle(english, type), englishLabel);
      expect(settlementTitle(arabicLocale, type), arabicLabel);
    }

    expect(SettlementType.fuel.name, 'fuel');
    expect(SettlementType.roadFeesClient.name, 'roadFeesClient');
  });
}
