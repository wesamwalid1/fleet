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
import '../../domain/entities/cash_request.dart';
import '../../domain/entities/cash_request_result.dart';
import '../../domain/repositories/cash_request_repository.dart';
import '../../domain/usecases/request_cash.dart';
import '../bloc/request_cash_bloc.dart';
import '../bloc/request_cash_event.dart';
import '../bloc/request_cash_state.dart';

Future<void> showRequestCashSheet(
  BuildContext context, {
  required String driverId,
  void Function(String requestId)? onViewTransaction,
}) {
  final requests = context.read<CashRequestRepository>();
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
          value: requests,
          child: BlocProvider(
            create: (_) => RequestCashBloc(
              driverId: driverId,
              requestCash: RequestCash(requests),
              repository: requests,
            )..add(const RequestCashStarted()),
            child: BlocListener<RequestCashBloc, RequestCashState>(
              listenWhen: (previous, current) =>
                  previous.result == null && current.result != null,
              listener: (_, _) => homeBloc.add(const HomeSummaryRefreshed()),
              child: RequestCashSheet(onViewTransaction: onViewTransaction),
            ),
          ),
        ),
      );
    },
  );
}

class RequestCashSheet extends StatefulWidget {
  final void Function(String requestId)? onViewTransaction;

  const RequestCashSheet({super.key, this.onViewTransaction});

  @override
  State<RequestCashSheet> createState() => _RequestCashSheetState();
}

class _RequestCashSheetState extends State<RequestCashSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);

    return BlocListener<RequestCashBloc, RequestCashState>(
      listenWhen: (previous, current) =>
          previous.result == null && current.result != null,
      listener: (context, state) {
        final navigator = Navigator.of(context);
        final result = state.result!;
        final onView = widget.onViewTransaction;
        navigator.pop();
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => CashRequestSubmittedPage(
              result: result,
              onViewTransaction: onView,
            ),
          ),
        );
      },
      child: BlocListener<RequestCashBloc, RequestCashState>(
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
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: BlocBuilder<RequestCashBloc, RequestCashState>(
                  builder: (context, state) {
                    return _RequestCashForm(
                      state: state,
                      l10n: l10n,
                      amountController: _amountController,
                      noteController: _noteController,
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

class _RequestCashForm extends StatelessWidget {
  final RequestCashState state;
  final AppLocalizations l10n;
  final TextEditingController amountController;
  final TextEditingController noteController;

  const _RequestCashForm({
    required this.state,
    required this.l10n,
    required this.amountController,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Handle(),
        const SizedBox(height: 12),
        Text(
          l10n.requestCashTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.title,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.requestCashSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 18),
        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _SummaryCard(
            rows: [
              _SummaryLine(
                label: l10n.currentBalance,
                value: _money(state.currentBalanceEgp, locale, l10n.egp),
              ),
              _SummaryLine(
                label: l10n.maxLimit,
                value: _money(state.maxLimitEgp, locale, l10n.egp),
              ),
              _SummaryLine(
                label: l10n.availableRequestCapacity,
                value: _money(
                  state.availableRequestCapacityEgp,
                  locale,
                  l10n.egp,
                ),
                emphasize: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('request-cash-amount'),
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
              context.read<RequestCashBloc>().add(
                RequestCashAmountChanged(int.tryParse(value) ?? 0),
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('request-cash-note'),
            controller: noteController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.notesOptional,
              hintText: l10n.notesHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (value) {
              context.read<RequestCashBloc>().add(
                RequestCashNoteChanged(value),
              );
            },
          ),
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
                  key: const Key('request-cash-cancel'),
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
                  key: const Key('request-cash-submit'),
                  onPressed: state.canSubmit
                      ? () {
                          if (_blockIfOffline(context, l10n)) return;
                          context.read<RequestCashBloc>().add(
                            const RequestCashSubmitted(),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.4,
                    ),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
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
                      : Text(l10n.submitRequest),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String? _message(RequestCashState state, AppLocalizations l10n) {
    if (state.amountEgp > state.availableRequestCapacityEgp &&
        state.amountEgp > 0) {
      return l10n.exceedsRequestCapacityError;
    }
    return switch (state.error) {
      RequestCashError.invalidAmount => l10n.invalidAmountError,
      RequestCashError.exceedsCapacity => l10n.exceedsRequestCapacityError,
      RequestCashError.unexpected => l10n.requestCashFailed,
      null => null,
    };
  }
}

class CashRequestSubmittedPage extends StatelessWidget {
  final CashRequestResult result;
  final void Function(String requestId)? onViewTransaction;

  const CashRequestSubmittedPage({
    super.key,
    required this.result,
    this.onViewTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final request = result.request;
    final amount = _money(request.amountEgp, locale, l10n.egp);
    final isRequestCash = request.type == CashRequestType.requestCash;

    return Scaffold(
      backgroundColor: AppSurfaces.of(context).sheet,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                isRequestCash
                    ? Icons.south_west_rounded
                    : Icons.account_balance_outlined,
                color: AppColors.primary,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cashRequestSubmittedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.title,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cashRequestSubmittedDetail(amount, request.requestNumber),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
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
                    request.requestNumber,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('cash-request-home'),
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
                  key: const Key('cash-request-view'),
                  onPressed: () {
                    final id = request.id;
                    Navigator.pop(context);
                    onViewTransaction?.call(id);
                  },
                  style: _outlineStyle(),
                  child: Text(l10n.viewTransaction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<_SummaryLine> rows;

  const _SummaryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize ? AppColors.title : AppColors.muted,
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? AppColors.success : AppColors.title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

bool _blockIfOffline(BuildContext context, AppLocalizations l10n) {
  final connectivity = context.read<ConnectivityBloc>().state;
  if (!connectivity.blocksOnlineWork) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
  return true;
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
