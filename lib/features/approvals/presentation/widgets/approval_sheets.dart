import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/app_icons.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/localization/localized_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_item.dart';
import '../approval_format.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';

enum ApprovalSheetAction { approve, decline, confirm, reject }

Future<ApprovalSheetAction?> showApprovalSheet(
  BuildContext context, {
  required ApprovalItem item,
  required int balanceEgp,
}) {
  final height = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<ApprovalSheetAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppSurfaces.of(context).sheet,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return switch (item.kind) {
        ApprovalKind.vault => _CashApprovalSheet(
          item: item,
          balanceEgp: balanceEgp,
          title: AppLocalizations.of(context).approveCashReceipt,
          subtitle: AppLocalizations.of(context).vaultSentFunds,
          amountColor: AppColors.warningText,
          party: AppLocalizations.of(context).driversVault,
          confirm: ApprovalSheetAction.approve,
        ),
        ApprovalKind.driver => _CashApprovalSheet(
          item: item,
          balanceEgp: balanceEgp,
          title: AppLocalizations.of(context).approveCashFromDriver,
          subtitle: AppLocalizations.of(context)
              .driverSentCash(item.counterpartyName.of(context)),
          amountColor: AppColors.success,
          party:
              '${item.counterpartyName.of(context)} (${item.counterpartyId})',
          confirm: ApprovalSheetAction.approve,
          decline: ApprovalSheetAction.decline,
        ),
        ApprovalKind.roadExpense => _RoadExpenseSheet(item: item),
      };
    },
  );
}

Future<bool> showRejectExpenseDialog(
  BuildContext context, {
  required String reference,
}) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppSurfaces.of(context).sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final surfaces = AppSurfaces.of(context);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.rejectExpenseTitle,
                style: TextStyle(
                  color: surfaces.title,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.rejectExpenseMessage(reference),
                style: TextStyle(
                  color: surfaces.body,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('approval-reject-cancel'),
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: surfaces.title,
                        side: BorderSide(color: surfaces.border),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('approval-reject-yes'),
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.yesReject),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return accepted ?? false;
}

class _CashApprovalSheet extends StatelessWidget {
  final ApprovalItem item;
  final int balanceEgp;
  final String title;
  final String subtitle;
  final Color amountColor;
  final String party;
  final ApprovalSheetAction confirm;
  final ApprovalSheetAction? decline;

  const _CashApprovalSheet({
    required this.item,
    required this.balanceEgp,
    required this.title,
    required this.subtitle,
    required this.amountColor,
    required this.party,
    required this.confirm,
    this.decline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final after = balanceEgp + item.amountEgp;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppSurfaces.of(context).title,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppSurfaces.of(context).body,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              signedApprovalAmount(
                item.amountEgp,
                locale: locale,
                currency: l10n.egp,
              ),
              style: TextStyle(
                color: amountColor,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(label: l10n.from, value: party),
                  _DetailRow(
                    label: l10n.currentBalance,
                    value: approvalAmount(
                      balanceEgp,
                      locale: locale,
                      currency: l10n.egp,
                    ),
                  ),
                  _DetailRow(
                    label: l10n.balanceAfter,
                    value: approvalAmount(
                      after,
                      locale: locale,
                      currency: l10n.egp,
                    ),
                    valueColor: AppColors.success,
                  ),
                  _DetailRow(
                    label: l10n.date,
                    value: detailWhen(l10n, item, locale),
                  ),
                  _DetailRow(label: l10n.reference, value: item.reference),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key(
                      decline == null ? 'approval-cancel' : 'approval-decline',
                    ),
                    onPressed: () => Navigator.pop(context, decline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.title,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(decline == null ? l10n.cancel : l10n.decline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('approval-approve'),
                    onPressed: () => Navigator.pop(context, confirm),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('${l10n.approve} ✓'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadExpenseSheet extends StatelessWidget {
  final ApprovalItem item;

  const _RoadExpenseSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final perTrip = approvalAmount(
      item.perTripEgp,
      locale: locale,
      currency: l10n.egp,
    );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    AppIcons.invoice,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('approval-close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            Text(
              l10n.roadExpenseApproval,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppSurfaces.of(context).title,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminSubmittedExpense,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.totalAmount,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.hint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              signedApprovalAmount(
                item.amountEgp,
                locale: locale,
                currency: l10n.egp,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    asset: AppIcons.hashtag,
                    label: l10n.reference,
                    value: item.reference,
                  ),
                  _DetailRow(
                    asset: AppIcons.calendar,
                    label: l10n.period,
                    value: approvalPeriod(
                      item.periodStart!,
                      item.periodEnd!,
                      locale,
                    ),
                  ),
                  _DetailRow(
                    asset: AppIcons.receipt,
                    label: l10n.submittedBy,
                    value: item.submittedBy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.tripDetails,
              style: const TextStyle(
                color: AppColors.hint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppSurfaces.of(context).card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppSurfaces.of(context).border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        AppIcons.bus,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.vehicle,
                              style: const TextStyle(
                                color: AppColors.title,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.tripsPerAmount(item.lines.length, perTrip),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        approvalAmount(
                          item.amountEgp,
                          locale: locale,
                          currency: l10n.egp,
                        ),
                        style: const TextStyle(
                          color: AppColors.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final line in item.lines) ...[
                    const Divider(height: 16, color: AppColors.border),
                    _TripLine(line: line),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.grandTotal,
                    style: const TextStyle(
                      color: AppColors.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    approvalAmount(
                      item.amountEgp,
                      locale: locale,
                      currency: l10n.egp,
                    ),
                    style: const TextStyle(
                      color: AppColors.title,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('approval-reject'),
                    onPressed: () =>
                        Navigator.pop(context, ApprovalSheetAction.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n.reject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('approval-confirm'),
                    onPressed: () =>
                        Navigator.pop(context, ApprovalSheetAction.confirm),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('${l10n.confirm} ✓'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripLine extends StatelessWidget {
  final ApprovalTripLine line;

  const _TripLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              AppIcons.hashtag,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                line.code,
                style: const TextStyle(
                  color: AppColors.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              l10n.tripNumber(line.tripNumber),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppColors.hint,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                line.route(locale),
                style: const TextStyle(color: AppColors.title, fontSize: 13),
              ),
            ),
            Text(
              signedApprovalAmount(
                line.amountEgp,
                locale: locale,
                currency: l10n.egp,
              ),
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Image.asset(
              AppIcons.calendar,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 4),
            Text(
              approvalDay(line.date, locale),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String? asset;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    this.asset,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (asset != null) ...[
            Image.asset(
              asset!,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? AppColors.title,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> openApprovalRequest(
  BuildContext context,
  ApprovalItem item,
) async {
  if (_blockApprovalIfOffline(context)) return;

  final bloc = context.read<ApprovalsBloc>();
  final action = await showApprovalSheet(
    context,
    item: item,
    balanceEgp: bloc.state.balanceEgp,
  );
  if (!context.mounted || action == null) return;
  if (action == ApprovalSheetAction.reject) {
    final confirmed = await showRejectExpenseDialog(
      context,
      reference: item.reference,
    );
    if (!confirmed || !context.mounted) return;
  }
  // Re-check after the sheet: connectivity may have changed mid-flow.
  if (_blockApprovalIfOffline(context)) return;
  bloc.add(
    ApprovalActionRequested(
      id: item.id,
      command: commandFor(item.kind, action),
    ),
  );
}

/// Blocks approval actions while offline, unreachable, or probing.
bool _blockApprovalIfOffline(BuildContext context) {
  final connectivity = context.read<ConnectivityBloc>().state;
  if (!connectivity.blocksOnlineWork) return false;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const Key('offline-action-notice'),
        content: Text(l10n.offlineActionRequiresInternet),
      ),
    );
  return true;
}

ApprovalCommand commandFor(ApprovalKind kind, ApprovalSheetAction action) {
  return switch (action) {
    ApprovalSheetAction.approve when kind == ApprovalKind.vault =>
      ApprovalCommand.approveVault,
    ApprovalSheetAction.approve => ApprovalCommand.approveTransfer,
    ApprovalSheetAction.decline => ApprovalCommand.declineTransfer,
    ApprovalSheetAction.confirm => ApprovalCommand.confirmRoad,
    ApprovalSheetAction.reject => ApprovalCommand.rejectRoad,
  };
}
