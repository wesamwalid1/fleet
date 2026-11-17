import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/haptics/haptics_helper.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/presentation/bloc/theme_bloc.dart';
import '../../../../core/theme/presentation/bloc/theme_event.dart';
import '../../../../core/theme/presentation/bloc/theme_state.dart';
import '../../../../core/loading/minimum_loading_window.dart';
import '../../../../core/widgets/fleet_refresh_indicator.dart';
import '../../../../core/widgets/fleet_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approvals/presentation/bloc/approvals_bloc.dart';
import '../../../approvals/presentation/bloc/approvals_event.dart';
import '../../../approvals/presentation/bloc/approvals_state.dart';
import '../../../home/domain/entities/driver.dart';
import '../../../home/domain/entities/financial_summary.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../language_sheet.dart';
import '../logout_dialog.dart';

/// Account and settings, laid out as the driver's company ID: one raised
/// badge says who is signed in, and the rows that change things sit loose on
/// the ground below it, divided by hairlines.
class ProfilePage extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenHistory;

  /// Clock for a manual pull's minimum loading window. Defaults to wall time.
  final DateTime Function()? loadingNow;

  const ProfilePage({
    super.key,
    this.scrollController,
    required this.onOpenHome,
    required this.onOpenApprovals,
    required this.onOpenHistory,
    this.loadingNow,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void>? _pullInFlight;

  Future<void> _onPullToRefresh() {
    final connectivity = context.read<ConnectivityBloc>().state;
    if (connectivity.blocksOnlineWork) {
      _showOfflineActionNotice(context);
      return Future<void>.value();
    }
    return _pullInFlight ??= _performPull().whenComplete(() {
      _pullInFlight = null;
    });
  }

  Future<void> _performPull() async {
    final window = MinimumLoadingWindow(
      participants: 2,
      now: widget.loadingNow,
    );
    final summaryDone = Completer<void>();
    final approvalsDone = Completer<void>();
    context.read<HomeBloc>().add(
      HomeSummaryRefreshed(done: summaryDone, window: window),
    );
    context.read<ApprovalsBloc>().add(
      ApprovalsRefreshed(done: approvalsDone, window: window),
    );
    await Future.wait<void>([summaryDone.future, approvalsDone.future]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: palette.isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: palette.isDark
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Material(
        color: palette.ground,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return switch (state) {
              HomeReady(:final driver, :final summary, :final financeStatus) =>
                _ProfileBody(
                  scrollController: widget.scrollController,
                  driver: driver,
                  summary: financeStatus == HomeFinanceStatus.ready
                      ? summary
                      : null,
                  financeLoading: financeStatus == HomeFinanceStatus.loading,
                  financeFailed: financeStatus == HomeFinanceStatus.failed,
                  onOpenHome: widget.onOpenHome,
                  onOpenApprovals: widget.onOpenApprovals,
                  onOpenHistory: widget.onOpenHistory,
                  onRefresh: _onPullToRefresh,
                ),
              HomeFailure() => const _ProfileFailure(),
              _ => Center(
                child: CircularProgressIndicator(
                  color: palette.action,
                  strokeWidth: 2.2,
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

void _showOfflineActionNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  HapticsHelper.error();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
}

class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homeLoadError,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: palette.body),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('profile-retry'),
              onPressed: () =>
                  context.read<HomeBloc>().add(const HomeStarted()),
              style: TextButton.styleFrom(
                foregroundColor: palette.action,
                minimumSize: const Size(48, 48),
                textStyle: _buttonText(context),
              ),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final ScrollController? scrollController;
  final Driver driver;
  final FinancialSummary? summary;
  final bool financeLoading;
  final bool financeFailed;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenApprovals;
  final VoidCallback onOpenHistory;
  final Future<void> Function() onRefresh;

  const _ProfileBody({
    this.scrollController,
    required this.driver,
    required this.summary,
    required this.financeLoading,
    required this.financeFailed,
    required this.onOpenHome,
    required this.onOpenApprovals,
    required this.onOpenHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context);
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (previous, current) =>
          previous.isUnavailable != current.isUnavailable,
      builder: (context, connectivity) {
        final offline = connectivity.isUnavailable;
        final amount = offline || summary == null
            ? null
            : formatHomeAmount(
                summary!.balanceEgp,
                locale: locale.toString(),
                withCurrency: true,
                currency: l10n.egp,
              );
        final balance = offline
            ? l10n.offlineSectionUnavailable
            : amount ?? (financeFailed ? l10n.balanceLoadError : null);
        final language = locale.languageCode == 'ar'
            ? l10n.languageArabic
            : l10n.languageEnglish;

        // The shell extends its body behind the floating navigation bar and
        // reports the bar's height as bottom padding, so the last group can
        // scroll fully above it.
        return FleetRefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            key: const Key('profile-scroll'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: 32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
            _Header(
              title: l10n.navProfile,
              initials: driver.initials(locale),
              name: driver.displayName(locale),
              driverId: driver.id,
              vault: l10n.driversVault,
              balance: balance,
              balanceIsStatus: amount == null,
              balanceLoading: financeLoading,
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
                  trailing: financeLoading
                      ? const FleetValueSkeleton(
                          key: Key('profile-menu-balance-loading'),
                        )
                      : amount == null
                      ? null
                      : _Swap(
                          value: amount,
                          child: Text(
                            amount,
                            key: const Key('profile-balance-amount'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _valueStyle(palette),
                          ),
                        ),
                ),
                _MenuRow(
                  rowKey: const Key('profile-pending'),
                  icon: Icons.fact_check_outlined,
                  title: l10n.pendingApprovals,
                  onTap: onOpenApprovals,
                  trailing: offline ? null : const _PendingCount(),
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
                  trailing: _Swap(
                    value: language,
                    child: Text(
                      language,
                      key: const Key('profile-language-value'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _valueStyle(palette),
                    ),
                  ),
                ),
                // Like SwitchListTile: the whole row toggles, the merged node
                // announces the label with the switch state, and focus stops
                // once on the row.
                BlocBuilder<ThemeBloc, ThemePreferenceState>(
                  builder: (context, themeState) {
                    final dark = themeState.mode == ThemeMode.dark;
                    void select(bool value) {
                      if (value == dark) return;
                      HapticsHelper.selection();
                      context.read<ThemeBloc>().add(
                        ThemeModeSelected(
                          value ? ThemeMode.dark : ThemeMode.light,
                        ),
                      );
                    }

                    return MergeSemantics(
                      child: _MenuRow(
                        rowKey: const Key('profile-dark-mode'),
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkMode,
                        showChevron: false,
                        onTap: () => select(!dark),
                        trailing: ExcludeFocus(
                          child: Switch(
                            key: const Key('profile-dark-mode-switch'),
                            value: dark,
                            activeTrackColor: palette.action,
                            activeThumbColor: palette.onAction,
                            inactiveTrackColor: palette.field,
                            inactiveThumbColor: palette.fieldBorder,
                            trackOutlineColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? palette.action
                                  : palette.fieldBorder,
                            ),
                            onChanged: select,
                          ),
                        ),
                      ),
                    );
                  },
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
                  title: l10n.logout,
                  destructive: true,
                  showChevron: false,
                  onTap: () => showLogoutDialog(context),
                ),
              ],
            ),
          ],
          ),
        );
      },
    );
  }
}

/// Page title over the company ID badge.
class _Header extends StatelessWidget {
  final String title;
  final String initials;
  final String name;
  final String driverId;
  final String vault;
  final String? balance;

  /// [balance] is a status line (offline or failed), not an amount.
  final bool balanceIsStatus;
  final bool balanceLoading;

  const _Header({
    required this.title,
    required this.initials,
    required this.name,
    required this.driverId,
    required this.vault,
    required this.balance,
    required this.balanceIsStatus,
    required this.balanceLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final balance = this.balance;
    return SafeArea(
      key: const Key('profile-header'),
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: AppTextStyles.display.copyWith(color: palette.title),
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.hairline),
                boxShadow: palette.raisedShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Center(child: _LanyardSlot()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _InitialsTile(initials),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                name,
                                key: const Key('profile-name'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title.copyWith(
                                  color: palette.title,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _Rule(palette),
                        Column(
                          key: const Key('profile-identity'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BadgeField(
                              label: l10n.profileBadgeId,
                              value: driverId,
                            ),
                            _Rule(palette),
                            _BadgeField(
                              label: l10n.profileBadgeVault,
                              value: vault,
                            ),
                          ],
                        ),
                        if (balanceLoading) ...[
                          _Rule(palette),
                          _BadgeField(
                            key: const Key('profile-balance-loading'),
                            label: l10n.profileBadgeBalance,
                            value: '',
                            valueChild: const FleetValueSkeleton(width: 88),
                          ),
                        ] else if (balance != null) ...[
                          _Rule(palette),
                          _BadgeField(
                            key: const Key('profile-balance'),
                            label: l10n.profileBadgeBalance,
                            value: balance,
                            status: balanceIsStatus,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The punched hole a lanyard clip goes through: the ground shows through,
/// shaded along its top cut edge.
class _LanyardSlot extends StatelessWidget {
  const _LanyardSlot();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(palette.insetShade, palette.ground),
              palette.ground,
            ],
            stops: const [0, 0.45],
          ),
        ),
      ),
    );
  }
}

class _InitialsTile extends StatelessWidget {
  final String initials;

  const _InitialsTile(this.initials);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        key: const Key('profile-avatar'),
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.mark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              initials,
              maxLines: 1,
              style: AppTextStyles.title.copyWith(color: palette.onMark),
            ),
          ),
        ),
      ),
    );
  }
}

/// One label and value line of the badge; the value sits at the end in
/// tabular figures and swaps in place when it changes. A [status] value, such
/// as an offline notice, is set quieter so it does not read as data.
class _BadgeField extends StatelessWidget {
  final String label;
  final String value;
  final bool status;
  final Widget? valueChild;

  const _BadgeField({
    super.key,
    required this.label,
    required this.value,
    this.status = false,
    this.valueChild,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flex both sides so long AR labels at large text scales cannot
            // blow past the badge width (text-scale audit @ 1.6 / 320).
            Expanded(
              flex: 2,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: valueChild != null
                  ? Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: valueChild,
                    )
                  : _Swap(
                value: value,
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: status
                      ? AppTextStyles.bodyMedium.copyWith(color: palette.muted)
                      : AppTextStyles.bodyMedium.copyWith(
                          color: palette.title,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppTextStyles.tabular,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final AppPalette palette;

  const _Rule(this.palette);

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: palette.hairline);
  }
}

/// Cross-fades a changed value in place over 180ms without moving its row;
/// with reduced motion the new value replaces the old at once.
class _Swap extends StatelessWidget {
  final Object value;
  final Widget child;

  const _Swap({required this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}

/// Pending-approval count at the end of the Pending Approvals row.
class _PendingCount extends StatelessWidget {
  const _PendingCount();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return BlocBuilder<ApprovalsBloc, ApprovalsState>(
      buildWhen: (previous, current) =>
          previous.pendingCount != current.pendingCount ||
          previous.loading != current.loading,
      builder: (context, state) {
        if (state.loading) {
          return const FleetValueSkeleton(
            key: Key('profile-pending-loading'),
            width: 28,
            height: 22,
          );
        }
        if (state.pendingCount == 0) {
          return const SizedBox.shrink();
        }
        final count = state.pendingCount.toString();
        return _Swap(
          value: count,
          child: Container(
            key: const Key('profile-pending-count'),
            constraints: const BoxConstraints(minWidth: 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.action,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: palette.onAction,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTextStyles.tabular,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 4),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: palette.muted),
        ),
      ),
    );
  }
}

/// Related rows on the ground, divided by hairlines; no card around them.
class _MenuGroup extends StatelessWidget {
  final Key? groupKey;
  final List<Widget> children;

  const _MenuGroup({this.groupKey, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      key: groupKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: palette.hairline,
            ),
          child,
        ],
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final Key rowKey;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;
    return InkWell(
      key: rowKey,
      onTap: onTap,
      highlightColor: palette.title.withValues(alpha: 0.06),
      splashColor: palette.title.withValues(alpha: 0.08),
      focusColor: palette.focus.withValues(alpha: 0.12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: destructive ? palette.error : palette.muted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: destructive ? palette.error : palette.title,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
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
                Icon(chevron, color: palette.muted, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _valueStyle(AppPalette palette) {
  return AppTextStyles.bodyMedium.copyWith(
    color: palette.body,
    fontWeight: FontWeight.w600,
    fontFeatures: AppTextStyles.tabular,
  );
}

/// Theme font with the redesign's button weight, so labels use the app face.
TextStyle? _buttonText(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge
      ?.merge(AppTextStyles.buttonLarge);
}
