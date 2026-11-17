import 'dart:async';

import 'package:driver_portal_app/core/loading/minimum_loading_window.dart';
import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/domain/repositories/approval_repository.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/assigned_trip.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_attachment.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/expense_repository.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/domain/repositories/history_repository.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_event.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_state.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';
import '../../support/reveal_finance.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pull shows finance and trip skeletons while requests pend', (
    tester,
  ) async {
    final summaryGate = Completer<FinancialSummary>();
    final tripGate = Completer<List<AssignedTrip>>();
    final finance = _GatedFinance(
      initial: _summary(2200),
      onRefresh: () => summaryGate.future,
    );
    final expenses = _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () => tripGate.future,
    );

    await _pumpHome(
      tester,
      financeRepository: finance,
      expenseRepository: expenses,
    );

    expect(find.byKey(const Key('home-balance')), findsOneWidget);
    expect(find.textContaining('TR-2026-0927'), findsWidgets);

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(find.textContaining('TR-2026-0927'), findsNothing);
    expect(finance.calls, 2);
    expect(expenses.calls, 2);

    var completed = false;
    unawaited(pull.then((_) => completed = true));
    await tester.pump();
    expect(completed, isFalse);

    summaryGate.complete(_summary(2100));
    await tester.pump();
    await tester.pump();
    expect(completed, isFalse);
    // A pull reveals every section together, so finance stays on its skeleton
    // until the trip read finishes too.
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);

    tripGate.complete([_activeTrip('TR-REFRESHED')]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
    expect(find.textContaining('TR-REFRESHED'), findsWidgets);
    expect(find.text('2,100 EGP'), findsWidgets);
  });

  testWidgets('summary failure preserves content and finishes the pull', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: _summary(2200),
      onRefresh: () async => throw StateError('summary failed'),
    );
    await _pumpHome(tester, financeRepository: finance);

    expect(find.text('2,200 EGP'), findsWidgets);

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(find.byKey(const Key('home-retry')), findsNothing);
    expect(find.text('2,200 EGP'), findsWidgets);
    final state = tester.element(find.byKey(const Key('home-page')))
        .read<HomeBloc>()
        .state;
    expect(state, isA<HomeReady>());
    expect((state as HomeReady).financeStatus, HomeFinanceStatus.ready);
    expect(state.summary?.balanceEgp, 2200);
  });

  testWidgets('trip failure preserves prior trip and finishes the pull', (
    tester,
  ) async {
    final expenses = _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () async => throw StateError('trip failed'),
    );
    await _pumpHome(tester, expenseRepository: expenses);

    expect(find.textContaining('TR-2026-0927'), findsWidgets);

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.textContaining('TR-2026-0927'), findsWidgets);
  });

  testWidgets('offline pull shows notice and does not refresh data', (
    tester,
  ) async {
    final finance = _GatedFinance(initial: _summary(2200));
    final expenses = _GatedExpenses(initial: [_activeTrip('TR-2026-0927')]);
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);

    await _pumpHome(
      tester,
      financeRepository: finance,
      expenseRepository: expenses,
      networkMonitor: monitor,
      internetReachability: reachability,
    );

    expect(finance.calls, 1);
    expect(expenses.calls, 1);

    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    await _pullAndSettle(tester);

    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    expect(find.byKey(const Key('balance-loading')), findsNothing);
    expect(find.byKey(const Key('home-limit-loading')), findsNothing);
    expect(find.byKey(const Key('home-trip-loading')), findsNothing);
    expect(find.byKey(const Key('home-pending-loading')), findsNothing);
    expect(find.byKey(const Key('home-recent-loading')), findsNothing);
    expect(finance.calls, 1);
    expect(expenses.calls, 1);
  });

  testWidgets('concurrent pulls share one in-flight refresh', (tester) async {
    final summaryGate = Completer<FinancialSummary>();
    final finance = _GatedFinance(
      initial: _summary(2200),
      onRefresh: () => summaryGate.future,
    );
    await _pumpHome(tester, financeRepository: finance);

    final first = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(finance.calls, 2);

    final second = _startPull(tester);
    await tester.pump();
    expect(finance.calls, 2);

    summaryGate.complete(_summary(2000));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await Future.wait([first, second]);
    expect(finance.calls, 2);
  });

  testWidgets('home keeps FleetRefreshIndicator on the ready scroll view', (
    tester,
  ) async {
    await _pumpHome(tester);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.byKey(const Key('home-page')), findsOneWidget);
  });

  testWidgets('pull shows loading for all data-driven home sections', (
    tester,
  ) async {
    final summaryGate = Completer<FinancialSummary>();
    final tripGate = Completer<List<AssignedTrip>>();
    final approvalsGate = Completer<List<ApprovalItem>>();
    final historyGate = Completer<List<HistoryEntry>>();
    final finance = _GatedFinance(
      initial: _summary(2200),
      onRefresh: () => summaryGate.future,
    );
    final expenses = _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () => tripGate.future,
    );
    final approvals = _GatedApprovals(onRefresh: () => approvalsGate.future);
    final history = _GatedHistory(onRefresh: () => historyGate.future);

    await _pumpHome(
      tester,
      financeRepository: finance,
      expenseRepository: expenses,
      approvalRepository: approvals,
      historyRepository: history,
    );

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(finance.calls, 2);
    expect(expenses.calls, 2);
    expect(approvals.calls, 2);
    expect(history.calls, 2);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-loading')), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('home-charge-progress')),
          )
          .value,
      0,
    );

    var completed = false;
    unawaited(pull.then((_) => completed = true));

    summaryGate.complete(_summary(2100));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-loading')), findsOneWidget);
    expect(completed, isFalse);

    tripGate.complete([_activeTrip('TR-REFRESHED')]);
    approvalsGate.complete(const []);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('home-pending-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-loading')), findsOneWidget);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(completed, isFalse);

    historyGate.complete(const []);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
    expect(find.byKey(const Key('home-recent-loading')), findsNothing);
    expect(find.textContaining('TR-REFRESHED'), findsWidgets);
    expect(find.text('2,100 EGP'), findsWidgets);
  });

  testWidgets('initial entry shows section skeletons before completion', (
    tester,
  ) async {
    final summaryGate = Completer<FinancialSummary>();
    final tripGate = Completer<List<AssignedTrip>>();
    final approvalsGate = Completer<List<ApprovalItem>>();
    final historyGate = Completer<List<HistoryEntry>>();

    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      withConnectivity(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(
            now: () => DateTime(2026, 10, 20, 9),
            financeRepository: _GatedFinance(
              initial: _summary(2200),
              onRefresh: () => summaryGate.future,
              gateInitial: true,
              initialFuture: summaryGate.future,
            ),
            expenseRepository: _GatedExpenses(
              initial: [_activeTrip('TR-2026-0927')],
              onRefresh: () => tripGate.future,
              gateInitial: true,
              initialFuture: tripGate.future,
            ),
            approvalRepository: _GatedApprovals(
              onRefresh: () => approvalsGate.future,
              gateInitial: true,
              initialFuture: approvalsGate.future,
            ),
            historyRepository: _GatedHistory(
              onRefresh: () => historyGate.future,
              gateInitial: true,
              initialFuture: historyGate.future,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-balance')), findsNothing);

    summaryGate.complete(_summary(2200));
    tripGate.complete([_activeTrip('TR-2026-0927')]);
    approvalsGate.complete(const []);
    historyGate.complete(const []);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-balance')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-loading')), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('home-charge-progress')),
          )
          .value,
      closeTo(0.64, 0.001),
    );
  });

  testWidgets('one section failure still finishes the whole-home pull', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: _summary(2200),
      onRefresh: () async => throw StateError('summary failed'),
    );
    final expenses = _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () async => [_activeTrip('TR-OK')],
    );
    final approvals = _GatedApprovals(
      onRefresh: () async => throw StateError('approvals failed'),
    );
    final history = _GatedHistory(onRefresh: () async => const []);

    await _pumpHome(
      tester,
      financeRepository: finance,
      expenseRepository: expenses,
      approvalRepository: approvals,
      historyRepository: history,
    );

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.text('2,200 EGP'), findsWidgets);
    expect(find.textContaining('TR-OK'), findsWidgets);
  });

  testWidgets(
    'home pull refreshes finance approvals and history exactly once',
    (tester) async {
      final finance = _GatedFinance(initial: _summary(2200));
      final approvals = _GatedApprovals();
      final history = _GatedHistory();

      await _pumpHome(
        tester,
        financeRepository: finance,
        approvalRepository: approvals,
        historyRepository: history,
      );
      expect(finance.calls, 1);
      expect(approvals.calls, 1);
      expect(history.calls, 1);

      final approvalsBloc = tester
          .element(find.byKey(const Key('home-page')))
          .read<ApprovalsBloc>();
      final revisionBefore = approvalsBloc.state.revision;

      await _pullAndSettle(tester);
      // Allow any listener-driven cascade that would otherwise enqueue work.
      await tester.pumpAndSettle();

      expect(finance.calls, 2);
      expect(approvals.calls, 2);
      expect(history.calls, 2);
      expect(approvalsBloc.state.revision, revisionBefore);
    },
  );

  testWidgets(
    'approval action revision still refreshes finance and history',
    (tester) async {
      final finance = _GatedFinance(initial: _summary(2200));
      final history = _GatedHistory();

      await _pumpHome(
        tester,
        financeRepository: finance,
        historyRepository: history,
      );
      expect(finance.calls, 1);
      expect(history.calls, 1);
      expect(find.byKey(const Key('home-pending-approve-DSB-2025-0441')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
      );
      await tester.pumpAndSettle();

      final approvalsBloc = tester
          .element(find.byKey(const Key('home-page')))
          .read<ApprovalsBloc>();
      expect(approvalsBloc.state.revision, greaterThan(0));
      expect(finance.calls, greaterThan(1));
      expect(history.calls, greaterThan(1));
    },
  );

  testWidgets('max limit progress starts at zero then reaches target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      withConnectivity(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(
            now: () => DateTime(2026, 10, 20, 9),
            financeRepository: _GatedFinance(initial: _summary(2200)),
          ),
        ),
      ),
    );
    // Loading frame, then the meter, then the post-frame that starts at zero.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    var indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('home-charge-progress')),
    );
    expect(indicator.value, closeTo(0.0, 0.02));

    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump();
    indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('home-charge-progress')),
    );
    expect(indicator.value, closeTo(0.64, 0.001));
  });

  testWidgets('max limit progress animates from zero to a new target', (
    tester,
  ) async {
    final summaryGate = Completer<FinancialSummary>();
    final finance = _GatedFinance(
      initial: _summary(2200, charge: 3200),
      onRefresh: () => summaryGate.future,
    );
    await _pumpHome(tester, financeRepository: finance);

    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('home-charge-progress')),
          )
          .value,
      closeTo(0.64, 0.001),
    );

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('home-charge-progress')),
          )
          .value,
      0,
    );

    summaryGate.complete(_summary(2200, charge: 1000));
    // The floor is marked when the read starts, so let that remainder elapse
    // before the meter remounts and replays from zero.
    await tester.pump(MinimumLoadingWindow.duration);
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('home-charge-progress')),
          )
          .value,
      closeTo(0.0, 0.02),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('home-charge-progress')),
        )
        .value!;
    expect(mid, greaterThan(0.02));
    expect(mid, lessThan(0.20));

    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump(const Duration(seconds: 1));
    await pull;
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('home-charge-progress')),
          )
          .value,
      closeTo(0.20, 0.001),
    );
  });

  testWidgets(
    'max limit refreshes replay from zero even for an identical target',
    (tester) async {
      final summaryGate = Completer<FinancialSummary>();
      final finance = _GatedFinance(
        initial: _summary(2200, charge: 3200),
        onRefresh: () => summaryGate.future,
      );
      await _pumpHome(tester, financeRepository: finance);

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('home-charge-progress')),
            )
            .value,
        closeTo(0.64, 0.001),
      );

      final pull = _startPull(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('home-charge-progress')),
            )
            .value,
        0,
      );

      summaryGate.complete(_summary(2200, charge: 3200));
      // The floor is marked when the read starts, so let that remainder elapse
      // before the meter remounts and replays from zero.
      await tester.pump(MinimumLoadingWindow.duration);
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('home-charge-progress')),
            )
            .value,
        closeTo(0.0, 0.02),
      );
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pump(const Duration(seconds: 1));
      await pull;
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('home-charge-progress')),
            )
            .value,
        closeTo(0.64, 0.001),
      );
    },
  );

  testWidgets(
    'rapid successive finance refreshes reset progress without errors',
    (tester) async {
      final firstGate = Completer<FinancialSummary>();
      final secondGate = Completer<FinancialSummary>();
      var refresh = 0;
      final finance = _GatedFinance(
        initial: _summary(2200, charge: 3200),
        onRefresh: () {
          refresh += 1;
          return refresh == 1 ? firstGate.future : secondGate.future;
        },
      );
      await _pumpHome(tester, financeRepository: finance);
      final homeBloc = tester
          .element(find.byKey(const Key('home-page')))
          .read<HomeBloc>();

      homeBloc.add(const HomeSummaryRefreshed());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);

      // Queued while the first refresh is still loading.
      homeBloc.add(const HomeSummaryRefreshed());
      await tester.pump();
      firstGate.complete(_summary(2200, charge: 4000));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);

      secondGate.complete(_summary(2200, charge: 500));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pump(const Duration(milliseconds: 420));
      expect(find.byKey(const Key('home-limit-loading')), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('home-charge-progress')),
            )
            .value,
        closeTo(0.10, 0.001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reconnect shows home loading states and reloads trip', (
    tester,
  ) async {
    final summaryGate = Completer<FinancialSummary>();
    final tripGate = Completer<List<AssignedTrip>>();
    final finance = _GatedFinance(
      initial: _summary(2200),
      onRefresh: () => summaryGate.future,
    );
    final expenses = _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () => tripGate.future,
    );
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);

    await _pumpHome(
      tester,
      financeRepository: finance,
      expenseRepository: expenses,
      networkMonitor: monitor,
      internetReachability: reachability,
    );
    expect(find.textContaining('TR-2026-0927'), findsWidgets);
    expect(finance.calls, 1);
    expect(expenses.calls, 1);

    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);

    reachability.reachable = true;
    monitor.setHasInterface(true);
    await tester.tap(find.byKey(const Key('offline-banner-retry')));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(finance.calls, greaterThan(1));
    expect(expenses.calls, greaterThan(1));
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);

    summaryGate.complete(_summary(2200));
    tripGate.complete([_activeTrip('TR-RECONNECTED')]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('home-balance')), findsOneWidget);
    expect(find.textContaining('TR-RECONNECTED'), findsWidgets);
    expect(find.byKey(const Key('balance-loading')), findsNothing);
  });

  testWidgets('max limit progress jumps when animations are disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      withConnectivity(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScope(
              now: () => DateTime(2026, 10, 20, 9),
              financeRepository: _GatedFinance(initial: _summary(2200)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('home-charge-progress')),
    );
    expect(indicator.value, closeTo(0.64, 0.001));
  });

  testWidgets('home finance and trip stay readable in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      withConnectivity(
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScope(
            now: () => DateTime(2026, 10, 20, 9),
            financeRepository: _GatedFinance(initial: _summary(2200)),
            expenseRepository: _GatedExpenses(
              initial: [_activeTrip('TR-2026-0927')],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-balance')), findsOneWidget);
    expect(find.byKey(const Key('home-trip-details')), findsOneWidget);
    expect(find.byKey(const Key('home-charge-progress')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'initial entry paints every section skeleton when reads are immediate',
    (tester) async {
      await _pumpHomeFrame(tester);
      await _pumpUntil(tester, find.byKey(const Key('balance-loading')));
      _expectSectionSkeletons(tester);
      expect(find.byKey(const Key('home-balance')), findsNothing);
      expect(find.textContaining('TR-2026-0927'), findsNothing);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      expect(find.byKey(const Key('home-balance')), findsOneWidget);
      expect(find.byKey(const Key('balance-loading')), findsNothing);
      expect(find.byKey(const Key('home-limit-loading')), findsNothing);
      expect(find.byKey(const Key('home-trip-loading')), findsNothing);
      expect(find.byKey(const Key('home-pending-loading')), findsNothing);
      expect(find.byKey(const Key('home-recent-loading')), findsNothing);
      expect(find.textContaining('TR-2026-0927'), findsWidgets);
    },
  );

  testWidgets(
    'pull paints every section skeleton when responses are immediate',
    (tester) async {
      final finance = _GatedFinance(
        initial: _summary(2200),
        onRefresh: () async => _summary(2100),
      );
      final expenses = _GatedExpenses(
        initial: [_activeTrip('TR-2026-0927')],
        onRefresh: () async => [_activeTrip('TR-IMMEDIATE')],
      );
      final approvals = _GatedApprovals(onRefresh: () async => const []);
      final history = _GatedHistory(onRefresh: () async => const []);
      await _pumpHome(
        tester,
        financeRepository: finance,
        expenseRepository: expenses,
        approvalRepository: approvals,
        historyRepository: history,
      );
      expect(find.text('2,200 EGP'), findsWidgets);
      expect(find.textContaining('TR-2026-0927'), findsWidgets);

      final pull = _startPull(tester);
      await _pumpUntilPullSkeletons(
        tester,
        refreshStarted: () =>
            finance.calls > 1 ||
            expenses.calls > 1 ||
            approvals.calls > 1 ||
            history.calls > 1,
      );
      _expectSectionSkeletons(tester);
      expect(finance.calls, 1);
      expect(expenses.calls, 1);
      expect(approvals.calls, 1);
      expect(history.calls, 1);
      expect(find.byKey(const Key('home-balance')), findsNothing);
      expect(find.text('2,200 EGP'), findsNothing);
      expect(find.text('2,100 EGP'), findsNothing);
      expect(find.textContaining('TR-2026-0927'), findsNothing);
      expect(find.textContaining('TR-IMMEDIATE'), findsNothing);

      await tester.pumpAndSettle();
      await pull;
      expect(find.byKey(const Key('home-balance')), findsOneWidget);
      expect(find.text('2,100 EGP'), findsWidgets);
      expect(find.textContaining('TR-IMMEDIATE'), findsWidgets);
      expect(find.byKey(const Key('balance-loading')), findsNothing);
      expect(finance.calls, 2);
      expect(expenses.calls, 2);
      expect(approvals.calls, 2);
      expect(history.calls, 2);
    },
  );

  testWidgets(
    'reconnect paints a loading frame when the reload is immediate',
    (tester) async {
      final finance = _GatedFinance(
        initial: _summary(2200),
        onRefresh: () async => _summary(2100),
      );
      final expenses = _GatedExpenses(
        initial: [_activeTrip('TR-2026-0927')],
        onRefresh: () async => [_activeTrip('TR-RECONNECTED')],
      );
      final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
      final reachability = FakeInternetReachability(reachable: true);
      await _pumpHome(
        tester,
        financeRepository: finance,
        expenseRepository: expenses,
        networkMonitor: monitor,
        internetReachability: reachability,
      );

      reachability.reachable = false;
      monitor.setHasInterface(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      reachability.reachable = true;
      monitor.setHasInterface(true);
      final retry = find.byKey(const Key('offline-banner-retry'));
      final gesture = await tester.startGesture(tester.getCenter(retry));
      await gesture.up();
      await _pumpUntil(tester, find.byKey(const Key('balance-loading')));
      _expectSectionSkeletons(tester);
      expect(find.textContaining('TR-RECONNECTED'), findsNothing);
      expect(find.text('2,100 EGP'), findsNothing);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-balance')), findsOneWidget);
      expect(find.textContaining('TR-RECONNECTED'), findsWidgets);
      expect(find.text('2,100 EGP'), findsWidgets);
      expect(find.byKey(const Key('balance-loading')), findsNothing);
      expect(finance.calls, greaterThan(1));
      expect(expenses.calls, greaterThan(1));
    },
  );

  testWidgets(
    'immediate pull keeps every skeleton until the 800ms floor',
    (tester) async {
      final repos = _immediateRepos(balance: 2100, tripCode: 'TR-IMMEDIATE');
      await _pumpHome(tester, repos: repos);

      final pull = _startPull(tester);
      await _reachPaintedPull(tester, repos);
      _expectSectionSkeletons(tester);
      expect(repos.calls, everyElement(2));
      expect(find.byKey(const Key('home-balance')), findsNothing);
      expect(find.text('2,100 EGP'), findsNothing);
      expect(find.textContaining('TR-IMMEDIATE'), findsNothing);

      await tester.pump(const Duration(milliseconds: 799));
      _expectSectionSkeletons(tester);
      expect(find.byKey(const Key('home-balance')), findsNothing);
      expect(find.text('2,100 EGP'), findsNothing);
      expect(find.textContaining('TR-IMMEDIATE'), findsNothing);
      expect(repos.calls, everyElement(2));

      await tester.pump(const Duration(milliseconds: 1));
      _expectReadyPull(tester, balance: '2,100 EGP', tripCode: 'TR-IMMEDIATE');
      expect(repos.calls, everyElement(2));

      await _finishPullIndicator(tester);
      await pull;
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    },
  );

  testWidgets('a 300ms pull still waits for the 800ms floor', (tester) async {
    final repos = _delayedRepos(
      const Duration(milliseconds: 300),
      balance: 2100,
      tripCode: 'TR-300',
    );
    await _pumpHome(tester, repos: repos);

    final pull = _startPull(tester);
    await _reachPaintedPull(tester, repos);
    expect(repos.calls, everyElement(2));

    await tester.pump(const Duration(milliseconds: 300));
    _expectSectionSkeletons(tester);
    expect(find.text('2,100 EGP'), findsNothing);

    await tester.pump(const Duration(milliseconds: 499));
    _expectSectionSkeletons(tester);
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(repos.calls, everyElement(2));

    await tester.pump(const Duration(milliseconds: 1));
    _expectReadyPull(tester, balance: '2,100 EGP', tripCode: 'TR-300');
    expect(repos.calls, everyElement(2));
    await tester.pump(const Duration(milliseconds: 200));
    await pull;
  });

  testWidgets('a 1200ms pull is not held for an extra 800ms', (tester) async {
    final repos = _delayedRepos(
      const Duration(milliseconds: 1200),
      balance: 2100,
      tripCode: 'TR-1200',
    );
    await _pumpHome(tester, repos: repos);

    final pull = _startPull(tester);
    await _reachPaintedPull(tester, repos);
    expect(repos.calls, everyElement(2));

    await tester.pump(const Duration(milliseconds: 800));
    _expectSectionSkeletons(tester);
    expect(find.text('2,100 EGP'), findsNothing);
    expect(repos.calls, everyElement(2));

    await tester.pump(const Duration(milliseconds: 399));
    _expectSectionSkeletons(tester);
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(repos.calls, everyElement(2));

    await tester.pump(const Duration(milliseconds: 1));
    _expectReadyPull(tester, balance: '2,100 EGP', tripCode: 'TR-1200');
    expect(repos.calls, everyElement(2));
    await _finishPullIndicator(tester);
    await pull;
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets(
    'a failed pull keeps prior content and does not stay pending',
    (tester) async {
      final finance = _GatedFinance(
        initial: _summary(2200),
        onRefresh: () async => throw StateError('summary failed'),
      );
      final expenses = _GatedExpenses(
        initial: [_activeTrip('TR-2026-0927')],
        onRefresh: () async => [_activeTrip('TR-2026-0927')],
      );
      await _pumpHome(
        tester,
        financeRepository: finance,
        expenseRepository: expenses,
      );
      expect(find.text('2,200 EGP'), findsWidgets);

      final pull = _startPull(tester);
      await _pumpUntilPullSkeletons(
        tester,
        refreshStarted: () => finance.calls > 1 || expenses.calls > 1,
      );
      await tester.pump();
      expect(finance.calls, 2);
      expect(expenses.calls, 2);

      await tester.pump(const Duration(milliseconds: 799));
      _expectSectionSkeletons(tester);
      expect(find.text('2,200 EGP'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(const Key('balance-loading')), findsNothing);
      expect(find.byKey(const Key('home-trip-loading')), findsNothing);
      expect(find.byKey(const Key('home-pending-loading')), findsNothing);
      expect(find.byKey(const Key('home-recent-loading')), findsNothing);
      expect(find.text('2,200 EGP'), findsWidgets);
      expect(find.textContaining('TR-2026-0927'), findsWidgets);
      expect(find.byKey(const Key('home-retry')), findsNothing);
      final state = tester
          .element(find.byKey(const Key('home-page')))
          .read<HomeBloc>()
          .state;
      expect(state, isA<HomeReady>());
      expect((state as HomeReady).financeStatus, HomeFinanceStatus.ready);
      expect(state.summary?.balanceEgp, 2200);

      await _finishPullIndicator(tester);
      await pull;
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(finance.calls, 2);
    },
  );

  testWidgets(
    'a second pull during the floor does not reread or extend it',
    (tester) async {
      final repos = _immediateRepos(balance: 2100, tripCode: 'TR-ONCE');
      await _pumpHome(tester, repos: repos);

      final first = _startPull(tester);
      await _reachPaintedPull(tester, repos);
      expect(repos.calls, everyElement(2));

      final second = _startPull(tester);
      await tester.pump(const Duration(milliseconds: 799));
      _expectSectionSkeletons(tester);
      expect(repos.calls, everyElement(2));

      await tester.pump(const Duration(milliseconds: 1));
      _expectReadyPull(tester, balance: '2,100 EGP', tripCode: 'TR-ONCE');
      expect(repos.calls, everyElement(2));

      await _finishPullIndicator(tester);
      await Future.wait([first, second]);
      expect(repos.calls, everyElement(2));
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    },
  );
}

/// Lets the 200ms indicator close finish, then the meter's 420ms replay.
///
/// One exact 200ms pump is short of the close: the dismiss starts during the
/// reveal frame, so the next frame still has a few milliseconds left.
Future<void> _finishPullIndicator(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 420));
  await tester.pump();
}

void _expectSectionSkeletons(WidgetTester tester) {
  expect(find.byKey(const Key('balance-loading')), findsOneWidget);
  expect(find.byKey(const Key('home-limit-loading')), findsOneWidget);
  expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);
  expect(find.byKey(const Key('home-pending-loading')), findsOneWidget);
  expect(find.byKey(const Key('home-recent-loading')), findsOneWidget);
  expect(
    tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('home-charge-progress')),
        )
        .value,
    0,
  );
}

/// Advances one frame at a time until the pull skeletons are in the tree.
///
/// Stops on the first frame that shows them, and fails if a refresh read
/// starts before that frame. The step only moves the indicator clock; the
/// pass condition is the rendered loading state, not a snap-duration count.
Future<void> _pumpUntilPullSkeletons(
  WidgetTester tester, {
  required bool Function() refreshStarted,
}) async {
  for (var frame = 0; frame < 40; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.byKey(const Key('balance-loading')).evaluate().isNotEmpty) {
      expect(refreshStarted(), isFalse);
      return;
    }
    expect(
      refreshStarted(),
      isFalse,
      reason: 'refresh read started before the loading frame was painted',
    );
  }
  fail('loading skeletons were not painted before the refresh read');
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 4; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump();
  }
}

Future<void> _pumpHomeFrame(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    withConnectivity(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScope(now: () => DateTime(2026, 10, 20, 9)),
      ),
    ),
  );
}

FinancialSummary _summary(int balance, {int charge = 3200}) {
  return FinancialSummary(
    balanceEgp: balance,
    chargeEgp: charge,
    maxLimitEgp: 5000,
  );
}

AssignedTrip _activeTrip(String code) {
  return AssignedTrip(
    id: 'trip-$code',
    code: code,
    driverId: MockCashLedger.senderId,
    status: TripStatus.active,
    origin: const LocalizedString(en: 'Cairo', ar: 'القاهرة'),
    destination: const LocalizedString(en: 'Alexandria', ar: 'الإسكندرية'),
    date: DateTime(2026, 9, 27),
    vehicle: 'Truck',
  );
}

class _PullRepos {
  _PullRepos({
    required this.finance,
    required this.expenses,
    required this.approvals,
    required this.history,
  });

  final _GatedFinance finance;
  final _GatedExpenses expenses;
  final _GatedApprovals approvals;
  final _GatedHistory history;

  List<int> get calls => [
    finance.calls,
    expenses.calls,
    approvals.calls,
    history.calls,
  ];
}

_PullRepos _immediateRepos({required int balance, required String tripCode}) {
  return _PullRepos(
    finance: _GatedFinance(
      initial: _summary(2200),
      onRefresh: () async => _summary(balance),
    ),
    expenses: _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () async => [_activeTrip(tripCode)],
    ),
    approvals: _GatedApprovals(onRefresh: () async => const []),
    history: _GatedHistory(onRefresh: () async => const []),
  );
}

_PullRepos _delayedRepos(
  Duration delay, {
  required int balance,
  required String tripCode,
}) {
  return _PullRepos(
    finance: _GatedFinance(
      initial: _summary(2200),
      onRefresh: () => Future.delayed(delay, () => _summary(balance)),
    ),
    expenses: _GatedExpenses(
      initial: [_activeTrip('TR-2026-0927')],
      onRefresh: () => Future.delayed(delay, () => [_activeTrip(tripCode)]),
    ),
    approvals: _GatedApprovals(
      onRefresh: () => Future.delayed(delay, () => const []),
    ),
    history: _GatedHistory(
      onRefresh: () => Future.delayed(delay, () => const []),
    ),
  );
}

/// Paints the pull skeletons, then the following frame that starts the reads
/// and marks the 800ms window. Clock time does not advance on the mark frame.
Future<void> _reachPaintedPull(WidgetTester tester, _PullRepos repos) async {
  await _pumpUntilPullSkeletons(
    tester,
    refreshStarted: () => repos.calls.any((calls) => calls > 1),
  );
  await tester.pump();
}

void _expectReadyPull(
  WidgetTester tester, {
  required String balance,
  required String tripCode,
}) {
  expect(find.byKey(const Key('home-balance')), findsOneWidget);
  expect(find.text(balance), findsWidgets);
  expect(find.byKey(const Key('balance-loading')), findsNothing);
  expect(find.byKey(const Key('home-limit-loading')), findsNothing);
  expect(find.byKey(const Key('home-charge-progress')), findsOneWidget);
  expect(find.byKey(const Key('home-trip-loading')), findsNothing);
  expect(find.textContaining(tripCode), findsWidgets);
  expect(find.byKey(const Key('home-pending-loading')), findsNothing);
  expect(find.byKey(const Key('home-pending-card')), findsOneWidget);
  expect(find.byKey(const Key('home-recent-loading')), findsNothing);
  expect(find.byKey(const Key('home-recent-card')), findsOneWidget);
}

Future<void> _pumpHome(
  WidgetTester tester, {
  _PullRepos? repos,
  FinanceRepository? financeRepository,
  ExpenseRepository? expenseRepository,
  ApprovalRepository? approvalRepository,
  HistoryRepository? historyRepository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  FakeInternetReachability? internetReachability,
}) async {
  financeRepository ??= repos?.finance;
  expenseRepository ??= repos?.expenses;
  approvalRepository ??= repos?.approvals;
  historyRepository ??= repos?.history;
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    withConnectivity(
      networkMonitor: networkMonitor,
      internetReachability: internetReachability,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScope(
          now: () => DateTime(2026, 10, 20, 9),
          loadingNow: () => tester.binding.clock.now(),
          financeRepository: financeRepository,
          expenseRepository: expenseRepository,
          approvalRepository: approvalRepository,
          historyRepository: historyRepository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await revealHomeFinance(tester);
}

Future<void> _startPull(WidgetTester tester) {
  final indicator = tester.state<RefreshIndicatorState>(
    find.byType(RefreshIndicator),
  );
  return indicator.show();
}

Future<void> _pullAndSettle(WidgetTester tester) async {
  // Do not await show() before pumping — onRefresh awaits BLoC work that
  // only progresses after pumps.
  final pull = _startPull(tester);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await pull;
}

class _GatedFinance implements FinanceRepository {
  final FinancialSummary initial;
  final Future<FinancialSummary> Function()? onRefresh;
  final bool gateInitial;
  final Future<FinancialSummary>? initialFuture;
  int calls = 0;

  _GatedFinance({
    required this.initial,
    this.onRefresh,
    this.gateInitial = false,
    this.initialFuture,
  });

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() {
    calls += 1;
    if (calls == 1) {
      if (gateInitial) return initialFuture ?? Completer<FinancialSummary>().future;
      return Future.value(initial);
    }
    return onRefresh?.call() ?? Future.value(initial);
  }
}

class _GatedExpenses implements ExpenseRepository {
  final List<AssignedTrip> initial;
  final Future<List<AssignedTrip>> Function()? onRefresh;
  final bool gateInitial;
  final Future<List<AssignedTrip>>? initialFuture;
  int calls = 0;
  final ExpenseRepository _fallback;

  _GatedExpenses({
    required this.initial,
    this.onRefresh,
    this.gateInitial = false,
    this.initialFuture,
  }) : _fallback = ExpenseRepositoryImpl(
         MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000),
       );

  @override
  Future<List<AssignedTrip>> getAssignedTrips(String driverId) {
    calls += 1;
    if (calls == 1) {
      if (gateInitial) {
        return initialFuture ?? Completer<List<AssignedTrip>>().future;
      }
      return Future.value(initial);
    }
    return onRefresh?.call() ?? Future.value(initial);
  }

  @override
  Future<int> getAvailableBalance(String driverId) =>
      _fallback.getAvailableBalance(driverId);

  @override
  Future<ExpenseRequest> createRecordedExpense({
    required String driverId,
    required String tripId,
    required SettlementType settlementType,
    required int amountEgp,
    required String? notes,
    required List<ExpenseAttachment> attachments,
    required DateTime createdAt,
    ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
  }) =>
      _fallback.createRecordedExpense(
        driverId: driverId,
        tripId: tripId,
        settlementType: settlementType,
        amountEgp: amountEgp,
        notes: notes,
        attachments: attachments,
        createdAt: createdAt,
        tripScope: tripScope,
      );

  @override
  Future<ExpenseRequest> approve(String expenseId) =>
      _fallback.approve(expenseId);

  @override
  Future<ExpenseRequest> reject(String expenseId) =>
      _fallback.reject(expenseId);

  @override
  Future<void> cancel(String expenseId) => _fallback.cancel(expenseId);

  @override
  Future<List<ExpenseRequest>> getExpenses() => _fallback.getExpenses();
}

class _GatedApprovals implements ApprovalRepository {
  final Future<List<ApprovalItem>> Function()? onRefresh;
  final bool gateInitial;
  final Future<List<ApprovalItem>>? initialFuture;
  int calls = 0;

  _GatedApprovals({
    this.onRefresh,
    this.gateInitial = false,
    this.initialFuture,
  });

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<ApprovalItem>> getApprovals(String driverId) {
    calls += 1;
    if (calls == 1) {
      if (gateInitial) {
        return initialFuture ?? Completer<List<ApprovalItem>>().future;
      }
      return Future.value(const []);
    }
    return onRefresh?.call() ?? Future.value(const []);
  }

  @override
  Future<int> getAvailableBalance(String driverId) async => 2200;

  @override
  Future<void> approveVaultReceipt({
    required String driverId,
    required String receiptId,
    DateTime? finalizedAt,
  }) async {}

  @override
  Future<void> approveIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) async {}

  @override
  Future<void> declineIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) async {}

  @override
  Future<void> confirmRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) async {}

  @override
  Future<void> rejectRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) async {}
}

class _GatedHistory implements HistoryRepository {
  final Future<List<HistoryEntry>> Function()? onRefresh;
  final bool gateInitial;
  final Future<List<HistoryEntry>>? initialFuture;
  int calls = 0;

  _GatedHistory({
    this.onRefresh,
    this.gateInitial = false,
    this.initialFuture,
  });

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) {
    calls += 1;
    if (calls == 1) {
      if (gateInitial) {
        return initialFuture ?? Completer<List<HistoryEntry>>().future;
      }
      return Future.value(const []);
    }
    return onRefresh?.call() ?? Future.value(const []);
  }
}
