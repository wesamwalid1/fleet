import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/request_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/pages/request_cash_flow_page.dart';
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
import '../../support/haptic_log.dart';

const _me = MockCashLedger.senderId;

void main() {
  testWidgets('genuine offline failure SnackBar triggers one error haptic', (
    tester,
  ) async {
    final log = HapticLog.install();
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

    log.clear();
    reachability.reachable = false;
    monitor.setHasInterface(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pump();

    expect(find.byKey(const Key('offline-action-notice')), findsOneWidget);
    log.expectOnly(['HapticFeedbackType.heavyImpact']);
  });

  testWidgets('informational notification SnackBar triggers no haptic', (
    tester,
  ) async {
    final log = HapticLog.install();
    await _pumpShell(tester);

    log.clear();
    final context = tester.element(find.byKey(const Key('nav-home')));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('notification-target-notice'),
          behavior: SnackBarBehavior.floating,
          content: Text(
            AppLocalizations.of(context).notificationTargetUnavailable,
          ),
        ),
      );
    await tester.pump();

    expect(find.byKey(const Key('notification-target-notice')), findsOneWidget);
    log.expectNone();
  });
}

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
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
      home: HomeScope(now: () => DateTime(2026, 10, 20, 9)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRequestFlow(
  WidgetTester tester, {
  required MockCashLedger ledger,
  required CashRequestRepositoryImpl repository,
  required FakeNetworkInterfaceMonitor networkMonitor,
  required FakeInternetReachability internetReachability,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    withConnectivity(
      networkMonitor: networkMonitor,
      internetReachability: internetReachability,
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
