import 'dart:async';

import 'package:driver_portal_app/core/connectivity/domain/internet_reachability.dart';
import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/domain/repositories/history_repository.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/history/presentation/pages/history_page.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  testWidgets('pull dispatches HistoryRefreshed and awaits completion', (
    tester,
  ) async {
    final gate = Completer<List<HistoryEntry>>();
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () => gate.future,
    );

    await _pumpHistory(tester, repository: repo);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.text('Received from Vault'), findsOneWidget);
    expect(repo.calls, 1);

    final pull = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('history-loading')), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);
    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(repo.calls, 2);

    var completed = false;
    unawaited(pull.then((_) => completed = true));
    await tester.pump();
    expect(completed, isFalse);

    gate.complete([_vaultEntry(id: 'H-REFRESH', amountEgp: 3500)]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byKey(const Key('history-entry-H-REFRESH')), findsOneWidget);
    expect(find.textContaining('3,500'), findsWidgets);
  });

  testWidgets('refresh failure keeps ledger and shows banner', (tester) async {
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () async => throw StateError('refresh failed'),
    );
    await _pumpHistory(tester, repository: repo);

    expect(find.text('Received from Vault'), findsOneWidget);

    await _pullAndSettle(tester);

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.text('Received from Vault'), findsOneWidget);
    expect(find.byKey(const Key('history-refresh-failed')), findsOneWidget);
    expect(find.byKey(const Key('history-refresh-retry')), findsOneWidget);
  });

  testWidgets('offline pull shows notice and does not refresh', (tester) async {
    final repo = _GatedHistory(initial: [_vaultEntry()]);
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = GateInternetReachability();

    await _pumpHistory(
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
    expect(find.byKey(const Key('history-loading')), findsNothing);
    expect(repo.calls, 1);

    reachability.complete(reachable: true);
    await tester.pumpAndSettle();
  });

  testWidgets('concurrent pulls share one in-flight refresh', (tester) async {
    final gate = Completer<List<HistoryEntry>>();
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () => gate.future,
    );
    await _pumpHistory(tester, repository: repo);

    final first = _startPull(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.calls, 2);

    final second = _startPull(tester);
    await tester.pump();
    expect(repo.calls, 2);

    gate.complete([_vaultEntry()]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await Future.wait([first, second]);
    expect(repo.calls, 2);
  });

  testWidgets('short empty ledger keeps AlwaysScrollable FleetRefresh', (
    tester,
  ) async {
    final repo = _GatedHistory(initial: const []);
    await _pumpHistory(tester, repository: repo);

    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    final scroll = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scroll.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('fixed chrome stays outside the ledger pull scrollable', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      repository: _GatedHistory(initial: [_vaultEntry()]),
    );

    final title = find.byKey(const Key('history-title'));
    final indicator = find.byType(FleetRefreshIndicator);
    expect(title, findsOneWidget);
    expect(indicator, findsOneWidget);

    final titleBox = tester.getRect(title);
    final listBox = tester.getRect(indicator);
    expect(titleBox.bottom, lessThanOrEqualTo(listBox.top + 1));
    expect(find.byKey(const Key('history-search')), findsOneWidget);
  });

  testWidgets('immediate pull keeps the ledger skeleton for 800ms', (
    tester,
  ) async {
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () async => [_vaultEntry(id: 'H-NOW', amountEgp: 2100)],
    );
    await _pumpHistory(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    expect(repo.calls, 2);
    expect(find.byKey(const Key('history-entry-H-NOW')), findsNothing);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('history-loading')), findsOneWidget);
    expect(find.text('Received from Vault'), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('history-loading')), findsNothing);
    expect(find.byKey(const Key('history-entry-H-NOW')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 300ms history pull still waits for 800ms', (tester) async {
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 300),
        () => [_vaultEntry(id: 'H-300', amountEgp: 2100)],
      ),
    );
    await _pumpHistory(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('history-loading')), findsOneWidget);
    expect(find.byKey(const Key('history-entry-H-300')), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('history-entry-H-300')), findsOneWidget);
    expect(find.byKey(const Key('history-loading')), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a 1200ms history pull is not held for an extra 800ms', (
    tester,
  ) async {
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () => Future.delayed(
        const Duration(milliseconds: 1200),
        () => [_vaultEntry(id: 'H-1200', amountEgp: 2100)],
      ),
    );
    await _pumpHistory(tester, repository: repo);
    final pull = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('history-loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 399));
    expect(find.byKey(const Key('history-loading')), findsOneWidget);
    expect(find.byKey(const Key('history-entry-H-1200')), findsNothing);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('history-entry-H-1200')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await pull;
  });

  testWidgets('a second history pull does not reread or extend the floor', (
    tester,
  ) async {
    final repo = _GatedHistory(
      initial: [_vaultEntry()],
      onRefresh: () async => [_vaultEntry(id: 'H-ONCE', amountEgp: 2100)],
    );
    await _pumpHistory(tester, repository: repo);
    final first = _startPull(tester);
    await _reachPullSkeleton(tester, () => repo.calls > 1);
    final second = _startPull(tester);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const Key('history-loading')), findsOneWidget);
    expect(repo.calls, 2);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('history-entry-H-ONCE')), findsOneWidget);
    expect(repo.calls, 2);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await Future.wait([first, second]);
    expect(repo.calls, 2);
  });
}

HistoryEntry _vaultEntry({String id = 'H-VAULT', int amountEgp = 2000}) {
  final when = DateTime(2026, 10, 20, 9);
  return HistoryEntry(
    id: id,
    kind: HistoryKind.vault,
    amountEgp: amountEgp,
    credit: true,
    status: HistoryDisplayStatus.awaitingApproval,
    tripCode: '',
    tripId: '',
    counterpartyName: const LocalizedString(en: 'Vault', ar: 'Vault'),
    counterpartyId: 'VAULT',
    requestNumber: id,
    createdAt: when,
    updatedAt: when,
  );
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required HistoryRepository repository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  InternetReachability? internetReachability,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ledger = MockCashLedger(senderBalanceEgp: 2200);
  final approvals = ApprovalRepositoryImpl(ledger);

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
              create: (_) => HistoryBloc(
                driverId: MockCashLedger.senderId,
                repository: repository,
              )..add(const HistoryStarted()),
            ),
            BlocProvider(
              create: (_) => ApprovalsBloc(
                driverId: MockCashLedger.senderId,
                repository: approvals,
                approveVaultReceipt: ApproveVaultReceipt(approvals),
                approveIncomingTransfer: ApproveIncomingTransfer(approvals),
                declineIncomingTransfer: DeclineIncomingTransfer(approvals),
                confirmRoadExpense: ConfirmRoadExpense(approvals),
                rejectRoadExpense: RejectRoadExpense(approvals),
              ),
            ),
          ],
          child: Scaffold(
            body: HistoryPage(
              now: () => DateTime(2026, 10, 21, 12),
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
    if (find.byKey(const Key('history-loading')).evaluate().isNotEmpty) {
      expect(refreshStarted(), isFalse);
      await tester.pump();
      return;
    }
    expect(refreshStarted(), isFalse);
  }
  fail('history loading skeleton was not painted');
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

class _GatedHistory implements HistoryRepository {
  final List<HistoryEntry> initial;
  final Future<List<HistoryEntry>> Function()? onRefresh;
  int calls = 0;

  _GatedHistory({required this.initial, this.onRefresh});

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) {
    calls += 1;
    if (calls == 1) return Future.value(initial);
    return onRefresh?.call() ?? Future.value(initial);
  }
}
