import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/fade_through_route.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/finance_driver.dart';
import '../../domain/repositories/cash_transfer_repository.dart';
import '../../domain/usecases/send_cash.dart';
import '../bloc/send_cash_bloc.dart';
import '../bloc/send_cash_event.dart';
import '../bloc/send_cash_state.dart';
import '../widgets/send_cash_success.dart';

const _sendCashQuickAmounts = [500, 1000, 1500, 2000];

enum SendCashFlowStep { recipient, amount, review, success }

/// Opens the dedicated full-screen Send Cash flow on one [SendCashBloc].
Future<void> openSendCashFlow(
  BuildContext context, {
  required String senderId,
  void Function(String transferId)? onViewTransaction,
}) {
  final transfers = context.read<CashTransferRepository>();
  final homeBloc = context.read<HomeBloc>();
  final connectivity = context.read<ConnectivityBloc>();

  return Navigator.of(context).push<void>(
    FadeThroughRoute<void>(
      settings: const RouteSettings(name: AppRoute.sendCash),
      ground: (context) => AppPalette.of(context).ground,
      builder: (routeContext) {
        return BlocProvider.value(
          value: connectivity,
          child: BlocProvider.value(
            value: homeBloc,
            child: RepositoryProvider.value(
              value: transfers,
              child: BlocProvider(
                create: (_) => SendCashBloc(
                  senderId: senderId,
                  sendCash: SendCash(transfers),
                  repository: transfers,
                )..add(const SendCashStarted()),
                child: SendCashFlowPage(onViewTransaction: onViewTransaction),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class SendCashFlowPage extends StatefulWidget {
  final void Function(String transferId)? onViewTransaction;

  const SendCashFlowPage({super.key, this.onViewTransaction});

  @override
  State<SendCashFlowPage> createState() => _SendCashFlowPageState();
}

class _SendCashFlowPageState extends State<SendCashFlowPage> {
  SendCashFlowStep _step = SendCashFlowStep.recipient;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _goTo(SendCashFlowStep step) {
    setState(() => _step = step);
  }

  void _onBack(SendCashState state) {
    if (state.submitting) return;
    switch (_step) {
      case SendCashFlowStep.recipient:
        Navigator.of(context).pop();
      case SendCashFlowStep.amount:
        _goTo(SendCashFlowStep.recipient);
      case SendCashFlowStep.review:
        _goTo(SendCashFlowStep.amount);
      case SendCashFlowStep.success:
        Navigator.of(context).pop();
    }
  }

  void _syncAmountField(SendCashState state) {
    final text = state.amountEgp == 0 ? '' : '${state.amountEgp}';
    if (_amountController.text == text) return;
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return BlocListener<SendCashBloc, SendCashState>(
      listenWhen: (previous, current) =>
          previous.result == null && current.result != null,
      listener: (context, state) {
        context.read<HomeBloc>().add(const HomeSummaryRefreshed());
        _goTo(SendCashFlowStep.success);
      },
      child: BlocConsumer<SendCashBloc, SendCashState>(
        listenWhen: (previous, current) =>
            previous.amountEgp != current.amountEgp,
        listener: (context, state) => _syncAmountField(state),
        builder: (context, state) {
          if (_step == SendCashFlowStep.success) {
            final result = state.result;
            if (result == null) {
              return Scaffold(
                backgroundColor: palette.ground,
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            final recipient = state.selectedRecipient;
            final locale = Localizations.localeOf(context);
            return PopScope(
              canPop: true,
              child: RequestSentPage(
                result: result,
                recipientName:
                    recipient?.displayName(locale) ??
                    result.transfer.recipientId,
                recipientGivenName:
                    recipient?.givenName(locale) ??
                    recipient?.displayName(locale) ??
                    result.transfer.recipientId,
                onViewTransaction: widget.onViewTransaction,
                onGoHome: () => Navigator.of(context).pop(),
              ),
            );
          }

          final canLeave =
              !state.submitting && (_step == SendCashFlowStep.recipient);
          return PopScope(
            canPop: canLeave,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || state.submitting) return;
              _onBack(state);
            },
            child: Scaffold(
              key: const Key('send-cash-flow'),
              backgroundColor: palette.ground,
              appBar: AppBar(
                backgroundColor: palette.ground,
                surfaceTintColor: Colors.transparent,
                foregroundColor: palette.title,
                leading: IconButton(
                  key: const Key('send-cash-back'),
                  tooltip: l10n.back,
                  onPressed: state.submitting ? null : () => _onBack(state),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(
                  _title(l10n),
                  style: AppTextStyles.appBarTitle.copyWith(
                    color: palette.title,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _StepIndicator(
                      step: _step,
                      label: l10n.sendCashStepProgress(_stepIndex(_step), 3),
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
                      SendCashFlowStep.recipient => _RecipientStep(
                        state: state,
                        onContinue: () => _goTo(SendCashFlowStep.amount),
                      ),
                      SendCashFlowStep.amount => _AmountStep(
                        state: state,
                        amountController: _amountController,
                        onContinue: () => _goTo(SendCashFlowStep.review),
                      ),
                      SendCashFlowStep.review => _ReviewStep(
                        state: state,
                        onEdit: () => _goTo(SendCashFlowStep.amount),
                      ),
                      SendCashFlowStep.success => const SizedBox.shrink(),
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

  String _title(AppLocalizations l10n) {
    return switch (_step) {
      SendCashFlowStep.recipient => l10n.sendCashStepRecipient,
      SendCashFlowStep.amount => l10n.sendCashStepAmount,
      SendCashFlowStep.review => l10n.sendCashStepReview,
      SendCashFlowStep.success => l10n.requestSent,
    };
  }

  int _stepIndex(SendCashFlowStep step) {
    return switch (step) {
      SendCashFlowStep.recipient => 1,
      SendCashFlowStep.amount => 2,
      SendCashFlowStep.review => 3,
      SendCashFlowStep.success => 3,
    };
  }
}

class _StepIndicator extends StatelessWidget {
  final SendCashFlowStep step;
  final String label;

  const _StepIndicator({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final current = switch (step) {
      SendCashFlowStep.recipient => 0,
      SendCashFlowStep.amount => 1,
      SendCashFlowStep.review => 2,
      SendCashFlowStep.success => 2,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
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
          key: const Key('send-cash-step-label'),
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
      key: Key('send-cash-step-dot-$index'),
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

class _RecipientStep extends StatefulWidget {
  final SendCashState state;
  final VoidCallback onContinue;

  const _RecipientStep({required this.state, required this.onContinue});

  @override
  State<_RecipientStep> createState() => _RecipientStepState();
}

class _RecipientStepState extends State<_RecipientStep> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context);
    final state = widget.state;
    final filtered = _filterRecipients(state.recipients, _query);
    final showSearch = !state.loading && state.recipients.isNotEmpty;

    return Column(
      children: [
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: TextField(
              key: const Key('send-cash-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              style: AppTextStyles.bodyMedium.copyWith(color: palette.title),
              decoration: InputDecoration(
                hintText: l10n.sendCashSearchHint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: palette.muted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: palette.muted,
                  size: 22,
                ),
                suffixIcon: _query.trim().isEmpty
                    ? null
                    : IconButton(
                        key: const Key('send-cash-search-clear'),
                        tooltip: l10n.clearSearch,
                        onPressed: _clearQuery,
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.muted,
                          size: 20,
                        ),
                      ),
                filled: true,
                fillColor: palette.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: _amountBorder(palette),
                focusedBorder: _amountBorder(palette, focused: true),
              ),
            ),
          ),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.recipients.isEmpty
              ? Center(
                  child: Text(
                    l10n.noDrivers,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.muted,
                    ),
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    key: const Key('send-cash-no-search-results'),
                    l10n.sendCashNoSearchResults,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.muted,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final driver = filtered[index];
                    final selected = driver.id == state.recipientId;
                    return _DriverTile(
                      driver: driver,
                      selected: selected,
                      locale: locale,
                      onTap: () => context.read<SendCashBloc>().add(
                        SendCashRecipientSelected(driver.id),
                      ),
                    );
                  },
                ),
        ),
        _BottomBar(
          child: FilledButton(
            key: const Key('send-cash-continue'),
            onPressed: state.recipientId == null ? null : widget.onContinue,
            style: _primaryStyle(palette),
            child: Text(l10n.sendCashContinue),
          ),
        ),
      ],
    );
  }
}

List<FinanceDriver> _filterRecipients(
  List<FinanceDriver> recipients,
  String rawQuery,
) {
  final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (query.isEmpty) return recipients;
  return [
    for (final driver in recipients)
      if (_matchesRecipient(driver, query)) driver,
  ];
}

bool _matchesRecipient(FinanceDriver driver, String query) {
  if (driver.fullName.matchesQuery(query)) return true;
  return driver.id.toLowerCase().contains(query.toLowerCase());
}

class _DriverTile extends StatelessWidget {
  final FinanceDriver driver;
  final bool selected;
  final Locale locale;
  final VoidCallback onTap;

  const _DriverTile({
    required this.driver,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: selected
          ? palette.action.withValues(alpha: 0.08)
          : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? palette.action : palette.hairline,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        key: Key('send-cash-driver-${driver.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: palette.action,
                child: Text(
                  driver.initials(locale),
                  style: AppTextStyles.helper.copyWith(
                    color: palette.onAction,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.rowTitle.copyWith(
                        color: palette.title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.driverCodeBalance(
                        driver.id,
                        _money(driver.balanceEgp, locale.toString(), l10n.egp),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: palette.action),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  final SendCashState state;
  final TextEditingController amountController;
  final VoidCallback onContinue;

  const _AmountStep({
    required this.state,
    required this.amountController,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final recipient = state.selectedRecipient;
    final canContinue =
        state.recipientId != null &&
        state.amountEgp > 0 &&
        state.amountEgp <= state.senderBalanceEgp;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recipient != null) ...[
                  Text(
                    recipient.displayName(Localizations.localeOf(context)),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: palette.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  key: const Key('send-cash-amount'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    enabledBorder: _amountBorder(palette),
                    focusedBorder: _amountBorder(palette, focused: true),
                  ),
                  onChanged: (value) {
                    context.read<SendCashBloc>().add(
                      SendCashAmountChanged(int.tryParse(value) ?? 0),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.yourBalance(
                    _money(state.senderBalanceEgp, locale, l10n.egp),
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < _sendCashQuickAmounts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _AmountChip(amount: _sendCashQuickAmounts[i]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _BalanceSummary(state: state),
                if (recipient != null) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    text: l10n.mustApprove(
                      recipient.givenName(Localizations.localeOf(context)),
                    ),
                  ),
                ],
                if (_amountMessage(state, l10n) case final message?) ...[
                  const SizedBox(height: 10),
                  Text(
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
          child: FilledButton(
            key: const Key('send-cash-continue'),
            onPressed: canContinue ? onContinue : null,
            style: _primaryStyle(palette),
            child: Text(l10n.sendCashContinue),
          ),
        ),
      ],
    );
  }

  String? _amountMessage(SendCashState state, AppLocalizations l10n) {
    if (state.amountEgp > state.senderBalanceEgp && state.amountEgp > 0) {
      return l10n.insufficientBalanceError;
    }
    return switch (state.error) {
      SendCashError.invalidAmount => l10n.invalidAmountError,
      SendCashError.insufficientBalance => l10n.insufficientBalanceError,
      SendCashError.unexpected => l10n.sendCashFailed,
      SendCashError.selectRecipient => l10n.selectDriverError,
      null => null,
    };
  }
}

class _ReviewStep extends StatelessWidget {
  final SendCashState state;
  final VoidCallback onEdit;

  const _ReviewStep({required this.state, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context);
    final recipient = state.selectedRecipient;
    final after = state.senderBalanceEgp - state.amountEgp;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.sendCashReviewHeading,
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
                        _ReviewRow(
                          label: l10n.sendCashRecipientLabel,
                          value:
                              recipient?.displayName(locale) ??
                              state.recipientId ??
                              '—',
                          detail: recipient?.id ?? state.recipientId,
                        ),
                        _ReviewRow(
                          label: l10n.amount,
                          value: _money(
                            state.amountEgp,
                            locale.toString(),
                            l10n.egp,
                          ),
                          compact: true,
                        ),
                        _ReviewRow(
                          label: l10n.yourBalanceAfter,
                          value: _money(after, locale.toString(), l10n.egp),
                          valueColor: palette.error,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if (recipient != null) ...[
                  const SizedBox(height: 14),
                  _InfoBanner(
                    text: l10n.mustApprove(recipient.givenName(locale)),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    key: const Key('send-cash-error'),
                    _errorText(state.error!, l10n),
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
                  key: const Key('send-cash-edit'),
                  onPressed: state.submitting ? null : onEdit,
                  style: _outlineStyle(palette),
                  child: Text(l10n.sendCashEdit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('send-cash-submit'),
                  onPressed: state.canSubmit
                      ? () {
                          final connectivity = context
                              .read<ConnectivityBloc>()
                              .state;
                          if (connectivity.blocksOnlineWork) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                key: const Key('offline-action-notice'),
                                content: Text(
                                  l10n.offlineActionRequiresInternet,
                                ),
                              ),
                            );
                            return;
                          }
                          context.read<SendCashBloc>().add(
                            const SendCashSubmitted(),
                          );
                        }
                      : null,
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
                      : Text(l10n.confirm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _errorText(SendCashError error, AppLocalizations l10n) {
    return switch (error) {
      SendCashError.selectRecipient => l10n.selectDriverError,
      SendCashError.invalidAmount => l10n.invalidAmountError,
      SendCashError.insufficientBalance => l10n.insufficientBalanceError,
      SendCashError.unexpected => l10n.sendCashFailed,
    };
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final Color? valueColor;

  /// Compact numeric rows stay label/value horizontal when still readable.
  final bool compact;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.detail,
    this.valueColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final labelStyle = AppTextStyles.bodyMedium.copyWith(color: palette.muted);
    final valueStyle = AppTextStyles.bodyLarge.copyWith(
      color: valueColor ?? palette.title,
      fontWeight: FontWeight.w700,
    );
    final detailStyle = AppTextStyles.helper.copyWith(color: palette.muted);

    if (!compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 4),
            Text(value, softWrap: true, style: valueStyle),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(detail!, softWrap: true, style: detailStyle),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final SendCashState state;

  const _BalanceSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final after = state.senderBalanceEgp - state.amountEgp;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _SummaryLine(
              label: l10n.yourBalanceAfter,
              value: _money(after, locale, l10n.egp),
              valueColor: palette.error,
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              label: l10n.amount,
              value: _money(state.amountEgp, locale, l10n.egp),
              valueColor: palette.action,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryLine({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTextStyles.tabular,
            ),
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
    final selected = context.select<SendCashBloc, bool>(
      (bloc) => bloc.state.amountEgp == amount,
    );
    return OutlinedButton(
      key: Key('send-cash-chip-$amount'),
      onPressed: () =>
          context.read<SendCashBloc>().add(SendCashAmountChanged(amount)),
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

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: palette.body, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
      elevation: 0,
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
