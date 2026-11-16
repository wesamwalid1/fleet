import 'package:flutter/material.dart';

import '../../../../core/haptics/haptics_helper.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../domain/entities/send_cash_result.dart';

/// Success screen for a completed Send Cash request.
class RequestSentPage extends StatefulWidget {
  final SendCashResult result;
  final String recipientName;
  final String recipientGivenName;
  final void Function(String transferId)? onViewTransaction;
  final VoidCallback? onGoHome;

  const RequestSentPage({
    super.key,
    required this.result,
    required this.recipientName,
    required this.recipientGivenName,
    this.onViewTransaction,
    this.onGoHome,
  });

  @override
  State<RequestSentPage> createState() => _RequestSentPageState();
}

class _RequestSentPageState extends State<RequestSentPage> {
  @override
  void initState() {
    super.initState();
    HapticsHelper.success();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = formatHomeAmount(
      widget.result.transfer.amountEgp,
      locale: locale,
      withCurrency: true,
      currency: l10n.egp,
    );
    final balance = formatHomeAmount(
      widget.result.senderBalanceEgp,
      locale: locale,
      withCurrency: true,
      currency: l10n.egp,
    );

    return Scaffold(
      key: const Key('send-cash-success'),
      backgroundColor: palette.ground,
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
                    Icon(Icons.outbox_rounded, color: palette.action, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      l10n.requestSent,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(color: palette.title),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.requestSentDetail(amount, widget.recipientName),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.field,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.hairline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: palette.body,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.waitingForApproval(
                                  widget.recipientGivenName,
                                ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: palette.body,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.action.withValues(alpha: 0.08),
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
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              balance,
                              style: AppTextStyles.display.copyWith(
                                color: palette.action,
                                fontFeatures: AppTextStyles.tabular,
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
                          widget.result.transfer.id,
                          style: AppTextStyles.helper.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('send-cash-home'),
                        onPressed:
                            widget.onGoHome ?? () => Navigator.pop(context),
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
                        key: const Key('send-cash-view'),
                        onPressed: () {
                          final transferId = widget.result.transfer.id;
                          Navigator.pop(context);
                          widget.onViewTransaction?.call(transferId);
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
            );
          },
        ),
      ),
    );
  }
}
