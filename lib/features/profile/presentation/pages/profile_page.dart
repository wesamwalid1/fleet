import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approvals/presentation/bloc/approvals_bloc.dart';
import '../../../approvals/presentation/bloc/approvals_state.dart';
import '../../../home/domain/entities/driver.dart';
import '../../../home/domain/entities/financial_summary.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../language_sheet.dart';
import '../logout_dialog.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onOpenHome;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenHistory;

  const ProfilePage({
    super.key,
    required this.onOpenHome,
    required this.onOpenApprovals,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return switch (state) {
          HomeReady(:final driver, :final summary, :final financeStatus) =>
            _ProfileBody(
              driver: driver,
              summary: financeStatus == HomeFinanceStatus.ready
                  ? summary
                  : null,
              financeFailed: financeStatus == HomeFinanceStatus.failed,
              onOpenHome: onOpenHome,
              onOpenApprovals: onOpenApprovals,
              onOpenHistory: onOpenHistory,
            ),
          HomeFailure() => const _ProfileFailure(),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }
}

class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
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
              key: const Key('profile-retry'),
              onPressed: () =>
                  context.read<HomeBloc>().add(const HomeStarted()),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Driver driver;
  final FinancialSummary? summary;
  final bool financeFailed;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenHistory;

  const _ProfileBody({
    required this.driver,
    required this.summary,
    required this.financeFailed,
    required this.onOpenHome,
    required this.onOpenApprovals,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = summary == null
        ? null
        : formatHomeAmount(
            summary!.balanceEgp,
            locale: locale,
            withCurrency: true,
            currency: l10n.egp,
          );
    final balanceLabel = amount == null
        ? (financeFailed ? l10n.balanceLoadError : null)
        : l10n.profileBalance(amount);

    return Column(
      children: [
        _Header(
          initials: driver.initials,
          name: driver.fullName,
          identity: l10n.profileIdentity(driver.id, l10n.driversVault),
          balanceLabel: balanceLabel,
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                children: [
                  _MenuRow(
                    rowKey: const Key('profile-my-balance'),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primary,
                    iconBackground: AppColors.primary.withValues(alpha: 0.1),
                    title: l10n.myBalance,
                    onTap: onOpenHome,
                    trailing: amount == null
                        ? null
                        : Text(
                            amount,
                            key: const Key('profile-balance-amount'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _MenuRow(
                    rowKey: const Key('profile-pending'),
                    icon: Icons.notifications_none_rounded,
                    iconColor: AppColors.error,
                    iconBackground: AppColors.dangerBackground,
                    title: l10n.pendingApprovals,
                    onTap: onOpenApprovals,
                    trailing: const _PendingBadge(),
                  ),
                  const SizedBox(height: 12),
                  _MenuRow(
                    rowKey: const Key('profile-history'),
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.success,
                    iconBackground: AppColors.successBackground,
                    title: l10n.transactionHistory,
                    onTap: onOpenHistory,
                  ),
                  const SizedBox(height: 12),
                  _MenuRow(
                    rowKey: const Key('profile-language'),
                    icon: Icons.language_rounded,
                    iconColor: AppColors.info,
                    iconBackground: AppColors.infoBackground,
                    title: l10n.language,
                    onTap: () => showLanguageSheet(context),
                    trailing: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? l10n.languageArabic
                          : l10n.languageEnglish,
                      key: const Key('profile-language-value'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuRow(
                    rowKey: const Key('profile-logout'),
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    iconBackground: AppColors.dangerBackground,
                    title: l10n.logout,
                    titleColor: AppColors.error,
                    background: AppColors.dangerBackground,
                    borderColor: AppColors.dangerBorder,
                    onTap: () => showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String initials;
  final String name;
  final String identity;
  final String? balanceLabel;

  const _Header({
    required this.initials,
    required this.name,
    required this.identity,
    required this.balanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final headerTop = Color.lerp(AppColors.primary, Colors.white, 0.28)!;
    return SizedBox(
      key: const Key('profile-header'),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [headerTop, AppColors.primary],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 52),
            child: Column(
              children: [
                CircleAvatar(
                  key: const Key('profile-avatar'),
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  key: const Key('profile-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  identity,
                  key: const Key('profile-identity'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (balanceLabel != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    key: const Key('profile-balance'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      balanceLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalsBloc, ApprovalsState>(
      buildWhen: (previous, current) =>
          previous.pendingCount != current.pendingCount ||
          previous.loading != current.loading,
      builder: (context, state) {
        if (state.loading || state.pendingCount == 0) {
          return const SizedBox.shrink();
        }
        return Container(
          key: const Key('profile-pending-count'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: const BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Text(
            state.pendingCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final Key rowKey;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Color titleColor;
  final Color background;
  final Color borderColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.rowKey,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.onTap,
    this.titleColor = AppColors.title,
    this.background = Colors.white,
    this.borderColor = AppColors.border,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: trailing!,
                ),
              ],
              const SizedBox(width: 4),
              Icon(chevron, color: AppColors.hint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
