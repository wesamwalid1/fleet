import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/presentation/settlement_style.dart';
import '../../domain/entities/history_entry.dart';
import '../history_format.dart';

class HistoryEntryTile extends StatelessWidget {
  final HistoryEntry entry;
  final String when;
  final VoidCallback? onTap;
  final Key? tileKey;

  const HistoryEntryTile({
    super.key,
    required this.entry,
    required this.when,
    this.onTap,
    this.tileKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final style = _tileStyle(entry);
    final statusColor = switch (entry.status) {
      HistoryDisplayStatus.pendingConfirm => AppColors.warningText,
      HistoryDisplayStatus.awaitingApproval => AppColors.muted,
      HistoryDisplayStatus.rejected => AppColors.error,
      _ => AppColors.success,
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.background,
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, color: style.foreground, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  historyTitle(l10n, entry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  historySubtitle(l10n, entry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  signedHistoryAmount(
                    entry,
                    locale: locale,
                    currency: l10n.egp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: entry.credit ? AppColors.success : AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return KeyedSubtree(key: tileKey, child: row);
    return InkWell(key: tileKey, onTap: onTap, child: row);
  }
}

class _TileStyle {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _TileStyle(this.icon, this.foreground, this.background);
}

_TileStyle _tileStyle(HistoryEntry entry) {
  if (entry.kind == HistoryKind.expense) {
    final visual = settlementVisual(entry.settlementType!);
    return _TileStyle(visual.icon, visual.color, visual.background);
  }
  if (entry.kind == HistoryKind.vault) {
    return const _TileStyle(
      Icons.account_balance_outlined,
      AppColors.success,
      AppColors.successBackground,
    );
  }
  if (entry.kind == HistoryKind.outgoing) {
    return const _TileStyle(
      Icons.person_outline,
      AppColors.pink,
      AppColors.pinkBackground,
    );
  }
  if (entry.isPending) {
    return const _TileStyle(
      Icons.hourglass_empty,
      AppColors.muted,
      AppColors.neutralBackground,
    );
  }
  return const _TileStyle(
    Icons.person_outline,
    AppColors.success,
    AppColors.successBackground,
  );
}
