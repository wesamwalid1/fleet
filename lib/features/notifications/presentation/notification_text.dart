import 'package:flutter/material.dart';

import '../../../core/assets/app_icons.dart';
import '../../../core/localization/localized_string.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../history/presentation/history_format.dart';
import '../../home/presentation/amount_format.dart';
import '../domain/entities/app_notification.dart';

String notificationTitle(
  AppLocalizations l10n,
  AppNotification n,
  String locale,
) {
  final name = n.counterpartyName.tr(l10n);
  return switch (n.type) {
    NotificationType.vaultReceiptPending => l10n.notificationVaultPendingTitle,
    NotificationType.incomingTransferPending => l10n.notificationIncomingTitle(
      name,
    ),
    NotificationType.transferSent => l10n.notificationTransferSentTitle(
      _amount(l10n, n, locale),
      name,
    ),
    NotificationType.sentTransferApproved => l10n.notificationSentApprovedTitle(
      name,
      _amount(l10n, n, locale),
    ),
    NotificationType.sentTransferRejected => l10n.notificationSentRejectedTitle(
      name,
      _amount(l10n, n, locale),
    ),
    NotificationType.roadExpensePending => l10n.notificationRoadPendingTitle,
    NotificationType.expenseRecorded => l10n.notificationExpenseRecordedTitle,
  };
}

String notificationBody(
  AppLocalizations l10n,
  AppNotification n,
  String locale,
) {
  final amount = _amount(l10n, n, locale);
  return switch (n.type) {
    NotificationType.transferSent => l10n.notificationTransferSentBody(
      n.entityId,
    ),
    NotificationType.sentTransferApproved =>
      l10n.notificationTransferConfirmedBody(n.entityId),
    NotificationType.sentTransferRejected => l10n.notificationRefundedBody(
      amount,
      n.entityId,
    ),
    NotificationType.expenseRecorded => l10n.notificationDeductedBody(
      amount,
      n.entityId,
    ),
    _ => l10n.notificationAmountReference(amount, n.entityId),
  };
}

/// Whether [n]'s displayed title or body contains [query], ignoring case.
bool notificationMatches(
  AppLocalizations l10n,
  AppNotification n,
  String locale,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return notificationTitle(l10n, n, locale).toLowerCase().contains(needle) ||
      notificationBody(l10n, n, locale).toLowerCase().contains(needle);
}

String _amount(AppLocalizations l10n, AppNotification n, String locale) {
  return formatHomeAmount(
    n.amountEgp,
    locale: locale,
    withCurrency: true,
    currency: l10n.egp,
  );
}

/// Clock time today, "Yesterday · time", otherwise the date and time.
String notificationWhen(
  AppLocalizations l10n,
  DateTime at,
  DateTime now,
  String locale,
) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final clock = historyClock(at, locale);
  if (day == today) return clock;
  if (day == today.subtract(const Duration(days: 1))) {
    return '${l10n.yesterday} · $clock';
  }
  return '${historyDayLabel(day, locale)} · $clock';
}

({String asset, Color tint}) notificationMark(NotificationType type) {
  return switch (type) {
    NotificationType.vaultReceiptPending => (
      asset: AppIcons.vault,
      tint: AppColors.warningBackground,
    ),
    NotificationType.incomingTransferPending => (
      asset: AppIcons.person,
      tint: AppColors.successBackground,
    ),
    NotificationType.transferSent => (
      asset: AppIcons.send,
      tint: AppColors.warningBackground,
    ),
    NotificationType.sentTransferApproved => (
      asset: AppIcons.send,
      tint: AppColors.successBackground,
    ),
    NotificationType.sentTransferRejected => (
      asset: AppIcons.send,
      tint: AppColors.dangerBackground,
    ),
    NotificationType.roadExpensePending => (
      asset: AppIcons.invoice,
      tint: AppColors.primary.withValues(alpha: 0.1),
    ),
    NotificationType.expenseRecorded => (
      asset: AppIcons.money,
      tint: AppColors.pinkBackground,
    ),
  };
}
