import '../../../l10n/app_localizations.dart';
import '../domain/greeting.dart';

String greetingText(AppLocalizations l10n, DateTime localTime) {
  return switch (greetingFor(localTime)) {
    GreetingPeriod.morning => l10n.goodMorning,
    GreetingPeriod.afternoon => l10n.goodAfternoon,
    GreetingPeriod.evening => l10n.goodEvening,
  };
}
