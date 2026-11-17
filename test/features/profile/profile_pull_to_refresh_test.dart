import 'dart:async';

import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_state.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/reveal_finance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('profile pull refreshes finance summary and waits for completion', (
    tester,
  ) async {
    final gate = Completer<FinancialSummary>();
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () => gate.future,
    );

    await _openProfile(tester, financeRepository: finance);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.byKey(const Key('profile-balance-amount')), findsOneWidget);
    expect(finance.calls, 1);

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    expect(finance.calls, 2);

    var completed = false;
    unawaited(pull.then((_) => completed = true));
    await tester.pump();
    expect(completed, isFalse);

    gate.complete(
      const FinancialSummary(
        balanceEgp: 1900,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.textContaining('1,900'), findsWidgets);
  });

  testWidgets('profile pull also refreshes approvals pending count source', (
    tester,
  ) async {
    await _openProfile(tester);

    final approvals = tester
        .element(find.byKey(const Key('profile-scroll')))
        .read<ApprovalsBloc>();
    final before = approvals.state.pendingCount;
    expect(before, greaterThan(0));
    expect(find.byKey(const Key('profile-pending-count')), findsOneWidget);

    await _pullAndSettle(tester);

    expect(approvals.state.pendingCount, before);
    expect(find.byKey(const Key('profile-pending-count')), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('profile finance failure preserves content and finishes', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () async => throw StateError('summary failed'),
    );
    await _openProfile(tester, financeRepository: finance);

    expect(find.byKey(const Key('profile-balance-amount')), findsOneWidget);

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    expect(find.byKey(const Key('profile-balance-amount')), findsOneWidget);
    final home = tester
        .element(find.byKey(const Key('profile-scroll')))
        .read<HomeBloc>()
        .state;
    expect(home, isA<HomeReady>());
    expect((home as HomeReady).financeStatus, HomeFinanceStatus.ready);
    expect(home.summary?.balanceEgp, 2200);
  });

  testWidgets('offline profile pull shows notice without refreshing finance', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);

    await _openProfile(
      tester,
      financeRepository: finance,
      networkMonitor: monitor,
      internetReachability: reachability,
    );
    expect(finance.calls, 1);

    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    await _pullAndSettle(tester);

    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    expect(find.byKey(const Key('profile-balance-loading')), findsNothing);
    expect(find.byKey(const Key('profile-pending-loading')), findsNothing);
    expect(finance.calls, 1);
  });

  testWidgets('profile concurrent pulls do not duplicate finance loads', (
    tester,
  ) async {
    final gate = Completer<FinancialSummary>();
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () => gate.future,
    );
    await _openProfile(tester, financeRepository: finance);

    final first = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(finance.calls, 2);

    final second = _startPull(tester);
    await tester.pump();
    expect(finance.calls, 2);

    gate.complete(
      const FinancialSummary(
        balanceEgp: 1800,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await Future.wait([first, second]);
    expect(finance.calls, 2);
  });

  testWidgets('immediate profile pull keeps balance and pending skeletons', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () async => const FinancialSummary(
        balanceEgp: 1900,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await _openProfile(tester, financeRepository: finance);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.byKey(const Key('profile-language-value')), findsOneWidget);

    final pull = _startPull(tester);
    await _reachProfileSkeleton(tester, () => finance.calls > 1);
    expect(finance.calls, 2);
    expect(find.byKey(const Key('profile-balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('profile-pending-loading')), findsOneWidget);
    expect(find.byKey(const Key('profile-balance-amount')), findsNothing);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.byKey(const Key('profile-language-value')), findsOneWidget);
    expect(find.textContaining('1,900'), findsNothing);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('profile-balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('profile-pending-loading')), findsOneWidget);
    expect(find.textContaining('1,900'), findsNothing);
    expect(finance.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('profile-balance-loading')), findsNothing);
    expect(find.byKey(const Key('profile-pending-loading')), findsNothing);
    expect(find.byKey(const Key('profile-balance-amount')), findsOneWidget);
    expect(find.textContaining('1,900'), findsWidgets);
    expect(find.byKey(const Key('profile-pending-count')), findsOneWidget);
    expect(finance.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 300ms profile pull still waits for 800ms', (tester) async {
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 300),
        () => const FinancialSummary(
          balanceEgp: 1900,
          chargeEgp: 3200,
          maxLimitEgp: 5000,
        ),
      ),
    );
    await _openProfile(tester, financeRepository: finance);
    final pull = _startPull(tester);
    await _reachProfileSkeleton(tester, () => finance.calls > 1);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('profile-balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('profile-pending-loading')), findsOneWidget);
    expect(find.textContaining('1,900'), findsNothing);
    expect(finance.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.textContaining('1,900'), findsWidgets);
    expect(find.byKey(const Key('profile-balance-loading')), findsNothing);
    expect(find.byKey(const Key('profile-pending-loading')), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 1200ms profile pull is not held for an extra 800ms', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 1200),
        () => const FinancialSummary(
          balanceEgp: 1900,
          chargeEgp: 3200,
          maxLimitEgp: 5000,
        ),
      ),
    );
    await _openProfile(tester, financeRepository: finance);
    final pull = _startPull(tester);
    await _reachProfileSkeleton(tester, () => finance.calls > 1);
    expect(finance.calls, 2);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('profile-balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('profile-pending-loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 399));
    expect(find.textContaining('1,900'), findsNothing);
    expect(finance.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.textContaining('1,900'), findsWidgets);
    expect(find.byKey(const Key('profile-balance-loading')), findsNothing);
    expect(find.byKey(const Key('profile-pending-loading')), findsNothing);
    expect(finance.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a second profile pull does not reread or extend the floor', (
    tester,
  ) async {
    final finance = _GatedFinance(
      initial: const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
      onRefresh: () async => const FinancialSummary(
        balanceEgp: 1900,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await _openProfile(tester, financeRepository: finance);
    final first = _startPull(tester);
    await _reachProfileSkeleton(tester, () => finance.calls > 1);
    final second = _startPull(tester);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('profile-balance-loading')), findsOneWidget);
    expect(finance.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.textContaining('1,900'), findsWidgets);
    expect(finance.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await Future.wait([first, second]);
    expect(finance.calls, 2);
  });
}

Future<void> _openProfile(
  WidgetTester tester, {
  FinanceRepository? financeRepository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  FakeInternetReachability? internetReachability,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
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
          now: () => DateTime(2026, 10, 21, 9),
          loadingNow: () => tester.binding.clock.now(),
          financeRepository: financeRepository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await revealHomeFinance(tester);
  await tester.tap(find.byKey(const Key('nav-profile')));
  await tester.pumpAndSettle();
}

Future<void> _reachProfileSkeleton(
  WidgetTester tester,
  bool Function() refreshStarted,
) async {
  for (var frame = 0; frame < 40; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.byKey(const Key('profile-balance-loading')).evaluate().isNotEmpty) {
      expect(refreshStarted(), isFalse);
      await tester.pump();
      return;
    }
    expect(refreshStarted(), isFalse);
  }
  fail('profile balance skeleton was not painted');
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
  int calls = 0;

  _GatedFinance({required this.initial, this.onRefresh});

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() {
    calls += 1;
    if (calls == 1) return Future.value(initial);
    return onRefresh?.call() ?? Future.value(initial);
  }
}
