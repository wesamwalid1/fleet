import 'dart:async';

import 'package:driver_portal_app/core/connectivity/domain/internet_reachability.dart';
import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/domain/repositories/approval_repository.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:driver_portal_app/features/approvals/presentation/pages/approvals_page.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_driver_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/driver_repository_impl.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_current_driver.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_financial_summary.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_event.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  testWidgets('pull dispatches ApprovalsRefreshed and awaits completion', (
    tester,
  ) async {
    final gate = Completer<List<ApprovalItem>>();
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () => gate.future,
    );

    await _pumpApprovals(tester, repository: repo);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.text('Received from Vault'), findsOneWidget);
    expect(repo.calls, 1);

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);
    expect(find.text('Approvals'), findsOneWidget);
    expect(repo.calls, 2);

    var completed = false;
    unawaited(pull.then((_) => completed = true));
    await tester.pump();
    expect(completed, isFalse);

    gate.complete([_vaultPending(id: 'DSB-REFRESHED', amountEgp: 3500)]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byKey(const Key('approval-card-DSB-REFRESHED')), findsOneWidget);
    expect(find.textContaining('3,500'), findsWidgets);
  });

  testWidgets('domain failure keeps content, finishes pull, stays silent', (
    tester,
  ) async {
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () async => throw StateError('refresh failed'),
    );
    await _pumpApprovals(tester, repository: repo);

    expect(find.text('Received from Vault'), findsOneWidget);

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.text('Received from Vault'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const Key('approvals-load-error')), findsNothing);
  });

  testWidgets('offline pull shows notice and does not refresh', (tester) async {
    final repo = _GatedApprovals(initial: [_vaultPending()]);
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = GateInternetReachability();

    await _pumpApprovals(
      tester,
      repository: repo,
      networkMonitor: monitor,
      internetReachability: reachability,
      settle: false,
    );
    await _pumpUntil(tester, find.text('Received from Vault'));
    expect(repo.calls, 1);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);

    await _pullAndSettle(tester);

    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    expect(find.byKey(const Key('approvals-loading')), findsNothing);
    expect(repo.calls, 1);

    reachability.complete(reachable: true);
    await tester.pumpAndSettle();
  });

  testWidgets('concurrent pulls share one in-flight refresh', (tester) async {
    final gate = Completer<List<ApprovalItem>>();
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () => gate.future,
    );
    await _pumpApprovals(tester, repository: repo);

    final first = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls, 2);

    final second = _startPull(tester);
    await tester.pump();
    expect(repo.calls, 2);

    gate.complete([_vaultPending()]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await Future.wait([first, second]);
    expect(repo.calls, 2);
  });

  testWidgets('short empty content keeps AlwaysScrollable FleetRefresh', (
    tester,
  ) async {
    final repo = _GatedApprovals(initial: const []);
    await _pumpApprovals(tester, repository: repo);

    expect(find.byKey(const Key('approvals-empty')), findsOneWidget);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    final scroll = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scroll.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('fixed chrome stays outside the pull scrollable', (tester) async {
    await _pumpApprovals(
      tester,
      repository: _GatedApprovals(initial: [_vaultPending()]),
    );

    final title = find.text('Approvals');
    final indicator = find.byType(FleetRefreshIndicator);
    expect(title, findsOneWidget);
    expect(indicator, findsOneWidget);

    final titleBox = tester.getRect(title);
    final listBox = tester.getRect(indicator);
    expect(titleBox.bottom, lessThanOrEqualTo(listBox.top + 1));
    expect(find.byKey(const Key('approvals-search')), findsOneWidget);
  });

  testWidgets('immediate pull keeps the inbox skeleton for 800ms', (
    tester,
  ) async {
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () async => [_vaultPending(id: 'DSB-NOW', amountEgp: 2100)],
    );
    await _pumpApprovals(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    expect(repo.calls, 2);
    expect(find.byKey(const Key('approval-card-DSB-NOW')), findsNothing);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('approvals-loading')), findsNothing);
    expect(find.byKey(const Key('approval-card-DSB-NOW')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 300ms approvals pull still waits for 800ms', (tester) async {
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 300),
        () => [_vaultPending(id: 'DSB-300', amountEgp: 2100)],
      ),
    );
    await _pumpApprovals(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(find.byKey(const Key('approval-card-DSB-300')), findsNothing);

    await tester.pump(const Duration(milliseconds: 499));
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('approval-card-DSB-300')), findsOneWidget);
    expect(find.byKey(const Key('approvals-loading')), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 1200ms approvals pull is not held for an extra 800ms', (
    tester,
  ) async {
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 1200),
        () => [_vaultPending(id: 'DSB-1200', amountEgp: 2100)],
      ),
    );
    await _pumpApprovals(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(find.byKey(const Key('approval-card-DSB-1200')), findsNothing);

    await tester.pump(const Duration(milliseconds: 399));
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('approval-card-DSB-1200')), findsOneWidget);
    expect(find.byKey(const Key('approvals-loading')), findsNothing);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a second approvals pull does not reread or extend the floor', (
    tester,
  ) async {
    final repo = _GatedApprovals(
      initial: [_vaultPending()],
      onRefresh: () async => [_vaultPending(id: 'DSB-ONCE', amountEgp: 2100)],
    );
    await _pumpApprovals(tester, repository: repo);
    final first = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    final second = _startPull(tester);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('approvals-loading')), findsOneWidget);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('approval-card-DSB-ONCE')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await Future.wait([first, second]);
    expect(repo.calls, 2);
  });
}

ApprovalItem _vaultPending({
  String id = 'DSB-2025-0441',
  int amountEgp = 2000,
}) {
  return ApprovalItem(
    id: id,
    kind: ApprovalKind.vault,
    outcome: ApprovalOutcome.pending,
    amountEgp: amountEgp,
    occurredAt: DateTime(2026, 10, 20, 9),
    reference: id,
    counterpartyName: const LocalizedString(en: 'Vault', ar: 'Vault'),
    counterpartyId: 'VAULT',
  );
}

Future<void> _pumpApprovals(
  WidgetTester tester, {
  required ApprovalRepository repository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  InternetReachability? internetReachability,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final drivers = const DriverRepositoryImpl(MockDriverDataSource());
  final finance = _StaticFinance();

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
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => HomeBloc(
                GetCurrentDriver(drivers),
                GetFinancialSummary(finance),
              )..add(const HomeStarted()),
            ),
            BlocProvider(
              create: (_) => ApprovalsBloc(
                driverId: MockCashLedger.senderId,
                repository: repository,
                approveVaultReceipt: ApproveVaultReceipt(repository),
                approveIncomingTransfer: ApproveIncomingTransfer(repository),
                declineIncomingTransfer: DeclineIncomingTransfer(repository),
                confirmRoadExpense: ConfirmRoadExpense(repository),
                rejectRoadExpense: RejectRoadExpense(repository),
              )..add(const ApprovalsStarted()),
            ),
          ],
          child: Scaffold(
            body: ApprovalsPage(
              loadingNow: () => tester.binding.clock.now(),
            ),
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
    if (find.byKey(const Key('approvals-loading')).evaluate().isNotEmpty) {
      expect(refreshStarted(), isFalse);
      await tester.pump();
      return;
    }
    expect(refreshStarted(), isFalse);
  }
  fail('approvals loading skeleton was not painted');
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

class _StaticFinance implements FinanceRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    return const FinancialSummary(
      balanceEgp: 2200,
      chargeEgp: 3200,
      maxLimitEgp: 5000,
    );
  }
}

class _GatedApprovals implements ApprovalRepository {
  final List<ApprovalItem> initial;
  final Future<List<ApprovalItem>> Function()? onRefresh;
  int calls = 0;

  _GatedApprovals({required this.initial, this.onRefresh});

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<ApprovalItem>> getApprovals(String driverId) {
    calls += 1;
    if (calls == 1) return Future.value(initial);
    return onRefresh?.call() ?? Future.value(initial);
  }

  @override
  Future<int> getAvailableBalance(String driverId) async => 2200;

  @override
  Future<void> approveVaultReceipt({
    required String driverId,
    required String receiptId,
    DateTime? finalizedAt,
  }) => _unsupported();

  @override
  Future<void> approveIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) => _unsupported();

  @override
  Future<void> declineIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) => _unsupported();

  @override
  Future<void> confirmRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) => _unsupported();

  @override
  Future<void> rejectRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) => _unsupported();

  Future<void> _unsupported() {
    throw UnsupportedError('not used in PTR tests');
  }
}
