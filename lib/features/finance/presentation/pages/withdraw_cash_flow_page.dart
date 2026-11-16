import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/haptics/haptics_helper.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/fade_through_route.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/repositories/cash_request_repository.dart';
import '../../domain/usecases/withdraw_cash.dart';
import '../bloc/withdraw_cash_bloc.dart';
import '../bloc/withdraw_cash_event.dart';
import '../bloc/withdraw_cash_state.dart';
import '../widgets/cash_request_success.dart';

const _withdrawQuickAmounts = [500, 1000, 1500, 2000];

enum WithdrawCashFlowStep { amount, review, success }

Future<void> openWithdrawCashFlow(
  BuildContext context, {
  required String driverId,
  void Function(String requestId)? onViewTransaction,
}) {
  final requests = context.read<CashRequestRepository>();
  final homeBloc = context.read<HomeBloc>();
  final connectivity = context.read<ConnectivityBloc>();

  return Navigator.of(context).push<void>(
    FadeThroughRoute<void>(
      settings: const RouteSettings(name: AppRoute.withdrawCash),
      ground: (context) => AppPalette.of(context).ground,
      builder: (_) {
        return BlocProvider.value(
          value: connectivity,
          child: BlocProvider.value(
            value: homeBloc,
            child: RepositoryProvider.value(
              value: requests,
              child: BlocProvider(
                create: (_) => WithdrawCashBloc(
                  driverId: driverId,
                  withdrawCash: WithdrawCash(requests),
                  repository: requests,
                )..add(const WithdrawCashStarted()),
                child: WithdrawCashFlowPage(
                  onViewTransaction: onViewTransaction,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class WithdrawCashFlowPage extends StatefulWidget {
  final void Function(String requestId)? onViewTransaction;

  const WithdrawCashFlowPage({super.key, this.onViewTransaction});

  @override
  State<WithdrawCashFlowPage> createState() => _WithdrawCashFlowPageState();
}

class _WithdrawCashFlowPageState extends State<WithdrawCashFlowPage> {
  WithdrawCashFlowStep _step = WithdrawCashFlowStep.amount;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _amountOutOfRange = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _goTo(WithdrawCashFlowStep step) => setState(() => _step = step);

  void _onBack(WithdrawCashState state) {
    if (state.submitting) return;
    switch (_step) {
      case WithdrawCashFlowStep.amount:
        Navigator.of(context).pop();
      case WithdrawCashFlowStep.review:
        _goTo(WithdrawCashFlowStep.amount);
      case WithdrawCashFlowStep.success:
        Navigator.of(context).pop();
    }
  }

  void _onAmountChanged(String value) {
    final parsed = int.tryParse(value);
    final outOfRange = value.isNotEmpty && parsed == null;
    if (outOfRange != _amountOutOfRange) {
      setState(() => _amountOutOfRange = outOfRange);
    }
    context.read<WithdrawCashBloc>().add(
      WithdrawCashAmountChanged(parsed ?? 0),
    );
  }

  void _syncAmountField(WithdrawCashState state) {
    if (_amountOutOfRange) return;
    final text = state.amountEgp == 0 ? '' : '${state.amountEgp}';
    if (_amountController.text == text) return;
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncNoteField(WithdrawCashState state) {
    if (_noteController.text == state.note) return;
    _noteController.value = TextEditingValue(
      text: state.note,
      selection: TextSelection.collapsed(offset: state.note.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<WithdrawCashBloc, WithdrawCashState>(
          listenWhen: (previous, current) =>
              previous.result == null && current.result != null,
          listener: (context, state) {
            context.read<HomeBloc>().add(const HomeSummaryRefreshed());
            _goTo(WithdrawCashFlowStep.success);
          },
        ),
        BlocListener<WithdrawCashBloc, WithdrawCashState>(
          listenWhen: (previous, current) =>
              previous.amountEgp != current.amountEgp,
          listener: (context, state) => _syncAmountField(state),
        ),
        BlocListener<WithdrawCashBloc, WithdrawCashState>(
          listenWhen: (previous, current) => previous.note != current.note,
          listener: (context, state) => _syncNoteField(state),
        ),
      ],
      child: BlocBuilder<WithdrawCashBloc, WithdrawCashState>(
        builder: (context, state) {
          if (_step == WithdrawCashFlowStep.success) {
            final result = state.result;
            if (result == null) {
              return Scaffold(
                backgroundColor: palette.ground,
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            return PopScope(
              canPop: true,
              child: CashRequestSubmittedPage(
                result: result,
                onViewTransaction: widget.onViewTransaction,
                onGoHome: () => Navigator.of(context).pop(),
              ),
            );
          }

          final canLeave =
              !state.submitting && _step == WithdrawCashFlowStep.amount;
          return PopScope(
            canPop: canLeave,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || state.submitting) return;
              _onBack(state);
            },
            child: Scaffold(
              key: const Key('withdraw-flow'),
              backgroundColor: palette.ground,
              appBar: AppBar(
                backgroundColor: palette.ground,
                surfaceTintColor: Colors.transparent,
                foregroundColor: palette.title,
                leading: IconButton(
                  key: const Key('withdraw-back'),
                  tooltip: l10n.back,
                  onPressed: state.submitting ? null : () => _onBack(state),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(
                  _step == WithdrawCashFlowStep.amount
                      ? l10n.withdrawStepAmount
                      : l10n.withdrawStepReview,
                  style: AppTextStyles.appBarTitle.copyWith(
                    color: palette.title,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _StepIndicator(
                      currentIndex: _step == WithdrawCashFlowStep.amount
                          ? 0
                          : 1,
                      total: 2,
                      label: l10n.withdrawStepProgress(
                        _step == WithdrawCashFlowStep.amount ? 1 : 2,
                        2,
                      ),
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      WithdrawCashFlowStep.amount => _AmountStep(
                        state: state,
                        amountController: _amountController,
                        noteController: _noteController,
                        amountOutOfRange: _amountOutOfRange,
                        onAmountChanged: _onAmountChanged,
                        onContinue: () => _goTo(WithdrawCashFlowStep.review),
                      ),
                      WithdrawCashFlowStep.review => _ReviewStep(
                        state: state,
                        onEdit: () => _goTo(WithdrawCashFlowStep.amount),
                      ),
                      WithdrawCashFlowStep.success => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final String label;

  const _StepIndicator({
    required this.currentIndex,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final current = currentIndex.clamp(0, total - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i <= current ? palette.action : palette.hairline,
                  ),
                ),
              _StepDot(index: i, current: current),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          key: const Key('withdraw-step-label'),
          label,
          style: AppTextStyles.helper.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;

  const _StepDot({required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final completed = index < current;
    final active = index == current;
    final color = completed || active ? palette.action : palette.hairline;
    return Container(
      key: Key('withdraw-step-dot-$index'),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed || active ? color : palette.surface,
        border: Border.all(color: color, width: 2),
      ),
      child: completed
          ? Icon(Icons.check_rounded, size: 14, color: palette.onAction)
          : Text(
              '${index + 1}',
              style: AppTextStyles.helper.copyWith(
                color: active ? palette.onAction : palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  final WithdrawCashState state;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final bool amountOutOfRange;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onContinue;

  const _AmountStep({
    required this.state,
    required this.amountController,
    required this.noteController,
    required this.amountOutOfRange,
    required this.onAmountChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final unavailable = state.summaryUnavailable;
    final exceeds =
        amountOutOfRange || state.amountEgp > state.availableBalanceEgp;
    final balanceAfter = state.availableBalanceEgp - state.amountEgp;
    final canContinue = state.canSubmit && !amountOutOfRange;

    return Column(
      children: [
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.withdrawSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.hairline),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: _balanceRow(
                            context,
                            l10n.withdrawAvailableBalance,
                            unavailable
                                ? '—'
                                : _money(
                                    state.availableBalanceEgp,
                                    locale,
                                    l10n.egp,
                                  ),
                            valueKey: const Key('withdraw-available-balance'),
                            emphasize: true,
                          ),
                        ),
                      ),
                      if (unavailable) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.withdrawSummaryLoadError,
                          key: const Key('withdraw-summary-error'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.helper.copyWith(
                            color: palette.error,
                          ),
                        ),
                        Center(
                          child: TextButton(
                            key: const Key('withdraw-retry'),
                            onPressed: () => context
                                .read<WithdrawCashBloc>()
                                .add(const WithdrawCashStarted()),
                            child: Text(l10n.tryAgain),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        l10n.withdrawAmountLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        key: const Key('withdraw-amount'),
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTextStyles.display.copyWith(
                          color: palette.action,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: AppTextStyles.display.copyWith(
                            color: palette.action.withValues(alpha: 0.35),
                          ),
                          filled: true,
                          fillColor: palette.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          enabledBorder: _amountBorder(palette),
                          focusedBorder: _amountBorder(palette, focused: true),
                        ),
                        onChanged: onAmountChanged,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (
                            var i = 0;
                            i < _withdrawQuickAmounts.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _AmountChip(
                                amount: _withdrawQuickAmounts[i],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.hairline),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: _balanceRow(
                            context,
                            l10n.withdrawBalanceAfter,
                            unavailable || exceeds
                                ? '—'
                                : _money(balanceAfter, locale, l10n.egp),
                            valueKey: const Key('withdraw-balance-after'),
                            valueColor: unavailable || exceeds
                                ? palette.muted
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const Key('withdraw-note'),
                        controller: noteController,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.title,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.notesOptional,
                          hintText: l10n.notesHint,
                          filled: true,
                          fillColor: palette.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: palette.fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: palette.focus,
                              width: 1.6,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<WithdrawCashBloc>().add(
                            WithdrawCashNoteChanged(value),
                          );
                        },
                      ),
                      if (_message(state, l10n, amountOutOfRange)
                          case final message?) ...[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.helper.copyWith(
                            color: palette.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        _BottomBar(
          child: FilledButton(
            key: const Key('withdraw-continue'),
            onPressed: canContinue ? onContinue : null,
            style: _primaryStyle(palette),
            child: Text(l10n.withdrawContinue),
          ),
        ),
      ],
    );
  }

  Widget _balanceRow(
    BuildContext context,
    String label,
    String value, {
    Key? valueKey,
    Color? valueColor,
    bool emphasize = false,
  }) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: emphasize ? palette.title : palette.muted,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          key: valueKey,
          style: AppTextStyles.bodyLarge.copyWith(
            color: valueColor ?? (emphasize ? palette.action : palette.title),
            fontWeight: FontWeight.w700,
            fontFeatures: AppTextStyles.tabular,
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;

  const _AmountChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final selected = context.select<WithdrawCashBloc, bool>(
      (bloc) => bloc.state.amountEgp == amount,
    );
    return OutlinedButton(
      key: Key('withdraw-chip-$amount'),
      onPressed: () => context.read<WithdrawCashBloc>().add(
        WithdrawCashAmountChanged(amount),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? palette.action : palette.surface,
        foregroundColor: selected ? palette.onAction : palette.title,
        side: BorderSide(
          color: selected ? palette.action : palette.fieldBorder,
        ),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: const StadiumBorder(),
      ),
      child: FittedBox(child: Text('$amount')),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final WithdrawCashState state;
  final VoidCallback onEdit;

  const _ReviewStep({required this.state, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final note = state.note.trim();
    final after = state.availableBalanceEgp - state.amountEgp;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.withdrawReviewHeading,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: palette.title,
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StackedRow(
                          label: l10n.withdrawTitle,
                          value: _money(state.amountEgp, locale, l10n.egp),
                        ),
                        if (note.isNotEmpty)
                          _StackedRow(label: l10n.notesOptional, value: note),
                        _StackedRow(
                          label: l10n.withdrawAvailableBalance,
                          value: _money(
                            state.availableBalanceEgp,
                            locale,
                            l10n.egp,
                          ),
                        ),
                        _StackedRow(
                          label: l10n.withdrawBalanceAfter,
                          value: _money(after, locale, l10n.egp),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.withdrawPendingExplain,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.muted,
                  ),
                ),
                if (_message(state, l10n, false) case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    key: const Key('withdraw-error'),
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.helper.copyWith(color: palette.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        _BottomBar(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('withdraw-edit'),
                  onPressed: state.submitting ? null : onEdit,
                  style: _outlineStyle(palette),
                  child: Text(l10n.withdrawEdit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('withdraw-submit'),
                  onPressed: state.submitting
                      ? null
                      : () {
                          if (_blockIfOffline(context, l10n)) return;
                          context.read<WithdrawCashBloc>().add(
                            const WithdrawCashSubmitted(),
                          );
                        },
                  style: _primaryStyle(palette),
                  child: state.submitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: palette.onAction,
                          ),
                        )
                      : Text(l10n.submitWithdraw),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackedRow extends StatelessWidget {
  final String label;
  final String value;

  const _StackedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: true,
            style: AppTextStyles.bodyLarge.copyWith(
              color: palette.title,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

String? _message(
  WithdrawCashState state,
  AppLocalizations l10n,
  bool amountOutOfRange,
) {
  if (state.summaryUnavailable) return null;
  if (amountOutOfRange ||
      (state.amountEgp > state.availableBalanceEgp && state.amountEgp > 0)) {
    return l10n.exceedsAvailableBalanceError;
  }
  return switch (state.error) {
    WithdrawCashError.invalidAmount => l10n.invalidAmountError,
    WithdrawCashError.exceedsAvailable => l10n.exceedsAvailableBalanceError,
    WithdrawCashError.unexpected => l10n.withdrawFailed,
    null => null,
  };
}

bool _blockIfOffline(BuildContext context, AppLocalizations l10n) {
  final connectivity = context.read<ConnectivityBloc>().state;
  if (!connectivity.blocksOnlineWork) return false;
  HapticsHelper.error();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
  return true;
}

ButtonStyle _primaryStyle(AppPalette palette) {
  return FilledButton.styleFrom(
    backgroundColor: palette.action,
    foregroundColor: palette.onAction,
    disabledBackgroundColor: palette.action.withValues(alpha: 0.35),
    disabledForegroundColor: palette.onAction.withValues(alpha: 0.7),
    minimumSize: const Size.fromHeight(52),
    textStyle: AppTextStyles.buttonLarge,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ButtonStyle _outlineStyle(AppPalette palette) {
  return OutlinedButton.styleFrom(
    foregroundColor: palette.title,
    minimumSize: const Size.fromHeight(52),
    side: BorderSide(color: palette.fieldBorder),
    textStyle: AppTextStyles.buttonLarge,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

OutlineInputBorder _amountBorder(AppPalette palette, {bool focused = false}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
      color: focused ? palette.focus : palette.fieldBorder,
      width: focused ? 1.6 : 1.2,
    ),
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
