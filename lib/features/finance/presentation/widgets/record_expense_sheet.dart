import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../data/device_expense_attachment_picker.dart';
import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/expense_attachment.dart';
import '../../domain/entities/settlement_type.dart';
import '../../domain/expense_attachment_picker.dart';
import '../../domain/failures/expense_exception.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/record_expense.dart';
import '../bloc/record_expense_bloc.dart';
import '../bloc/record_expense_event.dart';
import '../bloc/record_expense_state.dart';
import '../settlement_style.dart';
import 'attachment_thumbnail.dart';
import 'settlement_picker_sheet.dart';
import 'trip_picker_sheet.dart';

Future<void> showRecordExpenseSheet(
  BuildContext context, {
  required String driverId,
  ExpenseAttachmentPicker? picker,
}) {
  final expenses = context.read<ExpenseRepository>();
  final homeBloc = context.read<HomeBloc>();
  final height = MediaQuery.sizeOf(context).height;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return RepositoryProvider.value(
        value: expenses,
        child: BlocProvider(
          create: (_) => RecordExpenseBloc(
            driverId: driverId,
            recordExpense: RecordExpense(expenses),
            repository: expenses,
          )..add(const RecordExpenseStarted()),
          child: BlocListener<RecordExpenseBloc, RecordExpenseState>(
            listenWhen: (previous, current) =>
                previous.result == null && current.result != null,
            listener: (_, _) => homeBloc.add(const HomeSummaryRefreshed()),
            child: RecordExpenseSheet(
              picker: picker ?? DeviceExpenseAttachmentPicker(),
            ),
          ),
        ),
      );
    },
  );
}

class RecordExpenseSheet extends StatefulWidget {
  final ExpenseAttachmentPicker picker;

  const RecordExpenseSheet({super.key, required this.picker});

  @override
  State<RecordExpenseSheet> createState() => _RecordExpenseSheetState();
}

class _RecordExpenseSheetState extends State<RecordExpenseSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);

    return BlocListener<RecordExpenseBloc, RecordExpenseState>(
      listenWhen: (previous, current) =>
          previous.amountEgp != current.amountEgp,
      listener: (context, state) {
        final text = state.amountEgp == 0 ? '' : '${state.amountEgp}';
        if (_amountController.text == text) return;
        _amountController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: media.size.height * 0.88,
          child: SafeArea(
            child: BlocBuilder<RecordExpenseBloc, RecordExpenseState>(
              builder: (context, state) {
                return PopScope(
                  canPop: !state.submitting,
                  child: switch (state.stage) {
                    RecordExpenseStage.confirm => _ConfirmExpense(state: state),
                    RecordExpenseStage.recorded => _ExpenseRecorded(
                      state: state,
                    ),
                    RecordExpenseStage.form => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: _ExpenseForm(
                        state: state,
                        l10n: l10n,
                        amountController: _amountController,
                        notesController: _notesController,
                        onPick: (kind) => _pick(context, kind),
                      ),
                    ),
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, _AttachmentSource source) async {
    final bloc = context.read<RecordExpenseBloc>();
    try {
      final attachment = switch (source) {
        _AttachmentSource.camera => await widget.picker.pickCamera(),
        _AttachmentSource.gallery => await widget.picker.pickGallery(),
        _AttachmentSource.file => await widget.picker.pickFile(),
      };
      if (attachment == null || !context.mounted) return;
      bloc.add(RecordExpenseAttachmentAdded(attachment));
    } on ExpenseAttachmentFailedException {
      if (!context.mounted) return;
      bloc.add(const RecordExpenseAttachmentFailed());
    } catch (_) {
      if (!context.mounted) return;
      bloc.add(const RecordExpenseAttachmentFailed());
    }
  }
}

enum _AttachmentSource { camera, gallery, file }

class _ExpenseForm extends StatelessWidget {
  final RecordExpenseState state;
  final AppLocalizations l10n;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final ValueChanged<_AttachmentSource> onPick;

  const _ExpenseForm({
    required this.state,
    required this.l10n,
    required this.amountController,
    required this.notesController,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final trip = state.selectedTrip;
    final settlement = state.settlementType;
    final balanceAfter = state.balanceAfterEgp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Handle(),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.dangerBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recordExpense,
                    style: const TextStyle(
                      color: AppColors.title,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.recordExpenseSubtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('expense-close'),
              onPressed: state.submitting ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _BalancePill(
            label: l10n.currentBalance,
            amount: _money(state.balanceEgp, locale, l10n.egp),
          ),
          const SizedBox(height: 16),
          _FieldLabel(l10n.selectTripTitle),
          const SizedBox(height: 8),
          if (trip == null)
            _SelectorButton(
              key: const Key('expense-trip'),
              hint: l10n.selectTripHint,
              onTap: () => showTripPicker(context),
            )
          else
            _SelectedTrip(trip: trip, onTap: () => showTripPicker(context)),
          const SizedBox(height: 14),
          _FieldLabel(l10n.settlementType),
          const SizedBox(height: 8),
          if (settlement == null)
            _SelectorButton(
              key: const Key('expense-settlement'),
              hint: l10n.selectSettlementHint,
              onTap: () => showSettlementPicker(context),
            )
          else
            _SelectedSettlement(
              type: settlement,
              l10n: l10n,
              onTap: () => showSettlementPicker(context),
            ),
          const SizedBox(height: 14),
          _FieldLabel(l10n.amountEgpLabel),
          const SizedBox(height: 8),
          TextField(
            key: const Key('expense-amount'),
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(hint: '0').copyWith(
              suffixText: l10n.egp,
              suffixStyle: const TextStyle(color: AppColors.hint),
            ),
            onChanged: (value) {
              context.read<RecordExpenseBloc>().add(
                RecordExpenseAmountChanged(int.tryParse(value) ?? 0),
              );
            },
          ),
          if (balanceAfter != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.balanceAfterPreview(_money(balanceAfter, locale, l10n.egp)),
              style: TextStyle(
                color: balanceAfter < 0 ? AppColors.error : AppColors.muted,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _FieldLabel(l10n.notesOptional),
          const SizedBox(height: 8),
          TextField(
            key: const Key('expense-notes'),
            controller: notesController,
            minLines: 2,
            maxLines: 3,
            onChanged: (value) => context.read<RecordExpenseBloc>().add(
              RecordExpenseNotesChanged(value),
            ),
            decoration: _inputDecoration(hint: l10n.notesHint),
          ),
          const SizedBox(height: 14),
          _FieldLabel(l10n.attachmentsOptional),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DashedButton(
                  buttonKey: const Key('expense-camera'),
                  icon: Icons.photo_camera_outlined,
                  label: l10n.camera,
                  onPressed: () => onPick(_AttachmentSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashedButton(
                  buttonKey: const Key('expense-gallery'),
                  icon: Icons.image_outlined,
                  label: l10n.gallery,
                  onPressed: () => onPick(_AttachmentSource.gallery),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashedButton(
                  buttonKey: const Key('expense-file'),
                  icon: Icons.attach_file,
                  label: l10n.file,
                  onPressed: () => onPick(_AttachmentSource.file),
                ),
              ),
            ],
          ),
          if (state.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final attachment in state.attachments)
                  _AttachmentTile(attachment: attachment),
              ],
            ),
          ],
          if (_message(state, l10n) case final message?) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: message),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('expense-submit'),
            onPressed: state.submitting
                ? null
                : () => context.read<RecordExpenseBloc>().add(
                    const RecordExpenseReviewRequested(),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              disabledBackgroundColor: AppColors.error.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.recordExpense),
          ),
        ],
      ],
    );
  }

  String? _message(RecordExpenseState state, AppLocalizations l10n) {
    return switch (state.error) {
      RecordExpenseError.selectTrip => l10n.selectTripError,
      RecordExpenseError.selectSettlement => l10n.selectSettlementError,
      RecordExpenseError.invalidAmount => l10n.invalidAmountError,
      RecordExpenseError.insufficientBalance => l10n.insufficientBalanceError,
      RecordExpenseError.ineligibleTrip => l10n.ineligibleTripError,
      RecordExpenseError.attachmentFailed => l10n.attachmentFailed,
      RecordExpenseError.unexpected => l10n.expenseFailed,
      null => null,
    };
  }
}

class _ConfirmExpense extends StatelessWidget {
  final RecordExpenseState state;

  const _ConfirmExpense({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final trip = state.selectedTrip;
    final settlement = state.settlementType;
    final after = state.balanceEgp - state.amountEgp;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.confirmExpense,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.confirmExpenseSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.dangerBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  l10n.deduction,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '−${_money(state.amountEgp, locale, l10n.egp)}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            children: [
              if (settlement != null)
                _SummaryRow(
                  label: l10n.settlementType,
                  value: settlementTitle(l10n, settlement),
                ),
              if (trip != null)
                _SummaryRow(
                  label: l10n.trip,
                  value: trip.code,
                  detail: tripRoute(trip),
                ),
              _SummaryRow(
                label: l10n.currentBalance,
                value: _money(state.balanceEgp, locale, l10n.egp),
              ),
              _SummaryRow(
                label: l10n.balanceAfter,
                value: _money(after, locale, l10n.egp),
                valueColor: AppColors.success,
              ),
              if (state.attachments.isNotEmpty) ...[
                _SummaryRow(
                  label: l10n.attachments,
                  value: l10n.attachmentCount(state.attachments.length),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final attachment in state.attachments)
                          _ConfirmAttachment(attachment: attachment),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('expense-back'),
                  onPressed: state.submitting
                      ? null
                      : () => context.read<RecordExpenseBloc>().add(
                          const RecordExpenseReviewCancelled(),
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.title,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.back),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('expense-confirm'),
                  onPressed: state.submitting
                      ? null
                      : () => context.read<RecordExpenseBloc>().add(
                          const RecordExpenseSubmitted(),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.confirmDeduction,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseRecorded extends StatelessWidget {
  final RecordExpenseState state;

  const _ExpenseRecorded({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final result = state.result!;
    final expense = result.expense;
    final settlement = settlementTitle(l10n, expense.settlementType);
    final trip = state.selectedTrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.dangerBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.error,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.expenseRecorded,
            style: const TextStyle(
              color: AppColors.title,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.expenseDeducted(settlement),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.dangerBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  l10n.amountDeducted,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '−${_money(expense.amountEgp, locale, l10n.egp)}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            children: [
              _SummaryRow(
                label: l10n.newBalance,
                value: _money(result.balanceEgp, locale, l10n.egp),
                valueColor: AppColors.primary,
              ),
              _SummaryRow(
                label: l10n.tripCode,
                value: trip?.code ?? expense.tripId,
              ),
              _SummaryRow(label: l10n.reference, value: expense.id),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('expense-done'),
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.done),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTrip extends StatelessWidget {
  final AssignedTrip trip;
  final VoidCallback onTap;

  const _SelectedTrip({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('expense-trip'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.code,
                      style: const TextStyle(
                        color: AppColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${tripRoute(trip)} · ${formatTripDate(trip.date, locale)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedSettlement extends StatelessWidget {
  final SettlementType type;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _SelectedSettlement({
    required this.type,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = settlementVisual(type);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('expense-settlement'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: visual.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  settlementName(l10n, type),
                  style: const TextStyle(
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _SelectorButton({super.key, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(color: AppColors.hint, fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmAttachment extends StatelessWidget {
  final ExpenseAttachment attachment;

  const _ConfirmAttachment({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('expense-confirm-attachment-${attachment.id}'),
      width: 88,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: AppColors.neutralBackground,
              child: SizedBox(
                width: 56,
                height: 56,
                child: attachment.kind == ExpenseAttachmentKind.file
                    ? const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.muted,
                        size: 22,
                      )
                    : attachmentThumbnail(attachment),
              ),
            ),
          ),
          if (attachment.kind == ExpenseAttachmentKind.file) ...[
            const SizedBox(height: 4),
            Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ExpenseAttachment attachment;

  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: AppColors.neutralBackground,
                child: attachment.kind == ExpenseAttachmentKind.file
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.insert_drive_file_outlined,
                              color: AppColors.muted,
                              size: 20,
                            ),
                            Text(
                              attachment.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      )
                    : attachmentThumbnail(attachment),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton(
              key: Key('expense-remove-${attachment.id}'),
              tooltip: l10n.removeAttachment,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              onPressed: () => context.read<RecordExpenseBloc>().add(
                RecordExpenseAttachmentRemoved(attachment.id),
              ),
              icon: const Icon(Icons.close, size: 14, color: AppColors.title),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final String amount;

  const _BalancePill({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Widget> children;

  const _SummaryCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.detail,
    this.valueColor = AppColors.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('expense-error'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _DashedButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: CustomPaint(
        painter: const _DashedRectPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: AppColors.muted, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.hint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: _outline(AppColors.border),
    focusedBorder: _outline(AppColors.primary),
    border: _outline(AppColors.border),
  );
}

OutlineInputBorder _outline(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );
}

String _money(int amount, String locale, String currency) {
  return formatHomeAmount(
    amount,
    locale: locale,
    withCurrency: true,
    currency: currency,
  );
}
