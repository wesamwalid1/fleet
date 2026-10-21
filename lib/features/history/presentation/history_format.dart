import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../finance/presentation/settlement_style.dart';
import '../../home/presentation/amount_format.dart';
import '../domain/entities/history_entry.dart';

String signedHistoryAmount(
  HistoryEntry entry, {
  required String locale,
  required String currency,
}) {
  final amount = formatHomeAmount(
    entry.amountEgp,
    locale: locale,
    withCurrency: true,
    currency: currency,
  );
  return entry.credit ? '+$amount' : '-$amount';
}

String historyClock(DateTime time, String locale) {
  return DateFormat.jm(locale).format(time);
}

/// Compact stamp for a Home row: today's clock, "Yesterday", or the calendar day.
String recentWhenLabel(
  AppLocalizations l10n,
  DateTime occurredAt,
  DateTime now,
  String locale,
) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
  if (day == today) return historyClock(occurredAt, locale);
  if (day == today.subtract(const Duration(days: 1))) return l10n.yesterday;
  return historyDayLabel(day, locale);
}

String historyDayLabel(DateTime day, String locale) {
  return DateFormat('d MMM y', locale).format(day);
}

String historyDayHeader(
  AppLocalizations l10n,
  DateTime day,
  DateTime now,
  String locale,
) {
  final label = historyDayLabel(day, locale);
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(day.year, day.month, day.day);
  if (date == today) return l10n.historyToday(label);
  final yesterday = today.subtract(const Duration(days: 1));
  if (date == yesterday) return l10n.historyYesterday(label);
  return label;
}

String historyTitle(AppLocalizations l10n, HistoryEntry entry) {
  return switch (entry.kind) {
    HistoryKind.expense => settlementName(l10n, entry.settlementType!),
    HistoryKind.vault => l10n.receivedFromVault,
    HistoryKind.incoming when entry.isPending => l10n.pendingFrom(
      entry.counterpartyName,
    ),
    HistoryKind.incoming => l10n.receivedFromDriver(entry.counterpartyName),
    HistoryKind.outgoing => l10n.sentTo(entry.counterpartyName),
  };
}

String historyStatusText(AppLocalizations l10n, HistoryDisplayStatus status) {
  return switch (status) {
    HistoryDisplayStatus.recorded => l10n.recorded,
    HistoryDisplayStatus.approved => l10n.approved,
    HistoryDisplayStatus.confirmed => l10n.confirmed,
    HistoryDisplayStatus.rejected => l10n.rejected,
    HistoryDisplayStatus.pendingConfirm => l10n.pendingConfirm,
    HistoryDisplayStatus.awaitingApproval => l10n.awaitingYourApproval,
  };
}

String historySubtitle(AppLocalizations l10n, HistoryEntry entry) {
  final status = historyStatusText(l10n, entry.status);
  final marked = switch (entry.status) {
    HistoryDisplayStatus.recorded ||
    HistoryDisplayStatus.approved ||
    HistoryDisplayStatus.confirmed => '$status ✓',
    _ => status,
  };
  if (entry.status == HistoryDisplayStatus.awaitingApproval &&
      entry.kind == HistoryKind.incoming) {
    return marked;
  }
  final reference = switch (entry.kind) {
    HistoryKind.expense => entry.tripCode,
    HistoryKind.vault => l10n.driversVault,
    HistoryKind.incoming || HistoryKind.outgoing => entry.counterpartyId,
  };
  return '$reference · $marked';
}
