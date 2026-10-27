import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/type_avatar.dart';
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

/// Account and settings: a dark identity header over light grouped rows
/// (Quick Access, Settings, Account) that scroll with it as one page.
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: AppColors.background,
        child: BlocBuilder<HomeBloc, HomeState>(
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
        ),
      ),
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
              style: AppTextStyles.body,
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

    // The shell extends its body behind the floating navigation bar and
    // reports the bar's height as bottom padding, so the last group can
    // scroll fully above it.
    return ListView(
      key: const Key('profile-scroll'),
      padding: EdgeInsets.only(
        bottom: 32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Header(
          initials: driver.initials,
          name: driver.fullName,
          title: l10n.navProfile,
          identity: l10n.profileIdentity(driver.id, l10n.driversVault),
          balanceLabel: balanceLabel,
        ),
        _SectionLabel(l10n.profileQuickAccess),
        _MenuGroup(
          groupKey: const Key('profile-quick-access'),
          children: [
            _MenuRow(
              rowKey: const Key('profile-my-balance'),
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.myBalance,
              onTap: onOpenHome,
              trailing: amount == null
                  ? null
                  : Text(
                      amount,
                      key: const Key('profile-balance-amount'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.amount.copyWith(fontSize: 14),
                    ),
            ),
            _MenuRow(
              rowKey: const Key('profile-pending'),
              icon: Icons.fact_check_outlined,
              title: l10n.pendingApprovals,
              onTap: onOpenApprovals,
              trailing: const _PendingBadge(),
            ),
            _MenuRow(
              rowKey: const Key('profile-history'),
              icon: Icons.history_rounded,
              title: l10n.transactionHistory,
              onTap: onOpenHistory,
            ),
          ],
        ),
        _SectionLabel(l10n.profileSettings),
        _MenuGroup(
          groupKey: const Key('profile-settings'),
          children: [
            _MenuRow(
              rowKey: const Key('profile-language'),
              icon: Icons.language_rounded,
              title: l10n.language,
              onTap: () => showLanguageSheet(context),
              trailing: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? l10n.languageArabic
                    : l10n.languageEnglish,
                key: const Key('profile-language-value'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // Placeholder only: no theme switching or persistence yet, so the
            // switch stays off and disabled.
            _MenuRow(
              rowKey: const Key('profile-dark-mode'),
              icon: Icons.dark_mode_outlined,
              title: l10n.darkMode,
              showChevron: false,
              trailing: const Switch(
                key: Key('profile-dark-mode-switch'),
                value: false,
                onChanged: null,
              ),
            ),
          ],
        ),
        _SectionLabel(l10n.profileAccount),
        _MenuGroup(
          groupKey: const Key('profile-account'),
          children: [
            _MenuRow(
              rowKey: const Key('profile-logout'),
              icon: Icons.logout_rounded,
              iconColor: AppColors.rejectedText,
              iconBackground: AppColors.dangerBackground,
              title: l10n.logout,
              titleColor: AppColors.rejectedText,
              showChevron: false,
              onTap: () => showLogoutDialog(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dark identity panel on the wallet's ink; it scrolls with the rows.
class _Header extends StatelessWidget {
  final String initials;
  final String name;
  final String title;
  final String identity;
  final String? balanceLabel;

  const _Header({
    required this.initials,
    required this.name,
    required this.title,
    required this.identity,
    required this.balanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final balanceLabel = this.balanceLabel;
    return DecoratedBox(
      key: const Key('profile-header'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.inkLift, AppColors.title],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.sheet),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    key: const Key('profile-avatar'),
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          initials,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          key: const Key('profile-name'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          identity,
                          key: const Key('profile-identity'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.hint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (balanceLabel != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DecoratedBox(
                    key: const Key('profile-balance'),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: AppColors.primaryOnInk,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              balanceLabel,
                              maxLines: 2,
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.primaryOnInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
        return StatusBadge.pending(
          key: const Key('profile-pending-count'),
          label: state.pendingCount.toString(),
        );
      },
    );
  }
}

/// Small all-caps heading above a group of rows.
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.groupLabel.copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

/// White card holding related rows, separated by hairlines.
class _MenuGroup extends StatelessWidget {
  final Key? groupKey;
  final List<Widget> children;

  const _MenuGroup({this.groupKey, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: groupKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 70,
                  endIndent: 16,
                  color: AppColors.title.withValues(alpha: 0.08),
                ),
              child,
            ],
          ],
        ),
      ),
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
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    this.onTap,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySurface,
    this.titleColor = AppColors.title,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
    return InkWell(
      key: rowKey,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              TypeAvatar(
                size: 40,
                tint: iconBackground,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowTitle.copyWith(color: titleColor),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: trailing!,
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(chevron, color: AppColors.hint, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
