import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/assigned_trip.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('returning to Home does not reload the trip or replay the meter', (
    tester,
  ) async {
    final finance = _CountingFinance();
    final expenses = _CountingExpenses(MockCashLedger(senderBalanceEgp: 2200));
    final history = _CountingHistory(
      MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000)
        ..seedDriverApprovals(),
    );
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);

    await _pumpShell(
      tester,
      finance: finance,
      expenses: expenses,
      history: history,
      monitor: monitor,
      reachability: reachability,
    );

    expect(finance.calls, 1);
    expect(expenses.calls, 1);
    expect(find.textContaining('TR-2026-0927'), findsWidgets);
    expect(find.byKey(const Key('home-trip-loading')), findsNothing);
    expect(_meter(tester), closeTo(0.64, 0.02));

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(history.calls, 1);
    expect(find.byKey(const Key('history-loading')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pump();
    await tester.pump();

    expect(finance.calls, 1);
    expect(expenses.calls, 1);
    expect(find.byKey(const Key('home-trip-loading')), findsNothing);
    expect(find.textContaining('TR-2026-0927'), findsWidgets);
    expect(_meter(tester), closeTo(0.64, 0.02));
  });

  testWidgets('returning to History keeps the ledger, search, and call count', (
    tester,
  ) async {
    final history = _CountingHistory(
      MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000)
        ..seedDriverApprovals(),
    );
    await _pumpShell(tester, history: history);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(history.calls, 1);
    expect(find.byKey(const Key('history-loading')), findsNothing);
    expect(find.textContaining('Vault'), findsWidgets);

    await tester.enterText(find.byKey(const Key('history-search')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-no-results')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pump();
    await tester.pump();

    expect(history.calls, 1);
    expect(find.byKey(const Key('history-loading')), findsNothing);
    expect(find.byKey(const Key('history-no-results')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('history-search')))
          .controller!
          .text,
      'zzzz',
    );
  });

  testWidgets('an offscreen Home still reloads its trip when reconnecting', (
    tester,
  ) async {
    final expenses = _CountingExpenses(MockCashLedger(senderBalanceEgp: 2200));
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);
    await _pumpShell(
      tester,
      expenses: expenses,
      monitor: monitor,
      reachability: reachability,
    );
    expect(expenses.calls, 1);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();

    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    reachability.reachable = true;
    monitor.setHasInterface(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(expenses.calls, greaterThan(1));
    final afterReconnect = expenses.calls;

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(expenses.calls, afterReconnect);
    expect(find.byKey(const Key('home-trip-loading')), findsNothing);
  });

  testWidgets('a kept-alive Home pull and approval revision still refresh', (
    tester,
  ) async {
    final finance = _CountingFinance();
    final history = _CountingHistory(
      MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000)
        ..seedDriverApprovals(),
    );
    await _pumpShell(tester, finance: finance, history: history);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();

    final financeBefore = finance.calls;
    final historyBefore = history.calls;
    expect(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
    );
    await tester.pumpAndSettle();
    expect(finance.calls, greaterThan(financeBefore));
    expect(history.calls, greaterThan(historyBefore));

    final pull = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('home-trip-loading')), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await pull;
    expect(finance.calls, greaterThan(financeBefore + 1));
    expect(find.textContaining('TR-2026-0927'), findsWidgets);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  _CountingFinance? finance,
  _CountingExpenses? expenses,
  _CountingHistory? history,
  FakeNetworkInterfaceMonitor? monitor,
  FakeInternetReachability? reachability,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    withConnectivity(
      networkMonitor: monitor,
      internetReachability: reachability,
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
          financeRepository: finance,
          expenseRepository: expenses,
          historyRepository: history,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _meter(WidgetTester tester) {
  return tester
      .widget<LinearProgressIndicator>(
        find.byKey(const Key('home-charge-progress')),
      )
      .value!;
}

class _CountingFinance implements FinanceRepository {
  int calls = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    calls += 1;
    return const FinancialSummary(
      balanceEgp: 2200,
      chargeEgp: 3200,
      maxLimitEgp: 5000,
    );
  }
}

class _CountingExpenses extends ExpenseRepositoryImpl {
  _CountingExpenses(super.ledger);

  int calls = 0;

  @override
  Future<List<AssignedTrip>> getAssignedTrips(String driverId) {
    calls += 1;
    return super.getAssignedTrips(driverId);
  }
}

class _CountingHistory extends HistoryRepositoryImpl {
  _CountingHistory(super.ledger);

  int calls = 0;

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) {
    calls += 1;
    return super.getHistory(driverId);
  }
}
