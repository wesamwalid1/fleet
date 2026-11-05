import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/localization/localized_string.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/approval_item.dart';
import '../approval_format.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import 'approval_inbox_row.dart';

enum ApprovalSheetAction { approve, decline, confirm, reject }

Future<void> showApprovalSheet(
  BuildContext context, {
  required ApprovalItem item,
  required int balanceEgp,
  bool readOnly = false,
}) {
  final approvals = context.read<ApprovalsBloc>();
  final connectivity = context.read<ConnectivityBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).surface,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final media = MediaQuery.of(context);
      final maxHeight = media.size.height * 0.92;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: approvals),
            BlocProvider.value(value: connectivity),
          ],
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: BlocConsumer<ApprovalsBloc, ApprovalsState>(
              listenWhen: (previous, current) =>
                  previous.busy && !current.busy && !current.failed,
              listener: (context, state) {
                if (!readOnly && item.isPending) {
                  Navigator.pop(context);
                }
              },
              buildWhen: (previous, current) =>
                  previous.busy != current.busy ||
                  previous.balanceEgp != current.balanceEgp,
              builder: (context, state) {
                return _ApprovalReviewSheet(
                  item: item,
                  balanceEgp: balanceEgp,
                  readOnly: readOnly,
                  busy: state.busy,
                );
              },
            ),
          ),
        ),
      );
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
    backgroundColor: AppPalette.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final palette = AppPalette.of(context);
      final buttonText = Theme.of(context).textTheme.labelLarge
          ?.merge(AppTextStyles.buttonLarge);
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
                style: AppTextStyles.title.copyWith(color: palette.title),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.rejectExpenseMessage(reference),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.body,
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
                        foregroundColor: palette.title,
                        side: BorderSide(color: palette.fieldBorder),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: buttonText,
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
                        backgroundColor: palette.error,
                        foregroundColor: palette.onAction,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: buttonText,
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

class _ApprovalReviewSheet extends StatelessWidget {
  final ApprovalItem item;
  final int balanceEgp;
  final bool readOnly;
  final bool busy;

  const _ApprovalReviewSheet({
    required this.item,
    required this.balanceEgp,
    required this.readOnly,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return switch (item.kind) {
      ApprovalKind.vault || ApprovalKind.driver => _CashReviewBody(
        item: item,
        balanceEgp: balanceEgp,
        readOnly: readOnly,
        busy: busy,
      ),
      ApprovalKind.roadExpense => _RoadReviewBody(
        item: item,
        readOnly: readOnly,
        busy: busy,
      ),
    };
  }
}

class _CashReviewBody extends StatelessWidget {
  final ApprovalItem item;
  final int balanceEgp;
  final bool readOnly;
  final bool busy;

  const _CashReviewBody({
    required this.item,
    required this.balanceEgp,
    required this.readOnly,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final vault = item.kind == ApprovalKind.vault;
    final title = vault ? l10n.approveCashReceipt : l10n.approveCashFromDriver;
    final subtitle = vault
        ? l10n.vaultSentFunds
        : l10n.driverSentCash(item.counterpartyName.of(context));
    final party = vault
        ? l10n.driversVault
        : '${item.counterpartyName.of(context)} (${item.counterpartyId})';
    final after = balanceEgp + item.amountEgp;
    final mark = approvalMarkState(item.outcome);

    return _SheetScaffold(
      body: [
        _SheetHeader(
          title: title,
          subtitle: subtitle,
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
        Text(
          key: const Key('approval-detail-amount'),
          approvalAmount(item.amountEgp, locale: locale, currency: l10n.egp),
          style: TextStyle(
            color: palette.title,
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTextStyles.tabular,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ApprovalKindMark(mark, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.isPending
                    ? l10n.awaitingYourApproval
                    : item.outcome == ApprovalOutcome.rejected
                    ? l10n.rejected
                    : l10n.approved,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: mark == ApprovalMarkState.rejected
                      ? palette.error
                      : palette.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailRow(label: l10n.from, value: party),
        _DetailRow(label: l10n.reference, value: item.reference),
        _DetailRow(label: l10n.date, value: detailWhen(l10n, item, locale)),
        _SectionLabel(l10n.balanceSnapshotTitle),
        if (item.isPending && !readOnly) ...[
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
            value: approvalAmount(after, locale: locale, currency: l10n.egp),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.approvalCreditsWhenApproved,
              style: AppTextStyles.helper.copyWith(color: palette.muted),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              key: const Key('approval-detail-balance-outcome'),
              item.outcome == ApprovalOutcome.rejected
                  ? l10n.approvalNotCreditedToBalance
                  : l10n.approvalCreditedToBalance,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.title,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
      actions: !readOnly && item.isPending
          ? _CashActions(
              allowDecline: !vault,
              busy: busy,
              onDecline: () =>
                  _dispatch(context, item, ApprovalSheetAction.decline),
              onCancel: () => Navigator.pop(context),
              onApprove: () =>
                  _dispatch(context, item, ApprovalSheetAction.approve),
            )
          : _CloseOnly(busy: busy),
    );
  }
}

class _RoadReviewBody extends StatelessWidget {
  final ApprovalItem item;
  final bool readOnly;
  final bool busy;

  const _RoadReviewBody({
    required this.item,
    required this.readOnly,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final mark = approvalMarkState(item.outcome);
    final perTrip = approvalAmount(
      item.perTripEgp,
      locale: locale,
      currency: l10n.egp,
    );

    return _SheetScaffold(
      body: [
        _SheetHeader(
          title: l10n.roadExpenseApproval,
          subtitle: l10n.adminSubmittedExpense,
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
        Text(
          key: const Key('approval-detail-amount'),
          approvalAmount(item.amountEgp, locale: locale, currency: l10n.egp),
          style: TextStyle(
            color: palette.title,
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTextStyles.tabular,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ApprovalKindMark(mark, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.isPending
                    ? l10n.awaitingYourApproval
                    : item.outcome == ApprovalOutcome.rejected
                    ? l10n.rejected
                    : l10n.approved,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: mark == ApprovalMarkState.rejected
                      ? palette.error
                      : palette.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailRow(label: l10n.reference, value: item.reference),
        if (item.periodStart != null && item.periodEnd != null)
          _DetailRow(
            label: l10n.period,
            value: approvalPeriod(item.periodStart!, item.periodEnd!, locale),
          ),
        if (item.submittedBy.isNotEmpty)
          _DetailRow(label: l10n.submittedBy, value: item.submittedBy),
        if (item.vehicle.isNotEmpty)
          _DetailRow(label: l10n.vehicle, value: item.vehicle),
        if (item.lines.isNotEmpty) ...[
          _SectionLabel(l10n.tripDetails),
          Text(
            l10n.tripsPerAmount(item.lines.length, perTrip),
            style: AppTextStyles.helper.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 8),
          for (final (index, line) in item.lines.indexed) ...[
            if (index > 0) Divider(height: 1, color: palette.hairline),
            _TripLine(line: line),
          ],
        ],
        _SectionLabel(l10n.balanceSnapshotTitle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: const Key('approval-detail-balance-outcome'),
                l10n.approvalNoBalanceChange,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.title,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.approvalRoadBalanceNote,
                style: AppTextStyles.helper.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      actions: !readOnly && item.isPending
          ? _RoadActions(
              busy: busy,
              onReject: () => _rejectRoad(context, item),
              onConfirm: () =>
                  _dispatch(context, item, ApprovalSheetAction.confirm),
            )
          : _CloseOnly(busy: busy),
    );
  }
}

/// Content-sized sheet shell: short sheets stay compact; tall content scrolls
/// under a sticky action row, capped at the modal max height.
class _SheetScaffold extends StatelessWidget {
  final List<Widget> body;
  final Widget actions;

  const _SheetScaffold({required this.body, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: body,
              ),
            ),
            actions,
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTextStyles.title.copyWith(color: palette.title),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('approval-close'),
          onPressed: onClose,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.close_rounded, color: palette.muted),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppPalette.of(context).muted,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.title,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
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
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.code,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                approvalAmount(
                  line.amountEgp,
                  locale: locale,
                  currency: l10n.egp,
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.title,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.tripNumber(line.tripNumber),
            style: AppTextStyles.helper.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 2),
          Text(
            line.route(locale),
            style: AppTextStyles.bodyMedium.copyWith(color: palette.body),
          ),
          const SizedBox(height: 2),
          Text(
            approvalDay(line.date, locale),
            style: AppTextStyles.helper.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _CashActions extends StatelessWidget {
  final bool allowDecline;
  final bool busy;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onApprove;

  const _CashActions({
    required this.allowDecline,
    required this.busy,
    required this.onDecline,
    required this.onCancel,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final buttonText = Theme.of(context).textTheme.labelLarge
        ?.merge(AppTextStyles.buttonLarge);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: Key(allowDecline ? 'approval-decline' : 'approval-cancel'),
            onPressed: busy ? null : (allowDecline ? onDecline : onCancel),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.title,
              side: BorderSide(color: palette.fieldBorder),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: buttonText,
            ),
            child: Text(allowDecline ? l10n.decline : l10n.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const Key('approval-approve'),
            onPressed: busy ? null : onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: palette.action,
              foregroundColor: palette.onAction,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: buttonText,
            ),
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: palette.onAction,
                    ),
                  )
                : Text(l10n.approve),
          ),
        ),
      ],
    );
  }
}

class _RoadActions extends StatelessWidget {
  final bool busy;
  final VoidCallback onReject;
  final VoidCallback onConfirm;

  const _RoadActions({
    required this.busy,
    required this.onReject,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final buttonText = Theme.of(context).textTheme.labelLarge
        ?.merge(AppTextStyles.buttonLarge);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('approval-reject'),
            onPressed: busy ? null : onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.error,
              side: BorderSide(color: palette.error),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: buttonText,
            ),
            child: Text(l10n.reject),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const Key('approval-confirm'),
            onPressed: busy ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: palette.action,
              foregroundColor: palette.onAction,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: buttonText,
            ),
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: palette.onAction,
                    ),
                  )
                : Text(l10n.confirm),
          ),
        ),
      ],
    );
  }
}

class _CloseOnly extends StatelessWidget {
  final bool busy;

  const _CloseOnly({required this.busy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return OutlinedButton(
      key: const Key('approval-transaction-close'),
      onPressed: busy ? null : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.title,
        side: BorderSide(color: palette.fieldBorder),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(l10n.close),
    );
  }
}

/// Opens an actionable review for a pending item, or a read-only detail for a
/// finalized one. Read-only mode never dispatches [ApprovalActionRequested].
Future<void> openApprovalRequest(
  BuildContext context,
  ApprovalItem item, {
  bool readOnly = false,
}) async {
  final viewOnly = readOnly || !item.isPending;
  if (!viewOnly && _blockApprovalIfOffline(context)) return;

  final bloc = context.read<ApprovalsBloc>();
  await showApprovalSheet(
    context,
    item: item,
    balanceEgp: bloc.state.balanceEgp,
    readOnly: viewOnly,
  );
}

Future<void> _rejectRoad(BuildContext context, ApprovalItem item) async {
  if (_blockApprovalIfOffline(context)) return;
  final confirmed = await showRejectExpenseDialog(
    context,
    reference: item.reference,
  );
  if (!confirmed || !context.mounted) return;
  _dispatch(context, item, ApprovalSheetAction.reject);
}

void _dispatch(
  BuildContext context,
  ApprovalItem item,
  ApprovalSheetAction action,
) {
  if (_blockApprovalIfOffline(context)) return;
  context.read<ApprovalsBloc>().add(
    ApprovalActionRequested(
      id: item.id,
      command: commandFor(item.kind, action),
    ),
  );
}

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
