import 'package:flutter/material.dart';

import '../../../../core/assets/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/activity_row.dart';
import '../../../../core/widgets/type_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/history_entry.dart';
import '../history_format.dart';

/// A ledger row, shared by History and Home's recent transactions. Keys are
/// `'$keyPrefix-<id>'` for the row and `'$keyPrefix-details-<id>'` and
/// `'$keyPrefix-values-<id>'` for its two columns.
class HistoryEntryTile extends StatelessWidget {
  final HistoryEntry entry;
  final String when;
  final VoidCallback? onTap;
  final String keyPrefix;
  final bool showDivider;
  final bool highlighted;

  const HistoryEntryTile({
    super.key,
    required this.entry,
    required this.when,
    this.onTap,
    this.keyPrefix = 'history-entry',
    this.showDivider = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final id = entry.id;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ActivityRow(
        avatar: historyAvatar(entry),
        title: historyTitle(l10n, entry),
        subtitle: historySubtitle(l10n, entry),
        subtitleColor: historyStatusColor(entry.status),
        amount: signedHistoryAmount(entry, locale: locale, currency: l10n.egp),
        amountColor: entry.credit ? AppColors.creditText : AppColors.title,
        when: when,
        detailsKey: Key('$keyPrefix-details-$id'),
        valuesKey: Key('$keyPrefix-values-$id'),
      ),
    );
    final decorated = DecoratedBox(
      key: highlighted ? Key('history-highlight-$id') : null,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: row,
    );
    final tileKey = Key('$keyPrefix-$id');
    final tile = onTap == null
        ? KeyedSubtree(key: tileKey, child: decorated)
        : InkWell(
            key: tileKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: decorated,
          );
    if (!showDivider) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [tile, const HistoryEntryDivider()],
    );
  }
}

class HistoryEntryDivider extends StatelessWidget {
  const HistoryEntryDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.title.withValues(alpha: 0.08),
    );
  }
}

Color historyStatusColor(HistoryDisplayStatus status) {
  return switch (status) {
    HistoryDisplayStatus.pendingConfirm ||
    HistoryDisplayStatus.awaitingApproval => AppColors.pendingText,
    HistoryDisplayStatus.rejected => AppColors.rejectedText,
    _ => AppColors.creditText,
  };
}

TypeAvatar historyAvatar(HistoryEntry entry) {
  return switch (entry.kind) {
    HistoryKind.expense => TypeAvatar.asset(
      AppIcons.money,
      tint: AppColors.successBackground,
    ),
    HistoryKind.vault => TypeAvatar.asset(
      AppIcons.vault,
      tint: AppColors.warningBackground,
    ),
    HistoryKind.outgoing => TypeAvatar.asset(
      AppIcons.send,
      tint: AppColors.pinkBackground,
    ),
    HistoryKind.incoming when entry.isPending => TypeAvatar.asset(
      AppIcons.pending,
      tint: AppColors.warningBackground,
    ),
    HistoryKind.incoming => TypeAvatar.asset(
      AppIcons.person,
      tint: AppColors.successBackground,
    ),
    HistoryKind.roadExpense => const TypeAvatar(
      tint: AppColors.primarySurface,
      child: Icon(
        Icons.description_outlined,
        size: 24,
        color: AppColors.primary,
      ),
    ),
  };
}
