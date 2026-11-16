import 'package:flutter/material.dart';

import '../../../../core/haptics/haptics_helper.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../domain/entities/record_expense_result.dart';
import '../settlement_style.dart';

/// Success screen for a completed Record Expense submission.
class ExpenseRecordedPage extends StatefulWidget {
  final RecordExpenseResult result;
  final String? tripCode;
  final VoidCallback? onDone;

  const ExpenseRecordedPage({
    super.key,
    required this.result,
    this.tripCode,
    this.onDone,
  });

  @override
  State<ExpenseRecordedPage> createState() => _ExpenseRecordedPageState();
}

class _ExpenseRecordedPageState extends State<ExpenseRecordedPage> {
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
    final expense = widget.result.expense;
    final settlement = settlementTitle(l10n, expense.settlementType);

    return Scaffold(
      key: const Key('expense-success'),
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
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: palette.action,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.expenseRecorded,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(color: palette.title),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.expenseDeducted(settlement),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.action.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              l10n.amountDeducted,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '−${_money(expense.amountEgp, locale, l10n.egp)}',
                              style: AppTextStyles.display.copyWith(
                                color: palette.action,
                                fontFeatures: AppTextStyles.tabular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          children: [
                            _SuccessRow(
                              label: l10n.newBalance,
                              value: _money(
                                widget.result.balanceEgp,
                                locale,
                                l10n.egp,
                              ),
                              valueColor: palette.action,
                            ),
                            _SuccessRow(
                              label: l10n.tripCode,
                              value: widget.tripCode ?? expense.tripId,
                            ),
                            _SuccessRow(
                              label: l10n.reference,
                              value: expense.id,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('expense-done'),
                        onPressed:
                            widget.onDone ?? () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.action,
                          foregroundColor: palette.onAction,
                          minimumSize: const Size.fromHeight(52),
                          textStyle: AppTextStyles.buttonLarge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.done),
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

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SuccessRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
              color: valueColor ?? palette.title,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
