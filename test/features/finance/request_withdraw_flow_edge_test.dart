import 'dart:async';

import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/request_cash.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/withdraw_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/withdraw_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/withdraw_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/pages/request_cash_flow_page.dart';
import 'package:driver_portal_app/features/finance/presentation/pages/withdraw_cash_flow_page.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_driver_data_source.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/driver_repository_impl.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_current_driver.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_financial_summary.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

const _me = MockCashLedger.senderId;

void main() {
  testWidgets('request cash failure stays on review and keeps entered data', (
    tester,
  ) async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = _FailingRequestRepository(ledger);
    await _pumpRequestFlow(tester, ledger: ledger, repository: repository);

    await tester.tap(find.byKey(const Key('request-cash-chip-500')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('request-cash-note')),
      'keep me',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Review request'), findsOneWidget);
    final submit = find.byKey(const Key('request-cash-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.submitCalls, 1);
    expect(find.byKey(const Key('cash-request-success')), findsNothing);
    expect(find.text('Review request'), findsOneWidget);
    expect(
      find.text('Unable to submit the cash request. Please try again.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('request-cash-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('request-cash-edit')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('request-cash-amount')))
          .controller!
          .text,
      '500',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('request-cash-note')))
          .controller!
          .text,
      'keep me',
    );

    repository.fail = false;
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cash-request-success')), findsOneWidget);
    expect(find.textContaining('RC-'), findsWidgets);
    expect(repository.submitCalls, 2);
  });

  testWidgets('withdraw failure stays on review and keeps entered data', (
    tester,
  ) async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = _FailingWithdrawRepository(ledger);
    await _pumpWithdrawFlow(tester, ledger: ledger, repository: repository);

    await tester.tap(find.byKey(const Key('withdraw-chip-500')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('withdraw-note')),
      'retry note',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('withdraw-submit'));
    await tester.ensureVisible(submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('withdraw-error')), findsOneWidget);
    expect(
      find.text('Unable to submit the withdraw request. Please try again.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cash-request-success')), findsNothing);
    expect(repository.submitCalls, 1);
    expect(ledger.balanceOf(_me), 2200);

    repository.fail = false;
    await tester.tap(find.byKey(const Key('withdraw-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cash-request-success')), findsOneWidget);
    expect(find.textContaining('WD-'), findsWidgets);
    expect(repository.submitCalls, 2);
    expect(ledger.availableBalance(_me), 1700);
  });

  testWidgets('request cash offline submit shows notice and does not mutate', (
    tester,
  ) async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = CashRequestRepositoryImpl(ledger);
    await _pumpRequestFlow(
      tester,
      ledger: ledger,
      repository: repository,
      networkMonitor: monitor,
      internetReachability: reachability,
    );

    await tester.tap(find.byKey(const Key('request-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();

    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pump();
    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    expect(find.byKey(const Key('cash-request-success')), findsNothing);
    expect(ledger.cashRequests, isEmpty);
  });

  testWidgets('duplicate request cash submit is dropped while in flight', (
    tester,
  ) async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = _GatedRequestRepository(ledger);
    await _pumpRequestFlow(tester, ledger: ledger, repository: repository);

    await tester.tap(find.byKey(const Key('request-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pump();
    expect(repository.submitCalls, 1);

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cash-request-success')), findsOneWidget);
    expect(repository.submitCalls, 1);
  });

  testWidgets('duplicate withdraw submit is dropped while in flight', (
    tester,
  ) async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = _GatedWithdrawRepository(ledger);
    await _pumpWithdrawFlow(tester, ledger: ledger, repository: repository);

    await tester.tap(find.byKey(const Key('withdraw-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('withdraw-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.tap(submit);
    await tester.pump();
    expect(repository.submitCalls, 1);
    expect(ledger.balanceOf(_me), 2200);

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cash-request-success')), findsOneWidget);
    expect(repository.submitCalls, 1);
    expect(ledger.availableBalance(_me), 1700);
  });

  testWidgets('withdraw offline submit shows notice and does not mutate', (
    tester,
  ) async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = CashRequestRepositoryImpl(ledger);
    await _pumpWithdrawFlow(
      tester,
      ledger: ledger,
      repository: repository,
      networkMonitor: monitor,
      internetReachability: reachability,
    );

    await tester.tap(find.byKey(const Key('withdraw-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();

    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('withdraw-submit')));
    await tester.pump();
    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    expect(find.byKey(const Key('cash-request-success')), findsNothing);
    expect(ledger.cashRequests, isEmpty);
    expect(ledger.balanceOf(_me), 2200);
  });
}

Future<void> _pumpRequestFlow(
  WidgetTester tester, {
  required MockCashLedger ledger,
  required CashRequestRepositoryImpl repository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  FakeInternetReachability? internetReachability,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final monitor =
      networkMonitor ?? FakeNetworkInterfaceMonitor(hasInterface: true);
  final reachability =
      internetReachability ?? FakeInternetReachability(reachable: true);
  await tester.pumpWidget(
    withConnectivity(
      networkMonitor: monitor,
      internetReachability: reachability,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => HomeBloc(
              GetCurrentDriver(
                const DriverRepositoryImpl(MockDriverDataSource()),
              ),
              GetFinancialSummary(
                SessionFinanceRepository(const MockFinanceDataSource(), ledger),
              ),
            ),
            child: BlocProvider(
              create: (_) => RequestCashBloc(
                driverId: _me,
                requestCash: RequestCash(repository),
                repository: repository,
              )..add(const RequestCashStarted()),
              child: const RequestCashFlowPage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final connectivity = tester
      .element(find.byType(RequestCashFlowPage))
      .read<ConnectivityBloc>();
  if (!connectivity.state.isOnline) {
    connectivity.add(const ConnectivityRetryRequested());
    await tester.pumpAndSettle();
  }
  expect(connectivity.state.isOnline, isTrue);
}

Future<void> _pumpWithdrawFlow(
  WidgetTester tester, {
  required MockCashLedger ledger,
  required CashRequestRepositoryImpl repository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  FakeInternetReachability? internetReachability,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final monitor =
      networkMonitor ?? FakeNetworkInterfaceMonitor(hasInterface: true);
  final reachability =
      internetReachability ?? FakeInternetReachability(reachable: true);
  await tester.pumpWidget(
    withConnectivity(
      networkMonitor: monitor,
      internetReachability: reachability,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => HomeBloc(
              GetCurrentDriver(
                const DriverRepositoryImpl(MockDriverDataSource()),
              ),
              GetFinancialSummary(
                SessionFinanceRepository(const MockFinanceDataSource(), ledger),
              ),
            ),
            child: BlocProvider(
              create: (_) => WithdrawCashBloc(
                driverId: _me,
                withdrawCash: WithdrawCash(repository),
                repository: repository,
              )..add(const WithdrawCashStarted()),
              child: const WithdrawCashFlowPage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final connectivity = tester
      .element(find.byType(WithdrawCashFlowPage))
      .read<ConnectivityBloc>();
  if (!connectivity.state.isOnline) {
    connectivity.add(const ConnectivityRetryRequested());
    await tester.pumpAndSettle();
  }
  expect(connectivity.state.isOnline, isTrue);
}

class _FailingRequestRepository extends CashRequestRepositoryImpl {
  bool fail = true;
  int submitCalls = 0;

  _FailingRequestRepository(super.ledger);

  @override
  Future<CashRequest> submitRequestCash({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  }) async {
    submitCalls += 1;
    if (fail) throw Exception('submit failed');
    return super.submitRequestCash(
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      note: note,
    );
  }
}

class _FailingWithdrawRepository extends CashRequestRepositoryImpl {
  bool fail = true;
  int submitCalls = 0;

  _FailingWithdrawRepository(super.ledger);

  @override
  Future<CashRequest> submitWithdraw({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  }) async {
    submitCalls += 1;
    if (fail) throw Exception('submit failed');
    return super.submitWithdraw(
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      note: note,
    );
  }
}

class _GatedRequestRepository extends CashRequestRepositoryImpl {
  int submitCalls = 0;
  final Completer<void> _gate = Completer<void>();

  _GatedRequestRepository(super.ledger);

  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<CashRequest> submitRequestCash({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  }) async {
    submitCalls += 1;
    await _gate.future;
    return super.submitRequestCash(
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      note: note,
    );
  }
}

class _GatedWithdrawRepository extends CashRequestRepositoryImpl {
  int submitCalls = 0;
  final Completer<void> _gate = Completer<void>();

  _GatedWithdrawRepository(super.ledger);

  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<CashRequest> submitWithdraw({
    required String driverId,
    required int amountEgp,
    required DateTime createdAt,
    String? note,
  }) async {
    submitCalls += 1;
    await _gate.future;
    return super.submitWithdraw(
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      note: note,
    );
  }
}
