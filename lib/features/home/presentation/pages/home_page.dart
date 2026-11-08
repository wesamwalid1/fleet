import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/app_icons.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/text_link.dart';
import '../../../../core/widgets/type_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approvals/domain/entities/approval_item.dart';
import '../../../approvals/domain/latest_pending_approvals.dart';
import '../../../approvals/presentation/approval_format.dart';
import '../../../approvals/presentation/bloc/approvals_bloc.dart';
import '../../../approvals/presentation/bloc/approvals_state.dart';
import '../../../approvals/presentation/widgets/approval_inbox_row.dart';
import '../../../approvals/presentation/widgets/approval_inline_actions.dart';
import '../../../finance/domain/entities/assigned_trip.dart';
import '../../../finance/domain/entities/expense_trip_scope.dart';
import '../../../finance/domain/repositories/expense_repository.dart';
import '../../../finance/presentation/pages/record_expense_flow_page.dart';
import '../../../finance/presentation/widgets/request_cash_sheet.dart';
import '../../../finance/presentation/pages/send_cash_flow_page.dart';
import '../../../finance/presentation/widgets/withdraw_cash_sheet.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/domain/latest_history.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../history/presentation/history_format.dart';
import '../../../approvals/presentation/widgets/approval_sheets.dart';
import '../../../history/presentation/widgets/history_ledger_row.dart';
import '../../../history/presentation/widgets/transaction_detail_sheet.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../domain/entities/financial_summary.dart';
import '../amount_format.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

/// Home tab: balance and limit, active trip, actions, pending approvals, and
/// recent transactions — one shared surface language across Light and Dark.
class HomePage extends StatefulWidget {
  final DateTime Function() now;
  final VoidCallback? onOpenApprovals;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;

  const HomePage({
    super.key,
    required this.now,
    this.onOpenApprovals,
    this.onOpenHistory,
    this.onOpenProfile,
    this.onOpenNotifications,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemBars,
      child: Scaffold(
        key: const Key('home-page'),
        backgroundColor: palette.ground,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return switch (state) {
                HomeReady(
                  :final driver,
                  :final summary,
                  :final financeStatus,
                ) =>
                  _TripLoader(
                    driverId: driver.id,
                    builder: (context, trip) => CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Builder(
                            builder: (context) {
                              final locale = Localizations.localeOf(context);
                              return _HomeHeader(
                                fullName: driver.displayName(locale),
                                initials: driver.initials(locale),
                                onNotifications: widget.onOpenNotifications,
                                onProfile: widget.onOpenProfile,
                              );
                            },
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _BalanceSection(
                            summary: summary,
                            financeStatus: financeStatus,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HomeBody(
                            now: widget.now,
                            driverId: driver.id,
                            trip: trip,
                            onOpenApprovals: widget.onOpenApprovals,
                            onOpenHistory: widget.onOpenHistory,
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ColoredBox(color: palette.ground),
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
                          style: AppTextStyles.body.copyWith(
                            color: palette.body,
                          ),
                        ),
                        TextButton(
                          key: const Key('home-retry'),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.action,
                          ),
                          onPressed: () =>
                              context.read<HomeBloc>().add(const HomeStarted()),
                          child: Text(l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                ),
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
      ),
    );
  }
}

const _tabular = AppTextStyles.tabular;

String _money(BuildContext context, int amountEgp) {
  return formatHomeAmount(
    amountEgp,
    locale: Localizations.localeOf(context).toString(),
    withCurrency: true,
    currency: AppLocalizations.of(context).egp,
  );
}

/// Loads the driver's trips once and hands the active one (or null) to the
/// trip section.
class _TripLoader extends StatefulWidget {
  final String driverId;
  final Widget Function(BuildContext context, AsyncSnapshot<AssignedTrip?>)
  builder;

  const _TripLoader({required this.driverId, required this.builder});

  @override
  State<_TripLoader> createState() => _TripLoaderState();
}

class _TripLoaderState extends State<_TripLoader> {
  late Future<AssignedTrip?> _active;

  @override
  void initState() {
    super.initState();
    _active = _load();
  }

  @override
  void didUpdateWidget(_TripLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverId != widget.driverId) _active = _load();
  }

  Future<AssignedTrip?> _load() async {
    final trips = await context.read<ExpenseRepository>().getAssignedTrips(
      widget.driverId,
    );
    for (final trip in trips) {
      if (trip.status == TripStatus.active) return trip;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssignedTrip?>(
      future: _active,
      builder: widget.builder,
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double radius;

  const _Skeleton({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String fullName;
  final String initials;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  const _HomeHeader({
    required this.fullName,
    required this.initials,
    this.onNotifications,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.navProfile,
            child: InkResponse(
              key: const Key('home-avatar'),
              onTap: onProfile,
              radius: 26,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.hairline, width: 1.5),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      initials,
                      maxLines: 1,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              key: const Key('home-header-identity'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeBack,
                  key: const Key('home-welcome'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  key: const Key('home-driver-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    color: palette.title,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: l10n.notifications,
            child: InkResponse(
              key: const Key('home-notifications'),
              onTap: onNotifications,
              radius: 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: palette.title,
                      size: 26,
                    ),
                    BlocBuilder<NotificationsBloc, NotificationsState>(
                      buildWhen: (previous, current) =>
                          previous.hasUnread != current.hasUnread,
                      builder: (context, state) {
                        if (!state.hasUnread) return const SizedBox.shrink();
                        return PositionedDirectional(
                          top: 11,
                          end: 12,
                          child: Container(
                            key: const Key('home-notification-dot'),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: palette.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.ground,
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final FinancialSummary? summary;
  final HomeFinanceStatus financeStatus;

  const _BalanceSection({required this.summary, required this.financeStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (previous, current) =>
          previous.isUnavailable != current.isUnavailable,
      builder: (context, connectivity) {
        if (connectivity.isUnavailable) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: _OfflineFinancePlaceholder(),
          );
        }
        final summary = this.summary;
        final ready =
            financeStatus == HomeFinanceStatus.ready && summary != null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (financeStatus) {
                HomeFinanceStatus.loading => const _BalanceLoading(),
                HomeFinanceStatus.ready when summary != null => _BalanceFigures(
                  summary: summary,
                ),
                _ => const _BalanceError(),
              },
              if (ready) ...[
                const SizedBox(height: 12),
                _LimitMeter(summary: summary),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OfflineFinancePlaceholder extends StatelessWidget {
  const _OfflineFinancePlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Padding(
      key: const Key('home-offline-finance'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: palette.muted, size: 28),
          const SizedBox(height: 10),
          Text(
            l10n.offlineSectionUnavailable,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _BalanceFigures extends StatelessWidget {
  final FinancialSummary summary;

  const _BalanceFigures({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = formatHomeAmount(
      summary.totalBalanceEgp,
      locale: locale,
      withCurrency: false,
      currency: l10n.egp,
    );
    return DecoratedBox(
      key: const Key('home-finance-card'),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: [
            Text(
              l10n.homeTotalBalance,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: amount),
                    const TextSpan(
                      text: ' ',
                      style: TextStyle(letterSpacing: 0),
                    ),
                    TextSpan(
                      text: l10n.egp,
                      style: AppTextStyles.title.copyWith(
                        color: palette.muted,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                key: const Key('home-total-balance'),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.display.copyWith(
                  color: palette.title,
                  fontSize: 44,
                  height: 1.05,
                  letterSpacing: -1.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BalanceSubFigure(
                    label: l10n.homeAvailableBalance,
                    value: _money(context, summary.availableBalanceEgp),
                    valueKey: const Key('home-balance'),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BalanceSubFigure(
                    label: l10n.homeFrozenBalance,
                    value: _money(context, summary.frozenBalanceEgp),
                    valueKey: const Key('home-frozen-balance'),
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSubFigure extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  final IconData icon;

  const _BalanceSubFigure({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: palette.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: palette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            key: valueKey,
            maxLines: 1,
            style: AppTextStyles.brand.copyWith(
              color: palette.title,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontFeatures: _tabular,
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceLoading extends StatelessWidget {
  const _BalanceLoading();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bar = palette.hairline;
    return Semantics(
      label: AppLocalizations.of(context).loadingBalance,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
          child: Column(
            key: const Key('balance-loading'),
            children: [
              _Skeleton(width: 120, height: 14, color: bar),
              const SizedBox(height: 16),
              _Skeleton(width: 220, height: 44, color: bar, radius: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceError extends StatelessWidget {
  const _BalanceError();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Column(
      key: const Key('balance-error'),
      children: [
        Text(
          l10n.balanceLoadError,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: palette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          key: const Key('balance-retry'),
          style: TextButton.styleFrom(foregroundColor: palette.action),
          onPressed: () =>
              context.read<HomeBloc>().add(const HomeFinanceRetried()),
          child: Text(l10n.tryAgain),
        ),
      ],
    );
  }
}

/// Compact Max Limit meter. Remaining = Max − Charge (not request capacity).
class _LimitMeter extends StatelessWidget {
  final FinancialSummary summary;

  const _LimitMeter({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final max = summary.maxLimitEgp;
    final used = max <= 0 ? 0.0 : (summary.chargeEgp / max).clamp(0.0, 1.0);
    final remaining = (max - summary.chargeEgp).clamp(0, max);
    final percent = formatHomeAmount(
      (used * 100).round(),
      locale: locale,
      withCurrency: false,
      currency: l10n.egp,
    );
    final labelStyle = AppTextStyles.caption.copyWith(
      color: palette.muted,
      fontWeight: FontWeight.w600,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SplitRow(
              crossAxisAlignment: CrossAxisAlignment.end,
              maxFraction: 0.45,
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeRemainingLimit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _money(context, remaining),
                      key: const Key('home-remaining'),
                      maxLines: 1,
                      style: AppTextStyles.title.copyWith(
                        color: palette.title,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.3,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.maxLimit, maxLines: 1, style: labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    _money(context, max),
                    key: const Key('home-max-limit'),
                    maxLines: 1,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: palette.title,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('home-charge-progress'),
                value: used,
                minHeight: 6,
                color: palette.action,
                backgroundColor: palette.hairline,
                semanticsLabel: l10n.homeLimitUsed(percent),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.charge, maxLines: 1, style: labelStyle),
                    Text(
                      _money(context, summary.chargeEgp),
                      key: const Key('home-charge'),
                      maxLines: 1,
                      style: AppTextStyles.body.copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
                Text(l10n.homeLimitUsed(percent), style: labelStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final DateTime Function() now;
  final String driverId;
  final AsyncSnapshot<AssignedTrip?> trip;
  final VoidCallback? onOpenApprovals;
  final VoidCallback? onOpenHistory;

  const _HomeBody({
    required this.now,
    required this.driverId,
    required this.trip,
    this.onOpenApprovals,
    this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        40 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TripSection(driverId: driverId, trip: trip),
          const SizedBox(height: 28),
          _Actions(driverId: driverId, onOpenHistory: onOpenHistory),
          const SizedBox(height: 28),
          _PendingSection(onOpen: onOpenApprovals),
          const SizedBox(height: 28),
          _RecentSection(now: now, onSeeAll: onOpenHistory),
        ],
      ),
    );
  }
}

/// The trip panel: route, trip facts, and the trip's own Record Expense
/// action, grouped on one surface.
class _TripSection extends StatelessWidget {
  final String driverId;
  final AsyncSnapshot<AssignedTrip?> trip;

  const _TripSection({required this.driverId, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (previous, current) =>
          previous.isUnavailable != current.isUnavailable ||
          previous.blocksOnlineWork != current.blocksOnlineWork,
      builder: (context, connectivity) {
        final offline = connectivity.isUnavailable;
        final locked = connectivity.blocksOnlineWork;
        final loading = trip.connectionState != ConnectionState.done;
        final active = offline ? null : trip.data;
        final canRecord = !locked && !loading && active != null;
        final activeTripId = active?.id;
        return Column(
          key: const Key('home-trip-card'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              title: l10n.homeActiveTrip,
              trailing: active == null
                  ? null
                  : StatusBadge(
                      label: l10n.tripActive,
                      foreground: AppColors.creditText,
                      background: AppColors.successBackground,
                      leading: const SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (offline)
                      const _OfflineFinancePlaceholder()
                    else if (loading)
                      _Skeleton(
                        width: double.infinity,
                        height: 64,
                        color: palette.hairline,
                      )
                    else if (active == null)
                      _NoTrip(l10n: l10n)
                    else
                      _Journey(trip: active),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('trip-record-expense'),
                      onPressed: canRecord && activeTripId != null
                          ? () => openRecordExpenseFlow(
                              context,
                              driverId: driverId,
                              tripId: activeTripId,
                            )
                          : locked
                          ? () => _showOfflineActionNotice(context)
                          : null,
                      icon: Icon(
                        canRecord || locked
                            ? Icons.receipt_long_rounded
                            : Icons.lock_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        l10n.recordExpense,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: locked
                            ? palette.hairline
                            : palette.action,
                        foregroundColor: locked
                            ? palette.muted
                            : palette.onAction,
                        disabledBackgroundColor: palette.field,
                        disabledForegroundColor: palette.muted,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _showOfflineActionNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
}

/// General actions. This Record Expense is not tied to the active trip: the
/// driver selects any of their trips in the sheet, including completed ones.
class _Actions extends StatelessWidget {
  final String driverId;
  final VoidCallback? onOpenHistory;

  const _Actions({required this.driverId, this.onOpenHistory});

  static const _iconSize = 18.0;
  static const _gap = 10.0;
  static const _buttonHeight = 52.0;
  static const _radius = 14.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 10);

  /// Shared across Send Cash / Request Cash / Withdraw.
  static final _labelStyle = AppTextStyles.buttonLarge.copyWith(
    fontSize: 13.5,
    height: 1.15,
    fontWeight: FontWeight.w600,
  );

  /// Slightly smaller so Record Expense stays on one line without shrinking peers.
  static final _recordExpenseLabelStyle = AppTextStyles.buttonLarge.copyWith(
    fontSize: 12.5,
    height: 1.15,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (previous, current) =>
          previous.isUnavailable != current.isUnavailable ||
          previous.blocksOnlineWork != current.blocksOnlineWork,
      builder: (context, connectivity) {
        final offline = connectivity.isUnavailable;
        final locked = connectivity.blocksOnlineWork;
        VoidCallback gated(VoidCallback onlineAction) {
          return locked
              ? () => _showOfflineActionNotice(context)
              : onlineAction;
        }

        final actionStyle = OutlinedButton.styleFrom(
          foregroundColor: locked ? palette.muted : palette.title,
          backgroundColor: locked ? palette.hairline : palette.surface,
          disabledForegroundColor: palette.muted,
          side: BorderSide(
            color: locked ? palette.hairline : palette.fieldBorder,
          ),
          minimumSize: const Size.fromHeight(_buttonHeight),
          padding: _padding,
          textStyle: _labelStyle,
          shape: shape,
        );

        Widget icon(IconData data) => Icon(data, size: _iconSize);

        return Column(
          key: const Key('home-actions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title: l10n.homeActions),
            const SizedBox(height: 12),
            DecoratedBox(
              key: const Key('home-actions-panel'),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('send-cash'),
                            onPressed: gated(
                              () => openSendCashFlow(
                                context,
                                senderId: driverId,
                                onViewTransaction: (transferId) {
                                  context.read<HistoryBloc>().add(
                                    HistoryEntryHighlighted(transferId),
                                  );
                                  onOpenHistory?.call();
                                },
                              ),
                            ),
                            icon: icon(Icons.north_east_rounded),
                            label: _ActionLabel(l10n.sendCash),
                            style: actionStyle,
                          ),
                        ),
                        const SizedBox(width: _gap),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('record-expense'),
                            onPressed: gated(
                              () => openRecordExpenseFlow(
                                context,
                                driverId: driverId,
                                tripScope: ExpenseTripScope.anyTrip,
                              ),
                            ),
                            icon: icon(Icons.receipt_long_rounded),
                            label: _ActionLabel(
                              l10n.recordExpense,
                              style: _Actions._recordExpenseLabelStyle,
                            ),
                            style: actionStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _gap),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('request-cash'),
                            onPressed: gated(
                              () => showRequestCashSheet(
                                context,
                                driverId: driverId,
                                onViewTransaction: (requestId) {
                                  context.read<HistoryBloc>().add(
                                    HistoryEntryHighlighted(requestId),
                                  );
                                  onOpenHistory?.call();
                                },
                              ),
                            ),
                            icon: icon(Icons.south_west_rounded),
                            label: _ActionLabel(l10n.requestCash),
                            style: actionStyle,
                          ),
                        ),
                        const SizedBox(width: _gap),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('withdraw'),
                            onPressed: gated(
                              () => showWithdrawCashSheet(
                                context,
                                driverId: driverId,
                                onViewTransaction: (requestId) {
                                  context.read<HistoryBloc>().add(
                                    HistoryEntryHighlighted(requestId),
                                  );
                                  onOpenHistory?.call();
                                },
                              ),
                            ),
                            icon: icon(Icons.account_balance_outlined),
                            label: _ActionLabel(l10n.withdraw),
                            style: actionStyle,
                          ),
                        ),
                      ],
                    ),
                    if (offline) ...[
                      const SizedBox(height: 12),
                      Text(
                        key: const Key('home-offline-actions-hint'),
                        l10n.offlineActionRequiresInternet,
                        style: AppTextStyles.caption.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shared action label. Record Expense may pass a slightly smaller [style].
class _ActionLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _ActionLabel(this.text, {this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: style ?? _Actions._labelStyle,
    );
  }
}

class _Journey extends StatelessWidget {
  final AssignedTrip trip;

  const _Journey({required this.trip});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final palette = AppPalette.of(context);
    final place = AppTextStyles.title.copyWith(
      color: palette.title,
      fontSize: 20,
      height: 1.15,
      letterSpacing: -0.3,
      fontWeight: FontWeight.w800,
    );
    return Column(
      key: const Key('home-trip-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trip.origin.resolve(locale),
                key: const Key('home-trip-origin'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: place,
              ),
            ),
            const SizedBox(width: 10),
            const _RouteLine(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                trip.destination.resolve(locale),
                key: const Key('home-trip-destination'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: place,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _Fact(
              factKey: const Key('home-trip-code'),
              asset: AppIcons.hashtag,
              text: trip.code,
              strong: true,
            ),
            _Fact(
              asset: AppIcons.calendar,
              text: approvalDay(trip.date, locale),
            ),
            _Fact(asset: AppIcons.bus, text: trip.vehicle),
          ],
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final rail = palette.hairline;
    Widget dot(Color color) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return SizedBox(
      width: 72,
      child: Row(
        children: [
          dot(palette.action),
          Expanded(child: Container(height: 2, color: rail)),
          Container(
            key: const Key('home-trip-arrow'),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.field,
              shape: BoxShape.circle,
              border: Border.all(color: palette.hairline),
            ),
            child: Image.asset(
              AppIcons.bus,
              width: 18,
              height: 18,
              matchTextDirection: true,
              excludeFromSemantics: true,
            ),
          ),
          Expanded(child: Container(height: 2, color: rail)),
          dot(palette.title),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final Key? factKey;
  final String asset;
  final String text;
  final bool strong;

  const _Fact({
    this.factKey,
    required this.asset,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      key: factKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(asset, width: 16, height: 16, excludeFromSemantics: true),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: strong ? palette.title : palette.body,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: _tabular,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoTrip extends StatelessWidget {
  final AppLocalizations l10n;

  const _NoTrip({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      key: const Key('home-no-trip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeAvatar.asset(AppIcons.bus, tint: palette.field, opacity: 0.9),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeNoActiveTrip,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: palette.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeNoActiveTripHint,
                style: AppTextStyles.body.copyWith(
                  color: palette.body,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _pendingLimit = 2;

class _PendingSection extends StatelessWidget {
  final VoidCallback? onOpen;

  const _PendingSection({this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HomeBloc>().add(const HomeSummaryRefreshed());
      },
      child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        buildWhen: (previous, current) =>
            previous.isUnavailable != current.isUnavailable ||
            previous.blocksOnlineWork != current.blocksOnlineWork,
        builder: (context, connectivity) {
          return BlocBuilder<ApprovalsBloc, ApprovalsState>(
            builder: (context, state) {
              final offline = connectivity.isUnavailable;
              final pending = offline
                  ? const <ApprovalItem>[]
                  : latestPendingApprovals(state.items, limit: _pendingLimit);
              final count = offline ? 0 : state.pendingCount;
              return Column(
                key: const Key('home-pending-card'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    title: l10n.pendingApprovals,
                    trailing: count > 0
                        ? StatusBadge(
                            key: const Key('home-pending-count'),
                            label: l10n.pendingCount(count),
                            foreground: palette.muted,
                            background: palette.field,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (offline)
                    const _OfflineFinancePlaceholder()
                  else if (state.loading)
                    const _RowsLoading(rows: 2)
                  else if (pending.isEmpty)
                    const _AllCaughtUp()
                  else ...[
                    for (final item in pending)
                      _PendingRow(
                        item: item,
                        busy: state.busy,
                        actionsLocked: connectivity.blocksOnlineWork,
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextLink(
                        key: const Key('home-view-all-approvals'),
                        label: l10n.homeViewAllApprovals,
                        onPressed: onOpen,
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Padding(
      key: const Key('home-all-caught-up'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const ApprovalKindMark(ApprovalMarkState.approved, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeAllCaughtUp,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: palette.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.noPendingApprovals,
                  style: AppTextStyles.body.copyWith(
                    color: palette.body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowsLoading extends StatelessWidget {
  final int rows;

  const _RowsLoading({required this.rows});

  @override
  Widget build(BuildContext context) {
    final bar = AppPalette.of(context).hairline;
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _Skeleton(width: 22, height: 22, radius: 11, color: bar),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Skeleton(width: 150, height: 13, color: bar),
                      const SizedBox(height: 8),
                      _Skeleton(width: 96, height: 11, color: bar),
                    ],
                  ),
                ),
                _Skeleton(width: 70, height: 13, color: bar),
              ],
            ),
          ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  final ApprovalItem item;
  final bool busy;
  final bool actionsLocked;

  const _PendingRow({
    required this.item,
    required this.busy,
    required this.actionsLocked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final title = approvalTitle(l10n, item);
    final source = approvalSource(l10n, item);
    final when = item.kind == ApprovalKind.roadExpense
        ? approvalClock(item.occurredAt, locale)
        : cardRecency(l10n, item);
    final amount = approvalAmount(
      item.amountEgp,
      locale: locale,
      currency: l10n.egp,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('home-pending-${item.id}'),
              onTap: busy
                  ? null
                  : () {
                      if (actionsLocked) {
                        _showOfflineActionNotice(context);
                        return;
                      }
                      openApprovalRequest(context, item);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: ApprovalKindMark(ApprovalMarkState.pending),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: palette.title,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$source · ${l10n.filterPending}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: palette.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            when,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              amount,
                              maxLines: 1,
                              softWrap: false,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: palette.title,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                fontFeatures: _tabular,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.filterPending,
                            style: AppTextStyles.caption.copyWith(
                              color: palette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ApprovalInlineActions(
            item: item,
            enabled: !busy && !actionsLocked,
            busy: busy,
            keyPrefix: 'home-pending',
          ),
        ],
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  final DateTime Function() now;
  final VoidCallback? onSeeAll;

  const _RecentSection({required this.now, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HistoryBloc>().add(const HistoryStarted());
      },
      child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        buildWhen: (previous, current) =>
            previous.isUnavailable != current.isUnavailable,
        builder: (context, connectivity) {
          return BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              final offline = connectivity.isUnavailable;
              final latest = offline
                  ? const <HistoryEntry>[]
                  : latestHistoryEntries(state.entries);
              final locale = Localizations.localeOf(context).toString();
              return Column(
                key: const Key('home-recent-card'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    title: l10n.homeRecentTransactions,
                    trailing: TextLink(
                      key: const Key('home-recent-see-all'),
                      label: l10n.seeAll,
                      onPressed: onSeeAll,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (offline)
                    const _OfflineFinancePlaceholder()
                  else if (state.loading && state.entries.isEmpty)
                    const _RowsLoading(rows: 3)
                  else if (latest.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.noTransactions,
                        key: const Key('home-recent-empty'),
                        style: AppTextStyles.body.copyWith(
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    for (var index = 0; index < latest.length; index++)
                      HistoryLedgerRow(
                        entry: latest[index],
                        keyPrefix: 'home-recent',
                        showDivider: index < latest.length - 1,
                        when: recentWhenLabel(
                          l10n,
                          latest[index].occurredAt,
                          now(),
                          locale,
                        ),
                        onTap: () => showTransactionDetailSheet(
                          context,
                          entry: latest[index],
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
