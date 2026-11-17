import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/approvals/data/repositories/approval_repository_impl.dart';
import '../../features/approvals/domain/repositories/approval_repository.dart';
import '../../features/approvals/domain/usecases/approve_incoming_transfer.dart';
import '../../features/approvals/domain/usecases/approve_vault_receipt.dart';
import '../../features/approvals/domain/usecases/confirm_road_expense.dart';
import '../../features/approvals/domain/usecases/decline_incoming_transfer.dart';
import '../../features/approvals/domain/usecases/reject_road_expense.dart';
import '../../features/approvals/presentation/bloc/approvals_bloc.dart';
import '../../features/approvals/presentation/bloc/approvals_event.dart';
import '../../features/finance/data/datasources/mock_cash_ledger.dart';
import '../../features/finance/data/repositories/cash_request_repository_impl.dart';
import '../../features/finance/data/repositories/cash_transfer_repository_impl.dart';
import '../../features/finance/data/repositories/expense_repository_impl.dart';
import '../../features/finance/domain/repositories/cash_request_repository.dart';
import '../../features/finance/domain/repositories/cash_transfer_repository.dart';
import '../../features/finance/domain/repositories/expense_repository.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/bloc/history_event.dart';
import '../../features/home/data/datasources/mock_driver_data_source.dart';
import '../../features/home/data/datasources/mock_finance_data_source.dart';
import '../../features/home/data/repositories/driver_repository_impl.dart';
import '../../features/home/data/repositories/session_finance_repository.dart';
import '../../features/home/domain/repositories/driver_repository.dart';
import '../../features/home/domain/repositories/finance_repository.dart';
import '../../features/home/domain/summarize_transactions.dart';
import '../../features/home/domain/usecases/get_current_driver.dart';
import '../../features/home/domain/usecases/get_financial_summary.dart';
import '../../features/home/domain/usecases/watch_finance_changes.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/notifications/data/datasources/mock_notification_seed.dart';
import '../../features/notifications/data/datasources/notification_local_data_source.dart';
import '../../features/notifications/data/ledger_notification_bridge.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/bloc/notifications_event.dart';
import '../connectivity/data/always_online_connectivity.dart';
import '../connectivity/presentation/bloc/connectivity_bloc.dart';
import '../connectivity/presentation/bloc/connectivity_event.dart';
import '../debug/mock_network_delay.dart';
import '../navigation/portal_shell.dart';
import '../theme/data/theme_repository_impl.dart';
import '../theme/presentation/bloc/theme_bloc.dart';
import '../theme/presentation/bloc/theme_event.dart';

class HomeScope extends StatelessWidget {
  final DriverRepository? repository;
  final FinanceRepository? financeRepository;
  final ExpenseRepository? expenseRepository;
  final ApprovalRepository? approvalRepository;
  final HistoryRepository? historyRepository;
  final DateTime Function()? now;

  /// Clock for the Home pull's minimum loading window. Tests pass the
  /// binding clock so the 800ms floor is deterministic.
  final DateTime Function()? loadingNow;
  final bool seedApprovals;
  final void Function(MockCashLedger ledger)? configureLedger;
  final NotificationRepository? notificationRepository;

  /// Temporary test aid, honored in debug builds only: when this signed-in
  /// session starts, the demo notifications are put back to unread.
  final bool resetDemoNotifications;

  /// Optional mock I/O delay for Home-related repositories. Defaults to
  /// [MockNetworkDelay.resolve] (`MOCK_NETWORK_DELAY_MS` in debug only).
  final Duration? mockNetworkDelay;

  const HomeScope({
    super.key,
    this.repository,
    this.financeRepository,
    this.expenseRepository,
    this.approvalRepository,
    this.historyRepository,
    this.now,
    this.loadingNow,
    this.seedApprovals = true,
    this.configureLedger,
    this.notificationRepository,
    this.resetDemoNotifications = false,
    this.mockNetworkDelay,
  });

  @override
  Widget build(BuildContext context) {
    final opening = summarizeTransactions(
      maxLimitEgp: MockFinanceDataSource.maxLimitEgp,
      transactions: [
        for (final transaction in MockFinanceDataSource.transactions)
          transaction.toEntity(),
      ],
    );
    final ledger = MockCashLedger(
      senderBalanceEgp: opening.balanceEgp,
      maxLimitEgp: opening.maxLimitEgp,
    );
    if (seedApprovals) ledger.seedDriverApprovals();
    configureLedger?.call(ledger);
    final networkDelay = MockNetworkDelay.resolve(override: mockNetworkDelay);

    return RepositoryProvider<DriverRepository>(
      create: (_) =>
          repository ?? const DriverRepositoryImpl(MockDriverDataSource()),
      child: RepositoryProvider<FinanceRepository>(
        create: (_) =>
            financeRepository ??
            SessionFinanceRepository(
              const MockFinanceDataSource(),
              ledger,
              networkDelay: networkDelay,
            ),
        child: RepositoryProvider<CashTransferRepository>(
          create: (_) => CashTransferRepositoryImpl(ledger),
          child: RepositoryProvider<ExpenseRepository>(
            create: (_) =>
                expenseRepository ??
                ExpenseRepositoryImpl(ledger, networkDelay: networkDelay),
            child: RepositoryProvider<CashRequestRepository>(
              create: (_) => CashRequestRepositoryImpl(ledger),
              child: RepositoryProvider<ApprovalRepository>(
                create: (_) =>
                    approvalRepository ??
                    ApprovalRepositoryImpl(
                      ledger,
                      networkDelay: networkDelay,
                    ),
                child: RepositoryProvider<HistoryRepository>(
                  create: (_) =>
                      historyRepository ??
                      HistoryRepositoryImpl(
                        ledger,
                        networkDelay: networkDelay,
                      ),
                  child: RepositoryProvider<NotificationRepository>(
                    create: (_) =>
                        notificationRepository ??
                        NotificationRepositoryImpl(
                          SharedPreferencesNotificationDataSource(),
                          seedFor: seedApprovals
                              ? MockNotificationSeed.forDriver
                              : MockNotificationSeed.none,
                        ),
                    dispose: (repository) {
                      if (repository is NotificationRepositoryImpl &&
                          notificationRepository == null) {
                        repository.dispose();
                      }
                    },
                    child: RepositoryProvider<LedgerNotificationBridge>(
                      lazy: false,
                      create: (context) => LedgerNotificationBridge(
                        ledger,
                        context.read<NotificationRepository>(),
                      )..attach(),
                      dispose: (bridge) => bridge.detach(),
                      child: Builder(
                        builder: (context) {
                          final approvals = context.read<ApprovalRepository>();
                          final history = context.read<HistoryRepository>();
                          final notifications = context
                              .read<NotificationRepository>();
                          return MultiBlocProvider(
                            providers: [
                              BlocProvider(
                                create: (context) => HomeBloc(
                                  GetCurrentDriver(
                                    context.read<DriverRepository>(),
                                  ),
                                  GetFinancialSummary(
                                    context.read<FinanceRepository>(),
                                  ),
                                  watchFinanceChanges: WatchFinanceChanges(
                                    context.read<FinanceRepository>(),
                                  ),
                                )..add(const HomeStarted()),
                              ),
                              BlocProvider(
                                create: (_) => ApprovalsBloc(
                                  driverId: MockCashLedger.senderId,
                                  repository: approvals,
                                  approveVaultReceipt: ApproveVaultReceipt(
                                    approvals,
                                  ),
                                  approveIncomingTransfer:
                                      ApproveIncomingTransfer(approvals),
                                  declineIncomingTransfer:
                                      DeclineIncomingTransfer(approvals),
                                  confirmRoadExpense: ConfirmRoadExpense(
                                    approvals,
                                  ),
                                  rejectRoadExpense: RejectRoadExpense(
                                    approvals,
                                  ),
                                )..add(const ApprovalsStarted()),
                              ),
                              BlocProvider(
                                create: (_) => HistoryBloc(
                                  driverId: MockCashLedger.senderId,
                                  repository: history,
                                )..add(const HistoryStarted()),
                              ),
                              BlocProvider(
                                create: (_) => NotificationsBloc(
                                  driverId: MockCashLedger.senderId,
                                  repository: notifications,
                                )..add(const NotificationsStarted()),
                              ),
                            ],
                            child: _DevNotificationReset(
                              enabled: kDebugMode && resetDemoNotifications,
                              child: _EnsureAppLevelBlocs(
                                child: PortalShell(
                                  now: now ?? DateTime.now,
                                  loadingNow: loadingNow,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Supplies [ConnectivityBloc] / [ThemeBloc] when the tree was pumped without
/// [DriverPortalApp] (HomeScope-only tests). Production already provides both
/// above the session, so this is a no-op there.
class _EnsureAppLevelBlocs extends StatelessWidget {
  final Widget child;

  const _EnsureAppLevelBlocs({required this.child});

  @override
  Widget build(BuildContext context) {
    Widget tree = child;
    if (!_hasBloc<ThemeBloc>(context)) {
      tree = BlocProvider(
        create: (_) =>
            ThemeBloc(const ThemeRepositoryImpl())..add(const ThemeStarted()),
        child: tree,
      );
    }
    if (!_hasBloc<ConnectivityBloc>(context)) {
      tree = BlocProvider(
        create: (_) => ConnectivityBloc(
          monitor: const AlwaysOnlineNetworkMonitor(),
          reachability: const AlwaysReachableInternet(),
        )..add(const ConnectivityStarted()),
        child: tree,
      );
    }
    return tree;
  }

  static bool _hasBloc<T extends StateStreamableSource<Object?>>(
    BuildContext context,
  ) {
    try {
      context.read<T>();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// When [enabled], puts the demo notifications back to their initial content,
/// all unread, as the signed-in session starts, so notification scenarios can
/// be tested again after each login. The state is created once per
/// [HomeScope], which each login creates anew; rebuilds and tab changes keep
/// it, so the reset runs exactly once per session.
class _DevNotificationReset extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _DevNotificationReset({required this.enabled, required this.child});

  @override
  State<_DevNotificationReset> createState() => _DevNotificationResetState();
}

class _DevNotificationResetState extends State<_DevNotificationReset> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    final repository = context.read<NotificationRepository>();
    if (repository is NotificationRepositoryImpl) {
      unawaited(repository.resetSeedFixtures(MockCashLedger.senderId));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
