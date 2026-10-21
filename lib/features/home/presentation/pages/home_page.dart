import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/presentation/widgets/record_expense_sheet.dart';
import '../../../finance/presentation/widgets/send_cash_sheet.dart';
import '../../domain/entities/financial_summary.dart';
import '../amount_format.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../greeting_text.dart';
import '../widgets/balance_card.dart';
import '../widgets/home_header.dart';
import '../widgets/pending_approvals_section.dart';
import '../widgets/recent_transactions_section.dart';

class HomePage extends StatelessWidget {
  final DateTime Function() now;
  final VoidCallback? onOpenApprovals;
  final VoidCallback? onOpenHistory;

  const HomePage({
    super.key,
    required this.now,
    this.onOpenApprovals,
    this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return switch (state) {
              HomeReady(:final driver, :final summary, :final financeStatus) =>
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeHeader(
                        greeting: greetingText(l10n, now()),
                        fullName: driver.fullName,
                        initials: driver.initials,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          0,
                          20,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _balanceBody(
                              context,
                              l10n,
                              summary: summary,
                              financeStatus: financeStatus,
                            ),
                            if (financeStatus == HomeFinanceStatus.ready &&
                                summary != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      key: const Key('send-cash'),
                                      onPressed: () => showSendCashSheet(
                                        context,
                                        senderId: driver.id,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.send_rounded),
                                      label: Text(
                                        l10n.sendCash,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      key: const Key('record-expense'),
                                      onPressed: () => showRecordExpenseSheet(
                                        context,
                                        driverId: driver.id,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: AppColors.error,
                                        ),
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        l10n.recordExpense,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              PendingApprovalsSection(
                                onSeeAll: onOpenApprovals,
                              ),
                              const SizedBox(height: 12),
                              RecentTransactionsSection(
                                now: now,
                                onSeeAll: onOpenHistory,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              HomeFailure() => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.homeLoadError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      TextButton(
                        key: const Key('home-retry'),
                        onPressed: () =>
                            context.read<HomeBloc>().add(const HomeStarted()),
                        child: Text(l10n.tryAgain),
                      ),
                    ],
                  ),
                ),
              ),
              _ => const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
                child: BalanceCardPlaceholder(),
              ),
            };
          },
        ),
      ),
    );
  }

  Widget _balanceBody(
    BuildContext context,
    AppLocalizations l10n, {
    required FinancialSummary? summary,
    required HomeFinanceStatus financeStatus,
  }) {
    final locale = Localizations.localeOf(context).toString();
    return switch (financeStatus) {
      HomeFinanceStatus.loading => const BalanceCardPlaceholder(),
      HomeFinanceStatus.failed => const BalanceCardError(),
      HomeFinanceStatus.ready when summary != null => BalanceCard(
        balance: formatHomeAmount(
          summary.balanceEgp,
          locale: locale,
          withCurrency: true,
          currency: l10n.egp,
        ),
        charge: formatHomeAmount(
          summary.chargeEgp,
          locale: locale,
          withCurrency: false,
          currency: l10n.egp,
        ),
        maxLimit: formatHomeAmount(
          summary.maxLimitEgp,
          locale: locale,
          withCurrency: true,
          currency: l10n.egp,
        ),
      ),
      HomeFinanceStatus.ready => const BalanceCardError(),
    };
  }
}
