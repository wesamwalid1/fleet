import 'package:flutter/material.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../domain/entities/cash_request.dart';
import '../../domain/entities/cash_request_result.dart';

/// Shared success content for Request Cash and Withdraw submissions.
class CashRequestSubmittedPage extends StatelessWidget {
  final CashRequestResult result;
  final void Function(String requestId)? onViewTransaction;
  final VoidCallback? onGoHome;

  const CashRequestSubmittedPage({
    super.key,
    required this.result,
    this.onViewTransaction,
    this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final request = result.request;
    final amount = formatHomeAmount(
      request.amountEgp,
      locale: locale,
      withCurrency: true,
      currency: l10n.egp,
    );
    final isRequestCash = request.type == CashRequestType.requestCash;

    return Scaffold(
      key: const Key('cash-request-success'),
      backgroundColor: palette.ground,
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
                color: palette.action,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cashRequestSubmittedTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(color: palette.title),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cashRequestSubmittedDetail(amount, request.requestNumber),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.pendingConfirm,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.field,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    request.requestNumber,
                    style: AppTextStyles.helper.copyWith(color: palette.muted),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('cash-request-home'),
                  onPressed: onGoHome ?? () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.action,
                    foregroundColor: palette.onAction,
                    minimumSize: const Size.fromHeight(52),
                    textStyle: AppTextStyles.buttonLarge,
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
                    final view = onViewTransaction;
                    (onGoHome ?? () => Navigator.pop(context))();
                    view?.call(id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.title,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: palette.fieldBorder),
                    textStyle: AppTextStyles.buttonLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
