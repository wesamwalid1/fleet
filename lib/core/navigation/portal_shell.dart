import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/approvals/domain/repositories/approval_repository.dart';
import '../../features/approvals/presentation/bloc/approvals_bloc.dart';
import '../../features/approvals/presentation/bloc/approvals_event.dart';
import '../../features/approvals/presentation/pages/approvals_page.dart';
import '../../features/approvals/presentation/widgets/approval_sheets.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/bloc/history_event.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/notifications/domain/entities/notification_destination.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';
import '../../features/notifications/domain/usecases/resolve_notification_destination.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/bloc/notifications_event.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../l10n/app_localizations.dart';
import '../connectivity/domain/network_status.dart';
import '../connectivity/presentation/bloc/connectivity_bloc.dart';
import '../connectivity/presentation/bloc/connectivity_event.dart';
import '../connectivity/presentation/bloc/connectivity_state.dart';
import '../connectivity/presentation/widgets/offline_banner.dart';
import '../haptics/haptics_helper.dart';
import '../theme/app_surfaces.dart';
import 'widgets/portal_bottom_nav.dart';

class PortalShell extends StatefulWidget {
  final DateTime Function() now;
  const PortalShell({super.key, required this.now});

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  static const _tabCount = 4;
  static const _swipeDuration = Duration(milliseconds: 280);
  static const _dragSlop = 18.0;
  static const _flingVelocity = 700.0;

  final PageController _controller = PageController();
  late final List<ScrollController> _tabScrolls = List.generate(
    _tabCount,
    (_) => ScrollController(),
  );
  int _index = 0;
  bool _swipeEnabled = true;

  int? _pointer;
  double _dx = 0;
  double _dy = 0;
  double _origin = 0;
  Duration _downAt = Duration.zero;
  Duration _upAt = Duration.zero;
  bool _decided = false;
  bool _horizontal = false;
  bool _claimed = false;
  bool _moved = false;
  bool _released = false;
  bool _applyScheduled = false;

  /// True after a confirmed offline/unreachable period; cleared on refresh.
  bool _needsReconnectRefresh = false;

  @override
  void dispose() {
    for (final scroller in _tabScrolls) {
      scroller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 || index >= _tabCount) return;
    if (index == _index) {
      _scrollTabToTop(index);
      return;
    }
    if (!_controller.hasClients) return;
    HapticsHelper.selection();
    _controller.jumpToPage(index);
  }

  void _scrollTabToTop(int index) {
    final scroller = _tabScrolls[index];
    if (!scroller.hasClients) return;
    final offset = scroller.offset;
    if (offset <= 0) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      scroller.jumpTo(0);
      return;
    }
    scroller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (!mounted || index == _index) return;
    setState(() => _index = index);
  }

  /// Pushed above the shell, so the shell's providers are handed over.
  void _openNotifications() {
    final notifications = context.read<NotificationsBloc>();
    final connectivity = context.read<ConnectivityBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: notifications),
            BlocProvider.value(value: connectivity),
          ],
          child: NotificationsPage(now: widget.now, onOpen: _openNotification),
        ),
      ),
    );
  }

  bool _openingNotification = false;

  /// Persists the read state first, then leads to the notification's record.
  /// Reading never changes the underlying transaction or approval.
  Future<void> _openNotification(AppNotification notification) async {
    if (_openingNotification) return;
    _openingNotification = true;
    try {
      final notifications = context.read<NotificationRepository>();
      final resolve = ResolveNotificationDestination(
        approvals: context.read<ApprovalRepository>(),
        history: context.read<HistoryRepository>(),
      );
      final history = context.read<HistoryBloc>();
      final navigator = Navigator.of(context);
      final shellRoute = ModalRoute.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final l10n = AppLocalizations.of(context);

      await MarkNotificationRead(notifications)(
        driverId: notification.driverId,
        id: notification.id,
      );
      final destination = await resolve(notification);
      if (!mounted) return;
      // Back to this shell, not to the navigator's first route: routes below
      // the shell are outside the signed-in session.
      navigator.popUntil((route) => route == shellRoute || route.isFirst);

      switch (destination) {
        case OpenApprovalRequest(:final item):
          _select(1);
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          unawaited(openApprovalRequest(context, item));
        case ShowHistoryEntry(:final entryId, :final alreadyHandled):
          history.add(HistoryEntryHighlighted(entryId));
          _select(2);
          if (alreadyHandled) {
            _notice(messenger, l10n.notificationRequestHandled);
          }
        case ShowTabFallback(:final tab):
          _select(tab == NotificationTab.approvals ? 1 : 2);
          _notice(messenger, l10n.notificationTargetUnavailable);
      }
    } finally {
      _openingNotification = false;
    }
  }

  void _notice(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('notification-target-notice'),
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  bool _onScroll(ScrollNotification notification) {
    if (_pointer == null || notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (!_controller.hasClients) return false;
    final pageContext = _controller.position.context.notificationContext;
    if (notification.context != pageContext) {
      _claimed = true;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null || !_swipeEnabled) return;
    _pointer = event.pointer;
    _dx = 0;
    _dy = 0;
    _origin = _controller.hasClients ? _controller.position.pixels : 0;
    _downAt = event.timeStamp;
    _decided = false;
    _horizontal = false;
    _claimed = false;
    _moved = false;
    _released = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _released) return;
    _dx += event.delta.dx;
    _dy += event.delta.dy;
    _scheduleApply();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _released = true;
    _upAt = event.timeStamp;
    _scheduleApply();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _released = true;
    _claimed = true;
    _scheduleApply();
  }

  void _scheduleApply() {
    if (_applyScheduled) return;
    _applyScheduled = true;
    scheduleMicrotask(() {
      _applyScheduled = false;
      if (!mounted) return;
      _applyDrag();
    });
  }

  void _applyDrag() {
    if (_pointer == null || !_controller.hasClients) return;
    if (_claimed || !_swipeEnabled) {
      _restoreOrigin();
      if (_released) _finishPointer();
      return;
    }
    if (!_decided) {
      if (_dx.abs() < _dragSlop && _dy.abs() < _dragSlop) {
        if (_released) _finishPointer();
        return;
      }
      _decided = true;
      _horizontal = _dx.abs() > _dy.abs();
    }
    if (!_horizontal) {
      _restoreOrigin();
      if (_released) _finishPointer();
      return;
    }

    final position = _controller.position;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final raw = _origin + (ltr ? -_dx : _dx);
    final pixels = raw.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((pixels - position.pixels).abs() > 0.5) {
      _controller.jumpTo(pixels.toDouble());
      _moved = true;
    }
    if (!_released) return;

    final page = _controller.page ?? _index.toDouble();
    final elapsedMs = (_upAt - _downAt).inMilliseconds;
    final seconds = elapsedMs <= 0 ? 0.016 : elapsedMs / 1000;
    final scrollVelocity = (ltr ? -_dx : _dx) / seconds;
    var target = page;
    if (scrollVelocity > _flingVelocity) target += 0.5;
    if (scrollVelocity < -_flingVelocity) target -= 0.5;
    final index = target.round().clamp(0, _tabCount - 1);
    _finishPointer();
    _controller.animateToPage(
      index,
      duration: _swipeDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _restoreOrigin() {
    if (!_moved || !_controller.hasClients) return;
    _controller.jumpTo(_origin);
    _moved = false;
  }

  void _finishPointer() {
    _pointer = null;
    _released = false;
    _moved = false;
  }

  void _onReconnected() {
    context.read<HomeBloc>().add(const HomeSummaryRefreshed());
    context.read<ApprovalsBloc>().add(const ApprovalsStarted());
    context.read<HistoryBloc>().add(const HistoryStarted());
    context.read<NotificationsBloc>().add(const NotificationsStarted());
  }

  @override
  Widget build(BuildContext context) {
    _swipeEnabled = ModalRoute.isCurrentOf(context) ?? true;
    final l10n = AppLocalizations.of(context);
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.isUnavailable || current.isOnline),
      listener: (context, state) {
        if (state.isUnavailable) {
          _needsReconnectRefresh = true;
          return;
        }
        if (state.isOnline && _needsReconnectRefresh) {
          _needsReconnectRefresh = false;
          _onReconnected();
        }
      },
      child: Scaffold(
        backgroundColor: AppSurfaces.of(context).scaffold,
        extendBody: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status,
              builder: (context, state) {
                if (state.isOnline) {
                  return const SizedBox.shrink();
                }
                // Keep the last offline/unreachable banner visible while a
                // Retry probe runs (status == checking).
                final bannerStatus = state.status == NetworkStatus.checking
                    ? (state.previous ?? NetworkStatus.offline)
                    : state.status;
                return OfflineBanner(
                  status: bannerStatus,
                  title: l10n.offlineBannerTitle,
                  hint: l10n.offlineBannerHint,
                  retryLabel: l10n.offlineRetry,
                  retrying: state.status == NetworkStatus.checking,
                  onRetry: () => context.read<ConnectivityBloc>().add(
                    const ConnectivityRetryRequested(),
                  ),
                );
              },
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: PageView(
                    key: const Key('portal-tabs'),
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      HomePage(
                        now: widget.now,
                        scrollController: _tabScrolls[0],
                        onOpenApprovals: () => _select(1),
                        onOpenHistory: () => _select(2),
                        onOpenProfile: () => _select(3),
                        onOpenNotifications: _openNotifications,
                      ),
                      ApprovalsPage(scrollController: _tabScrolls[1]),
                      HistoryPage(
                        now: widget.now,
                        scrollController: _tabScrolls[2],
                      ),
                      ProfilePage(
                        scrollController: _tabScrolls[3],
                        onOpenHome: () => _select(0),
                        onOpenApprovals: () => _select(1),
                        onOpenHistory: () => _select(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: PortalBottomNav(
          index: _index,
          onSelected: _select,
        ),
      ),
    );
  }
}
