import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/app_icons.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/localization/localized_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/activity_row.dart';
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
import '../../../finance/domain/entities/assigned_trip.dart';
import '../../../finance/domain/entities/expense_trip_scope.dart';
import '../../../finance/domain/repositories/expense_repository.dart';
import '../../../finance/presentation/widgets/record_expense_sheet.dart';
import '../../../finance/presentation/widgets/send_cash_sheet.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/domain/latest_history.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../history/presentation/history_format.dart';
import '../../../history/presentation/widgets/expense_detail_sheet.dart';
import '../../../history/presentation/widgets/history_entry_tile.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../domain/entities/financial_summary.dart';
import '../amount_format.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

/// Home tab: a dark wallet plane (balance, limit gauge) above a white
/// activity sheet (the active trip with its own Record Expense; Send Cash and
/// a general Record Expense; pending approvals; recent transactions).
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

/// Status bar icons over the dark wallet plane.
const _lightStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// The other tabs are light and carry no overlay annotation of their own, so
/// the dark icons are restored when this page leaves the tab view.
const _darkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

class _HomePageState extends State<HomePage> {
  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(_darkStatusBar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightStatusBar,
      child: Scaffold(
        key: const Key('home-page'),
        backgroundColor: AppColors.title,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.inkLift, AppColors.title],
              stops: const [0, 0.45],
            ),
          ),
          child: SafeArea(
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
                                return _WalletHeader(
                                  fullName: driver.displayName(locale),
                                  initials: driver.initials(locale),
                                  onNotifications: widget.onOpenNotifications,
                                  onProfile: widget.onOpenProfile,
                                );
                              },
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _WalletPlane(
                              summary: summary,
                              financeStatus: financeStatus,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _ActivitySheet(
                              now: widget.now,
                              driverId: driver.id,
                              trip: trip,
                              onOpenApprovals: widget.onOpenApprovals,
                              onOpenHistory: widget.onOpenHistory,
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Builder(
                              builder: (context) => ColoredBox(
                                color: AppSurfaces.of(context).card,
                              ),
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
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.hint,
                            ),
                          ),
                          TextButton(
                            key: const Key('home-retry'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.read<HomeBloc>().add(
                              const HomeStarted(),
                            ),
                            child: Text(l10n.tryAgain),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                };
              },
            ),
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
    this.color = AppColors.neutralBackground,
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

/// Avatar and "Welcome back!" with the driver's name at the leading edge; the
/// approvals bell alone at the trailing edge.
class _WalletHeader extends StatelessWidget {
  final String fullName;
  final String initials;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  const _WalletHeader({
    required this.fullName,
    required this.initials,
    this.onNotifications,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      initials,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
                  style: const TextStyle(
                    color: AppColors.hint,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  key: const Key('home-driver-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
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
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
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
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.title,
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

class _WalletPlane extends StatelessWidget {
  final FinancialSummary? summary;
  final HomeFinanceStatus financeStatus;

  const _WalletPlane({required this.summary, required this.financeStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (previous, current) =>
          previous.isUnavailable != current.isUnavailable,
      builder: (context, connectivity) {
        if (connectivity.isUnavailable) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
            child: const _OfflineFinancePlaceholder(onDark: true),
          );
        }
        final summary = this.summary;
        final ready =
            financeStatus == HomeFinanceStatus.ready && summary != null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (financeStatus) {
                HomeFinanceStatus.loading => const _WalletLoading(),
                HomeFinanceStatus.ready when summary != null => _WalletFigures(
                  summary: summary,
                ),
                _ => const _WalletError(),
              },
              if (ready) ...[
                const SizedBox(height: 36),
                _LimitGauge(summary: summary),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OfflineFinancePlaceholder extends StatelessWidget {
  final bool onDark;

  const _OfflineFinancePlaceholder({this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = onDark ? AppColors.hint : AppColors.muted;
    return Padding(
      key: const Key('home-offline-finance'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            l10n.offlineSectionUnavailable,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _WalletFigures extends StatelessWidget {
  final FinancialSummary summary;

  const _WalletFigures({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = formatHomeAmount(
      summary.balanceEgp,
      locale: locale,
      withCurrency: false,
      currency: l10n.egp,
    );
    return Column(
      key: const Key('home-finance-card'),
      children: [
        Text(
          l10n.homeAvailableBalance,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.hint,
            fontSize: 14,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: amount),
                const TextSpan(text: ' ', style: TextStyle(letterSpacing: 0)),
                TextSpan(
                  text: l10n.egp,
                  style: const TextStyle(
                    color: AppColors.hint,
                    fontSize: 22,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            key: const Key('home-balance'),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              height: 1.05,
              letterSpacing: -2,
              fontWeight: FontWeight.w800,
              fontFeatures: _tabular,
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletLoading extends StatelessWidget {
  const _WalletLoading();

  @override
  Widget build(BuildContext context) {
    final bar = Colors.white.withValues(alpha: 0.1);
    return Semantics(
      label: AppLocalizations.of(context).loadingBalance,
      child: Column(
        key: const Key('balance-loading'),
        children: [
          _Skeleton(width: 120, height: 14, color: bar),
          const SizedBox(height: 16),
          _Skeleton(width: 220, height: 50, color: bar, radius: 12),
        ],
      ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('balance-error'),
      children: [
        Text(
          l10n.balanceLoadError,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.hint,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          key: const Key('balance-retry'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () =>
              context.read<HomeBloc>().add(const HomeFinanceRetried()),
          child: Text(l10n.tryAgain),
        ),
      ],
    );
  }
}

class _LimitGauge extends StatelessWidget {
  final FinancialSummary summary;

  const _LimitGauge({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
    const label = TextStyle(
      color: AppColors.hint,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                    style: label,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _money(context, remaining),
                      key: const Key('home-remaining'),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.1,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w800,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.maxLimit, maxLines: 1, style: label),
                  const SizedBox(height: 4),
                  Text(
                    _money(context, max),
                    key: const Key('home-max-limit'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                key: const Key('home-charge-progress'),
                value: used,
                minHeight: 10,
                color: AppColors.primaryOnInk,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                semanticsLabel: l10n.homeLimitUsed(percent),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryOnInk,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.charge, maxLines: 1, style: label),
                      ],
                    ),
                    Text(
                      _money(context, summary.chargeEgp),
                      key: const Key('home-charge'),
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.primaryOnInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
                Text(l10n.homeLimitUsed(percent), style: label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySheet extends StatelessWidget {
  final DateTime Function() now;
  final String driverId;
  final AsyncSnapshot<AssignedTrip?> trip;
  final VoidCallback? onOpenApprovals;
  final VoidCallback? onOpenHistory;

  const _ActivitySheet({
    required this.now,
    required this.driverId,
    required this.trip,
    this.onOpenApprovals,
    this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          30,
          20,
          40 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TripSection(driverId: driverId, trip: trip),
            const SizedBox(height: 36),
            _Actions(driverId: driverId, onOpenHistory: onOpenHistory),
            const SizedBox(height: 36),
            _PendingSection(onOpen: onOpenApprovals),
            const SizedBox(height: 36),
            _RecentSection(now: now, onSeeAll: onOpenHistory),
          ],
        ),
      ),
    );
  }
}

/// The trip panel: route, trip facts, and the trip's own Record Expense
/// action, grouped on one lavender surface.
class _TripSection extends StatelessWidget {
  final String driverId;
  final AsyncSnapshot<AssignedTrip?> trip;

  const _TripSection({required this.driverId, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final surfaces = AppSurfaces.of(context);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaces.panel,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (offline)
                          const _OfflineFinancePlaceholder()
                        else if (loading)
                          _Skeleton(
                            width: double.infinity,
                            height: 64,
                            color: surfaces.card,
                          )
                        else if (active == null)
                          _NoTrip(l10n: l10n)
                        else
                          _Journey(trip: active),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const Key('trip-record-expense'),
                          onPressed: canRecord && activeTripId != null
                              ? () => showRecordExpenseSheet(
                                  context,
                                  driverId: driverId,
                                  tripId: activeTripId,
                                )
                              : locked
                              ? () => _showOfflineActionNotice(context)
                              : null,
                          icon: Icon(
                            // Keep the action icon when offline-locked; only
                            // the online "no trip" disabled state uses a lock.
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
                                ? surfaces.neutral
                                : surfaces.title,
                            foregroundColor: locked
                                ? surfaces.muted
                                : surfaces.card,
                            disabledBackgroundColor: surfaces.card,
                            disabledForegroundColor: surfaces.body,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

void _showComingSoonNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('action-coming-soon-notice'),
      content: Text(l10n.actionComingSoon),
    ),
  );
}

/// General actions. This Record Expense is not tied to the active trip: the
/// driver selects any of their trips in the sheet, including completed ones.
/// Request Cash and Withdraw are UI entry points only until their flows are
/// defined.
class _Actions extends StatelessWidget {
  final String driverId;
  final VoidCallback? onOpenHistory;

  const _Actions({required this.driverId, this.onOpenHistory});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    const label = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const padding = EdgeInsets.symmetric(horizontal: 12);
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

        final filledStyle = FilledButton.styleFrom(
          backgroundColor: locked ? surfaces.neutral : AppColors.primary,
          foregroundColor: locked ? surfaces.muted : Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: padding,
          textStyle: label,
          shape: shape,
        );
        final outlinedStyle = OutlinedButton.styleFrom(
          foregroundColor: locked ? surfaces.muted : surfaces.title,
          backgroundColor: locked ? surfaces.neutral : surfaces.card,
          side: BorderSide(color: surfaces.border),
          minimumSize: const Size.fromHeight(54),
          padding: padding,
          textStyle: label,
          shape: shape,
        );

        return Column(
          key: const Key('home-actions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title: l10n.homeActions),
            const SizedBox(height: 14),
            DecoratedBox(
              key: const Key('home-actions-panel'),
              decoration: BoxDecoration(
                color: surfaces.panel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const Key('send-cash'),
                            onPressed: gated(
                              () => showSendCashSheet(
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
                            icon: const Icon(
                              Icons.north_east_rounded,
                              size: 20,
                            ),
                            label: _FitLabel(l10n.sendCash),
                            style: filledStyle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('record-expense'),
                            onPressed: gated(
                              () => showRecordExpenseSheet(
                                context,
                                driverId: driverId,
                                tripScope: ExpenseTripScope.anyTrip,
                              ),
                            ),
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              size: 20,
                            ),
                            label: _FitLabel(l10n.recordExpense),
                            style: outlinedStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('request-cash'),
                            onPressed: gated(
                              () => _showComingSoonNotice(context),
                            ),
                            icon: const Icon(
                              Icons.south_west_rounded,
                              size: 20,
                            ),
                            label: _FitLabel(l10n.requestCash),
                            style: outlinedStyle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('withdraw'),
                            onPressed: gated(
                              () => _showComingSoonNotice(context),
                            ),
                            icon: const Icon(
                              Icons.account_balance_outlined,
                              size: 20,
                            ),
                            label: _FitLabel(l10n.withdraw),
                            style: outlinedStyle,
                          ),
                        ),
                      ],
                    ),
                    if (offline) ...[
                      const SizedBox(height: 12),
                      Text(
                        key: const Key('home-offline-actions-hint'),
                        l10n.offlineActionRequiresInternet,
                        style: AppTextStyles.caption,
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

/// One line that scales down rather than truncating in a half-width button.
class _FitLabel extends StatelessWidget {
  final String text;

  const _FitLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, softWrap: false),
    );
  }
}

class _Journey extends StatelessWidget {
  final AssignedTrip trip;

  const _Journey({required this.trip});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    const place = TextStyle(
      color: AppColors.title,
      fontSize: 22,
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
        const SizedBox(height: 16),
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
    final rail = AppColors.primary.withValues(alpha: 0.35);
    Widget dot(Color color) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return SizedBox(
      width: 72,
      child: Row(
        children: [
          dot(AppColors.primary),
          Expanded(child: Container(height: 2, color: rail)),
          Container(
            key: const Key('home-trip-arrow'),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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
          dot(AppColors.title),
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
            style: TextStyle(
              color: strong
                  ? AppSurfaces.of(context).title
                  : AppSurfaces.of(context).body,
              fontSize: 13.5,
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
    final surfaces = AppSurfaces.of(context);
    return Row(
      key: const Key('home-no-trip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeAvatar.asset(AppIcons.bus, tint: surfaces.card, opacity: 0.55),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeNoActiveTrip,
                style: TextStyle(
                  color: surfaces.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeNoActiveTripHint,
                style: TextStyle(
                  color: surfaces.body,
                  fontSize: 13.5,
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
    return BlocListener<ApprovalsBloc, ApprovalsState>(
      listenWhen: (previous, current) => current.revision != previous.revision,
      listener: (context, state) {
        context.read<HomeBloc>().add(const HomeSummaryRefreshed());
      },
      child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        buildWhen: (previous, current) =>
            previous.isUnavailable != current.isUnavailable,
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
                            foreground: AppColors.pendingText,
                            background: AppColors.warningBackground,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  if (offline)
                    const _OfflineFinancePlaceholder()
                  else if (state.loading)
                    const _RowsLoading(rows: 2)
                  else if (pending.isEmpty)
                    const _AllCaughtUp()
                  else ...[
                    for (final item in pending)
                      _PendingRow(item: item, onTap: onOpen),
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
    return Padding(
      key: const Key('home-all-caught-up'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const TypeAvatar(
            tint: AppColors.successBackground,
            child: Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeAllCaughtUp,
                  style: TextStyle(
                    color: AppSurfaces.of(context).title,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.noPendingApprovals,
                  style: TextStyle(
                    color: AppSurfaces.of(context).body,
                    fontSize: 13.5,
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
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _Skeleton(width: 46, height: 46, radius: 23),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Skeleton(width: 150, height: 13),
                      SizedBox(height: 8),
                      _Skeleton(width: 96, height: 11),
                    ],
                  ),
                ),
                _Skeleton(width: 70, height: 13),
              ],
            ),
          ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  final ApprovalItem item;
  final VoidCallback? onTap;

  const _PendingRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final (title, source, asset, tint) = switch (item.kind) {
      ApprovalKind.vault => (
        l10n.receivedFromVault,
        l10n.driversVault,
        AppIcons.vault,
        AppColors.warningBackground,
      ),
      ApprovalKind.driver => (
        l10n.receivedFromDriver(item.counterpartyName.tr(l10n)),
        item.counterpartyId,
        AppIcons.person,
        AppColors.successBackground,
      ),
      ApprovalKind.roadExpense => (
        l10n.roadExpenseApproval,
        item.reference,
        AppIcons.invoice,
        AppColors.primarySurface,
      ),
    };
    final when = item.kind == ApprovalKind.roadExpense
        ? approvalClock(item.occurredAt, locale)
        : cardRecency(l10n, item);
    return InkWell(
      key: Key('home-pending-${item.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ActivityRow(
          avatar: TypeAvatar.asset(asset, tint: tint),
          title: title,
          subtitle: '$source · ${l10n.filterPending}',
          subtitleColor: AppColors.pendingText,
          amount: signedApprovalAmount(
            item.amountEgp,
            locale: locale,
            currency: l10n.egp,
          ),
          amountColor: AppColors.title,
          when: when,
        ),
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
                  const SizedBox(height: 6),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    for (final entry in latest)
                      HistoryEntryTile(
                        entry: entry,
                        keyPrefix: 'home-recent',
                        when: recentWhenLabel(
                          l10n,
                          entry.occurredAt,
                          now(),
                          locale,
                        ),
                        onTap: entry.kind == HistoryKind.expense
                            ? () =>
                                  showExpenseDetailSheet(context, entry: entry)
                            : null,
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
