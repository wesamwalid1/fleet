import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/finance_driver.dart';
import '../../domain/entities/send_cash_result.dart';
import '../../domain/repositories/cash_transfer_repository.dart';
import '../../domain/usecases/send_cash.dart';
import '../bloc/send_cash_bloc.dart';
import '../bloc/send_cash_event.dart';
import '../bloc/send_cash_state.dart';

const sendCashQuickAmounts = [500, 1000, 1500, 2000];

Future<void> showSendCashSheet(
  BuildContext context, {
  required String senderId,
  void Function(String transferId)? onViewTransaction,
}) {
  final transfers = context.read<CashTransferRepository>();
  final homeBloc = context.read<HomeBloc>();
  final connectivity = context.read<ConnectivityBloc>();

  final height = MediaQuery.sizeOf(context).height;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    backgroundColor: AppSurfaces.of(context).sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return BlocProvider.value(
        value: connectivity,
        child: RepositoryProvider.value(
          value: transfers,
          child: BlocProvider(
            create: (_) => SendCashBloc(
              senderId: senderId,
              sendCash: SendCash(transfers),
              repository: transfers,
            )..add(const SendCashStarted()),
            child: BlocListener<SendCashBloc, SendCashState>(
              listenWhen: (previous, current) =>
                  previous.result == null && current.result != null,
              listener: (_, _) => homeBloc.add(const HomeSummaryRefreshed()),
              child: SendCashSheet(onViewTransaction: onViewTransaction),
            ),
          ),
        ),
      );
    },
  );
}

class SendCashSheet extends StatefulWidget {
  final void Function(String transferId)? onViewTransaction;

  const SendCashSheet({super.key, this.onViewTransaction});

  @override
  State<SendCashSheet> createState() => _SendCashSheetState();
}

class _SendCashSheetState extends State<SendCashSheet> {
  final _amountController = TextEditingController();
  bool _driversOpen = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom;

    return BlocListener<SendCashBloc, SendCashState>(
      listenWhen: (previous, current) =>
          previous.result == null && current.result != null,
      listener: (context, state) {
        final navigator = Navigator.of(context);
        final result = state.result!;
        final recipient = state.selectedRecipient;
        final onViewTransaction = widget.onViewTransaction;
        navigator.pop();
        navigator.push(
          MaterialPageRoute<void>(
            builder: (pageContext) {
              final locale = Localizations.localeOf(pageContext);
              return RequestSentPage(
                result: result,
                recipientName:
                    recipient?.displayName(locale) ??
                    result.transfer.recipientId,
                recipientGivenName:
                    recipient?.givenName(locale) ??
                    recipient?.displayName(locale) ??
                    result.transfer.recipientId,
                onViewTransaction: onViewTransaction,
              );
            },
          ),
        );
      },
      child: BlocListener<SendCashBloc, SendCashState>(
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
          padding: EdgeInsets.only(bottom: bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: BlocBuilder<SendCashBloc, SendCashState>(
                  builder: (context, state) {
                    return _SendCashForm(
                      state: state,
                      l10n: l10n,
                      amountController: _amountController,
                      driversOpen: _driversOpen,
                      onToggleDrivers: () =>
                          setState(() => _driversOpen = !_driversOpen),
                      onDriverSelected: () =>
                          setState(() => _driversOpen = false),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendCashForm extends StatelessWidget {
  final SendCashState state;
  final AppLocalizations l10n;
  final TextEditingController amountController;
  final bool driversOpen;
  final VoidCallback onToggleDrivers;
  final VoidCallback onDriverSelected;

  const _SendCashForm({
    required this.state,
    required this.l10n,
    required this.amountController,
    required this.driversOpen,
    required this.onToggleDrivers,
    required this.onDriverSelected,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final recipient = state.selectedRecipient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Handle(),
        const SizedBox(height: 12),
        Text(
          l10n.sendCashTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.title,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.sendCashSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 18),
        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.recipients.isEmpty)
          Text(
            l10n.noDrivers,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          )
        else ...[
          _DriverSelector(
            driver: recipient,
            open: driversOpen,
            onTap: onToggleDrivers,
          ),
          if (driversOpen) ...[
            const SizedBox(height: 8),
            _DriverList(
              drivers: state.recipients,
              onSelected: (driver) {
                context.read<SendCashBloc>().add(
                  SendCashRecipientSelected(driver.id),
                );
                onDriverSelected();
              },
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextField(
          key: const Key('send-cash-amount'),
          controller: amountController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.35),
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: _amountBorder(),
            focusedBorder: _amountBorder(),
          ),
          onChanged: (value) {
            context.read<SendCashBloc>().add(
              SendCashAmountChanged(int.tryParse(value) ?? 0),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.yourBalance(_money(state.senderBalanceEgp, locale, l10n.egp)),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (
              var index = 0;
              index < sendCashQuickAmounts.length;
              index++
            ) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: _AmountChip(amount: sendCashQuickAmounts[index])),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _AmountSummary(state: state),
        if (recipient != null) ...[
          const SizedBox(height: 12),
          _WarningBanner(
            text: l10n.mustApprove(
              recipient.givenName(Localizations.localeOf(context)),
            ),
          ),
        ],
        if (_message(state, l10n) case final message?) ...[
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('send-cash-cancel'),
                onPressed: state.submitting
                    ? null
                    : () => Navigator.pop(context),
                style: _outlineStyle(),
                child: Text(l10n.cancel),
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
                              content: Text(l10n.offlineActionRequiresInternet),
                            ),
                          );
                          return;
                        }
                        context.read<SendCashBloc>().add(
                          const SendCashSubmitted(),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 52),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.sendRequest),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _message(SendCashState state, AppLocalizations l10n) {
    if (state.amountEgp > state.senderBalanceEgp && state.amountEgp > 0) {
      return l10n.insufficientBalanceError;
    }
    return switch (state.error) {
      SendCashError.selectRecipient => l10n.selectDriverError,
      SendCashError.invalidAmount => l10n.invalidAmountError,
      SendCashError.insufficientBalance => l10n.insufficientBalanceError,
      SendCashError.unexpected => l10n.sendCashFailed,
      null => null,
    };
  }
}

class RequestSentPage extends StatelessWidget {
  final SendCashResult result;
  final String recipientName;
  final String recipientGivenName;
  final void Function(String transferId)? onViewTransaction;

  const RequestSentPage({
    super.key,
    required this.result,
    required this.recipientName,
    required this.recipientGivenName,
    this.onViewTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = _money(result.transfer.amountEgp, locale, l10n.egp);
    final balance = _money(result.senderBalanceEgp, locale, l10n.egp);

    return Scaffold(
      backgroundColor: AppSurfaces.of(context).sheet,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.outbox_rounded,
                      color: AppColors.primary,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.requestSent,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.title,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.requestSentDetail(amount, recipientName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WarningBanner(
                      text: l10n.waitingForApproval(recipientGivenName),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.currentBalance,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              balance,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.pendingConfirm,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.warningText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          result.transfer.id,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('send-cash-home'),
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.goHome),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('send-cash-view'),
                        onPressed: () {
                          final transferId = result.transfer.id;
                          Navigator.pop(context);
                          onViewTransaction?.call(transferId);
                        },
                        style: _outlineStyle(),
                        child: Text(l10n.viewTransaction),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DriverSelector extends StatelessWidget {
  final FinanceDriver? driver;
  final bool open;
  final VoidCallback onTap;

  const _DriverSelector({
    required this.driver,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Material(
      color: AppSurfaces.of(context).card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      child: InkWell(
        key: const Key('send-cash-driver'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (driver == null)
                Expanded(
                  child: Text(
                    l10n.selectDriver,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                    ),
                  ),
                )
              else ...[
                _Initials(initials: driver!.initials(locale)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver!.displayName(locale),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.driverCodeBalance(
                          driver!.id,
                          _money(driver!.balanceEgp, locale, l10n.egp),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Icon(
                open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverList extends StatelessWidget {
  final List<FinanceDriver> drivers;
  final ValueChanged<FinanceDriver> onSelected;

  const _DriverList({required this.drivers, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < drivers.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            InkWell(
              key: Key('send-cash-driver-${drivers[index].id}'),
              onTap: () => onSelected(drivers[index]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _Initials(initials: drivers[index].initials(locale)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drivers[index].displayName(locale),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.title,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            drivers[index].id,
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;

  const _AmountChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<SendCashBloc, bool>(
      (bloc) => bloc.state.amountEgp == amount,
    );
    return OutlinedButton(
      key: Key('send-cash-chip-$amount'),
      onPressed: () =>
          context.read<SendCashBloc>().add(SendCashAmountChanged(amount)),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? AppColors.primary
            : AppSurfaces.of(context).chipIdle,
        foregroundColor: selected
            ? Colors.white
            : AppSurfaces.of(context).title,
        side: BorderSide(
          color: selected ? AppColors.primary : AppSurfaces.of(context).border,
        ),
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: const StadiumBorder(),
      ),
      child: FittedBox(child: Text('$amount')),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  final SendCashState state;

  const _AmountSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final after = state.senderBalanceEgp - state.amountEgp;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _SummaryRow(
              label: l10n.yourBalanceAfter,
              value: _money(after, locale, l10n.egp),
              valueColor: AppColors.error,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: l10n.amount,
              value: _money(state.amountEgp, locale, l10n.egp),
              valueColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String text;

  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningText,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.warningText,
                  fontSize: 13,
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

class _Initials extends StatelessWidget {
  final String initials;

  const _Initials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox(width: 42, height: 4),
      ),
    );
  }
}

String _money(int amount, String locale, String currency) {
  return formatHomeAmount(
    amount,
    locale: locale,
    withCurrency: true,
    currency: currency,
  );
}

OutlineInputBorder _amountBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.primaryBorder, width: 1.4),
  );
}

ButtonStyle _outlineStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: AppColors.title,
    minimumSize: const Size.fromHeight(52),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
