import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../finance/domain/entities/approval_timing.dart';
import '../../home/presentation/amount_format.dart';
import '../domain/entities/approval_item.dart';

String signedApprovalAmount(
  int amountEgp, {
  required String locale,
  required String currency,
}) {
  return '+${formatHomeAmount(amountEgp, locale: locale, withCurrency: true, currency: currency)}';
}

String approvalAmount(
  int amountEgp, {
  required String locale,
  required String currency,
}) {
  return formatHomeAmount(
    amountEgp,
    locale: locale,
    withCurrency: true,
    currency: currency,
  );
}

String approvalDay(DateTime date, String locale) {
  return DateFormat('d MMM y', locale).format(date);
}

String approvalStamp(DateTime date, String locale) {
  return DateFormat('d MMM, HH:mm', locale).format(date);
}

String approvalClock(DateTime date, String locale) {
  return DateFormat('d MMM · h:mm a', locale).format(date);
}

String approvalPeriod(DateTime start, DateTime end, String locale) {
  final format = DateFormat('dd MMM y', locale);
  return '${format.format(start)} – ${format.format(end)}';
}

String cardRecency(AppLocalizations l10n, ApprovalItem item) {
  return switch (item.recency) {
    ApprovalRecency.justNow => l10n.justNow,
    ApprovalRecency.minutesAgo => l10n.minutesAgo(item.minutes),
    null => '',
  };
}

String detailWhen(AppLocalizations l10n, ApprovalItem item, String locale) {
  final day = approvalDay(item.occurredAt, locale);
  final relative = switch (item.recency) {
    ApprovalRecency.justNow => l10n.now,
    ApprovalRecency.minutesAgo => l10n.minutesAgo(item.minutes),
    null => '',
  };
  if (relative.isEmpty) return day;
  return '$day · $relative';
}
