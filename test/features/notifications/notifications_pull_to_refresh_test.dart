import 'dart:async';

import 'package:driver_portal_app/core/connectivity/domain/internet_reachability.dart';
import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/notifications/domain/entities/app_notification.dart';
import 'package:driver_portal_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:driver_portal_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';
import '../../support/paint_frame.dart';

void main() {
  test('NotificationsStarted still shows loading while items are empty',
      () async {
    final gate = Completer<List<AppNotification>>();
    final repo = _GatedNotifications(onLoad: () => gate.future);
    final bloc = NotificationsBloc(
      driverId: MockCashLedger.senderId,
      repository: repo,
    );
    addTearDown(bloc.close);

    expect(bloc.state.loading, isTrue);
    expect(bloc.state.items, isEmpty);

    bloc.add(const NotificationsStarted());
    await paintFrame();
    expect(bloc.state.loading, isTrue);
    expect(bloc.state.items, isEmpty);
    expect(repo.calls, 1);

    gate.complete([_item('n-1')]);
    await bloc.stream.firstWhere((state) => !state.loading);
    expect(bloc.state.items, hasLength(1));
  });

  test('NotificationsRefreshed keeps empty items while loading is painted',
      () async {
    final gate = Completer<List<AppNotification>>();
    final repo = _GatedNotifications(
      initial: const [],
      onRefresh: () => gate.future,
    );
    final bloc = NotificationsBloc(
      driverId: MockCashLedger.senderId,
      repository: repo,
    );
    addTearDown(bloc.close);

    bloc.add(const NotificationsStarted());
    await withFrames(bloc.stream.firstWhere((state) => !state.loading));
    expect(bloc.state.items, isEmpty);
    expect(bloc.state.loading, isFalse);

    bloc.add(const NotificationsRefreshed());
    await paintFrame();
    expect(bloc.state.loading, isTrue);
    expect(bloc.state.items, isEmpty);
    expect(repo.calls, 2);

    gate.complete(const []);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.loading, isFalse);
  });

  testWidgets('pull awaits refresh completion and keeps tiles visible', (
    tester,
  ) async {
    final gate = Completer<List<AppNotification>>();
    final repo = _GatedNotifications(
      initial: [_item('n-visible')],
      onRefresh: () => gate.future,
    );

    await _pumpPage(tester, repository: repo);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.byKey(const Key('notification-n-visible')), findsOneWidget);
    expect(repo.calls, 1);

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
    expect(find.byKey(const Key('notification-n-visible')), findsNothing);
    expect(find.byKey(const Key('notifications-title')), findsOneWidget);
    expect(repo.calls, 2);

    var completed = false;
    unawaited(pull.then((_) => completed = true));
    await tester.pump();
    expect(completed, isFalse);

    gate.complete([_item('n-refreshed')]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byKey(const Key('notification-n-refreshed')), findsOneWidget);
  });

  testWidgets('refresh failure keeps tiles, shows banner, finishes pull', (
    tester,
  ) async {
    final repo = _GatedNotifications(
      initial: [_item('n-keep')],
      onRefresh: () async => throw StateError('refresh failed'),
    );
    await _pumpPage(tester, repository: repo);

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byKey(const Key('notification-n-keep')), findsOneWidget);
    expect(find.byKey(const Key('notifications-refresh-failed')), findsOneWidget);
    expect(find.byKey(const Key('notifications-error')), findsNothing);
  });

  testWidgets('empty online list stays refreshable with AlwaysScrollable', (
    tester,
  ) async {
    final repo = _GatedNotifications(initial: const []);
    await _pumpPage(tester, repository: repo);

    expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final scroll = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scroll.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('offline pull shows notice and does not refresh', (tester) async {
    final repo = _GatedNotifications(initial: [_item('n-offline')]);
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = GateInternetReachability();

    await _pumpPage(
      tester,
      repository: repo,
      networkMonitor: monitor,
      internetReachability: reachability,
      settle: false,
    );
    await _pumpUntil(tester, find.byKey(const Key('notification-n-offline')));
    expect(repo.calls, 1);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);

    await _pullAndSettle(tester);

    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    expect(find.byKey(const Key('notifications-loading')), findsNothing);
    expect(repo.calls, 1);

    reachability.complete(reachable: true);
    await tester.pumpAndSettle();
  });

  testWidgets('concurrent pulls share one in-flight refresh', (tester) async {
    final gate = Completer<List<AppNotification>>();
    final repo = _GatedNotifications(
      initial: [_item('n-shared')],
      onRefresh: () => gate.future,
    );
    await _pumpPage(tester, repository: repo);

    final first = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls, 2);

    final second = _startPull(tester);
    await tester.pump();
    expect(repo.calls, 2);

    gate.complete([_item('n-shared')]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await Future.wait([first, second]);
    expect(repo.calls, 2);
  });

  testWidgets('fixed chrome stays outside the pull scrollable', (tester) async {
    await _pumpPage(
      tester,
      repository: _GatedNotifications(initial: [_item('n-chrome')]),
    );

    final title = find.byKey(const Key('notifications-title'));
    final indicator = find.byType(FleetRefreshIndicator);
    expect(title, findsOneWidget);
    expect(indicator, findsOneWidget);

    final titleBox = tester.getRect(title);
    final listBox = tester.getRect(indicator);
    expect(titleBox.bottom, lessThanOrEqualTo(listBox.top + 1));
    expect(find.byKey(const Key('notifications-search')), findsOneWidget);
  });

  testWidgets('tap still opens a notification after PTR wiring', (tester) async {
    final opened = <String>[];
    await _pumpPage(
      tester,
      repository: _GatedNotifications(initial: [_item('n-tap')]),
      onOpen: (notification) async {
        opened.add(notification.id);
      },
    );

    await tester.tap(find.byKey(const Key('notification-n-tap')));
    await tester.pump();
    expect(opened, ['n-tap']);
  });

  testWidgets('immediate pull keeps the notification skeleton for 800ms', (
    tester,
  ) async {
    final repo = _GatedNotifications(
      initial: [_item('n-old')],
      onRefresh: () async => [_item('n-now')],
    );
    await _pumpPage(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    expect(repo.calls, 2);
    expect(find.byKey(const Key('notification-n-now')), findsNothing);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
    expect(find.byKey(const Key('notification-n-old')), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('notifications-loading')), findsNothing);
    expect(find.byKey(const Key('notification-n-now')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 300ms notifications pull still waits for 800ms', (
    tester,
  ) async {
    final repo = _GatedNotifications(
      initial: [_item('n-old')],
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 300),
        () => [_item('n-300')],
      ),
    );
    await _pumpPage(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
    expect(find.byKey(const Key('notification-n-300')), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('notification-n-300')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 1200ms notifications pull is not held for an extra 800ms', (
    tester,
  ) async {
    final repo = _GatedNotifications(
      initial: [_item('n-old')],
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 1200),
        () => [_item('n-1200')],
      ),
    );
    await _pumpPage(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 399));
    expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
    expect(find.byKey(const Key('notification-n-1200')), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('notification-n-1200')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets(
    'a second notifications pull does not reread or extend the floor',
    (tester) async {
      final repo = _GatedNotifications(
        initial: [_item('n-old')],
        onRefresh: () async => [_item('n-once')],
      );
      await _pumpPage(tester, repository: repo);
      final first = _startPull(tester);
      await _reachPullSkeleton(tester, () => repo.calls > 1);
      final second = _startPull(tester);

      await tester.pump(const Duration(milliseconds: 799));
      expect(find.byKey(const Key('notifications-loading')), findsOneWidget);
      expect(repo.calls, 2);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(const Key('notification-n-once')), findsOneWidget);
      expect(repo.calls, 2);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      await Future.wait([first, second]);
      expect(repo.calls, 2);
    },
  );
}

AppNotification _item(String id, {bool read = false}) {
  return AppNotification(
    id: id,
    driverId: MockCashLedger.senderId,
    type: NotificationType.expenseRecorded,
    entityType: NotificationEntityType.expense,
    entityId: id,
    createdAt: DateTime(2026, 10, 20, 9),
    dedupKey: id,
    source: NotificationSource.event,
    read: read,
    amountEgp: 120,
    counterpartyName: const LocalizedString(en: 'Trip', ar: 'رحلة'),
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required NotificationRepository repository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  InternetReachability? internetReachability,
  Future<void> Function(AppNotification notification)? onOpen,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: withConnectivity(
        networkMonitor: networkMonitor,
        internetReachability: internetReachability,
        child: BlocProvider(
          create: (_) => NotificationsBloc(
            driverId: MockCashLedger.senderId,
            repository: repository,
          )..add(const NotificationsStarted()),
          child: NotificationsPage(
            now: () => DateTime(2026, 10, 30, 12),
            loadingNow: () => tester.binding.clock.now(),
            onOpen: onOpen ?? (_) async {},
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _reachPullSkeleton(
  WidgetTester tester,
  bool Function() refreshStarted,
) async {
  for (var frame = 0; frame < 40; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.byKey(const Key('notifications-loading')).evaluate().isNotEmpty) {
      expect(refreshStarted(), isFalse);
      await tester.pump();
      return;
    }
    expect(refreshStarted(), isFalse);
  }
  fail('notifications loading skeleton was not painted');
}

Future<void> _startPull(WidgetTester tester) {
  final indicator = tester.state<RefreshIndicatorState>(
    find.byType(RefreshIndicator),
  );
  return indicator.show();
}

Future<void> _pullAndSettle(WidgetTester tester) async {
  final pull = _startPull(tester);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await pull;
}

class _GatedNotifications implements NotificationRepository {
  final List<AppNotification>? initial;
  final Future<List<AppNotification>> Function()? onLoad;
  final Future<List<AppNotification>> Function()? onRefresh;
  int calls = 0;
  final _changes = StreamController<String>.broadcast();

  _GatedNotifications({this.initial, this.onLoad, this.onRefresh});

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<List<AppNotification>> getNotifications(String driverId) {
    calls += 1;
    if (calls == 1) {
      if (onLoad != null) return onLoad!();
      return Future.value(initial ?? const []);
    }
    return onRefresh?.call() ?? Future.value(initial ?? const []);
  }

  @override
  Future<bool> add(AppNotification notification) async => false;

  @override
  Future<void> update(AppNotification notification) async {}

  @override
  Future<void> markRead({required String driverId, required String id}) async {}
}
