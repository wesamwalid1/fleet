import 'dart:async';

import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/domain/repositories/approval_repository.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_transfer_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/cash_request_repository.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/cash_transfer_repository.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/expense_repository.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/repositories/history_repository.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_driver_data_source.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/driver_repository_impl.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/repositories/driver_repository.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/summarize_transactions.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_current_driver.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/usecases/watch_finance_changes.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/features/home/presentation/finance_visibility_cubit.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_event.dart';
import 'package:driver_portal_app/features/home/presentation/pages/home_page.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:driver_portal_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';
import '../../support/reveal_finance.dart';

void main() {
  testWidgets('home shows the two newest actionable approvals', (tester) async {
    await _pump(tester);

    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-RE-2026-1041')), findsNothing);
    expect(find.byKey(const Key('home-pending-DSB-2025-0301')), findsNothing);
    expect(find.byKey(const Key('home-recent-RE-2026-1041')), findsOneWidget);
    expect(find.textContaining('EXP-'), findsNothing);

    expect(
      tester.getTopLeft(find.byKey(const Key('home-pending-DSB-2025-0441'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('home-pending-TRF-2025-0123')))
            .dy,
      ),
    );
    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
  });

  testWidgets('home keeps only the latest two when more are pending', (
    tester,
  ) async {
    await _pump(
      tester,
      configureLedger: (ledger) {
        ledger.addPendingVaultReceipt(
          id: 'DSB-2026-1201',
          amountEgp: 150,
          createdAt: DateTime(2026, 12, 1),
        );
        ledger.addPendingVaultReceipt(
          id: 'DSB-2024-0101',
          amountEgp: 50,
          createdAt: DateTime(2024, 1, 1),
        );
      },
    );

    expect(find.text('5 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2026-1201')), findsNothing);
    expect(find.byKey(const Key('home-pending-RE-2026-1041')), findsNothing);
    expect(find.byKey(const Key('home-pending-DSB-2024-0101')), findsNothing);
    expect(find.text('Received from Sami Hassan'), findsNothing);
  });

  testWidgets('home shows an empty state when nothing is pending', (
    tester,
  ) async {
    await _pump(tester, seedApprovals: false);

    expect(find.byKey(const Key('home-all-caught-up')), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('No pending approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsNothing);
    expect(find.text('Received from Vault'), findsNothing);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
  });

  testWidgets('pending rows expose compact kind-specific inline actions', (
    tester,
  ) async {
    await _pump(tester);

    final approve = tester.getSize(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
    );
    expect(approve.height, lessThan(48));
    expect(approve.height, greaterThanOrEqualTo(40));

    expect(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-pending-decline-DSB-2025-0441')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('home-pending-reject-DSB-2025-0441')),
      findsNothing,
    );

    expect(
      find.byKey(const Key('home-pending-approve-TRF-2025-0123')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-pending-decline-TRF-2025-0123')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-pending-reject-TRF-2025-0123')),
      findsNothing,
    );
  });

  testWidgets('road expense preview keeps confirm and reject', (tester) async {
    await _pump(
      tester,
      configureLedger: (ledger) {
        // Drop the vault receipt so the seeded road expense enters the Home
        // preview (relative timings outrank calendar-only road expenses).
        ledger.approveVaultReceipt('DSB-2025-0441');
      },
    );

    expect(find.byKey(const Key('home-pending-RE-2026-1041')), findsOneWidget);
    expect(
      find.byKey(const Key('home-pending-confirm-RE-2026-1041')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-pending-reject-RE-2026-1041')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('home-pending-approve-RE-2026-1041')),
      findsNothing,
    );
  });

  testWidgets('tapping a pending row opens the details sheet on Home', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('home-pending-DSB-2025-0441')));
    await tester.pumpAndSettle();

    expect(find.text('Approve Cash Receipt'), findsOneWidget);
    expect(find.byKey(const Key('approval-approve')), findsOneWidget);
    expect(find.byKey(const Key('approval-cancel')), findsOneWidget);
    expect(find.text('Needs your decision'), findsNothing);
    expect(find.byKey(const Key('home-balance')), findsOneWidget);

    await tester.tap(find.byKey(const Key('approval-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Approve Cash Receipt'), findsNothing);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
  });

  testWidgets('busy pending rows do not open the details sheet', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pumpGatedApprove(tester, gate);

    await tester.tap(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
    );
    await tester.pump();

    expect(
      BlocProvider.of<ApprovalsBloc>(
        tester.element(find.byKey(const Key('home-pending-card'))),
      ).state.busy,
      isTrue,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('home-pending-DSB-2025-0441')),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('home-pending-DSB-2025-0441')));
    await tester.pump();
    expect(find.text('Approve Cash Receipt'), findsNothing);

    await tester.tap(find.byKey(const Key('home-pending-TRF-2025-0123')));
    await tester.pump();
    expect(find.text('Approve Cash from Driver'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsNothing);

    await tester.tap(find.byKey(const Key('home-pending-TRF-2025-0123')));
    await tester.pumpAndSettle();
    expect(find.text('Approve Cash from Driver'), findsOneWidget);

    await tester.tap(find.byKey(const Key('approval-close')));
    await tester.pumpAndSettle();
  });

  testWidgets('inline approve does not open the details sheet', (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
    );
    await tester.pump();
    expect(find.text('Approve Cash Receipt'), findsNothing);
    await tester.pumpAndSettle();

    expect(_text(tester, 'home-balance'), '4,200 EGP');
    expect(find.text('2 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsNothing);
    expect(
      find.byKey(const Key('home-pending-approve-DSB-2025-0441')),
      findsNothing,
    );
  });

  testWidgets('sheet approve credits the shared balance once', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('home-pending-DSB-2025-0441')));
    await tester.pumpAndSettle();
    expect(find.text('Approve Cash Receipt'), findsOneWidget);
    expect(find.text('4,200 EGP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();

    expect(find.text('Approve Cash Receipt'), findsNothing);
    expect(_text(tester, 'home-balance'), '4,200 EGP');
    expect(find.text('6,200 EGP'), findsNothing);
    expect(find.text('2 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsNothing);
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');

    await tester.tap(find.byKey(const Key('home-view-all-approvals')));
    await tester.pumpAndSettle();
    expect(find.text('Needs your decision'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );
    expect(find.text('2 pending'), findsOneWidget);
  });

  testWidgets('transfer decline is available and removes the preview row', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const Key('home-pending-decline-TRF-2025-0123')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsNothing);
    expect(find.text('2 pending'), findsOneWidget);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
  });
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Future<void> _pump(
  WidgetTester tester, {
  bool seedApprovals = true,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      home: HomeScope(
        now: () => DateTime(2026, 10, 20, 9),
        seedApprovals: seedApprovals,
        configureLedger: configureLedger,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await revealHomeFinance(tester);
}

/// HomeScope wiring with a vault-approve gate so ApprovalsBloc stays busy.
Future<void> _pumpGatedApprove(
  WidgetTester tester,
  Completer<void> gate,
) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

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
  )..seedDriverApprovals();
  final approvals = _GatedApprovalRepository(
    ApprovalRepositoryImpl(ledger),
    gate,
  );
  final finance = SessionFinanceRepository(
    const MockFinanceDataSource(),
    ledger,
  );
  final history = HistoryRepositoryImpl(ledger);
  final notifications = NotificationRepositoryImpl(
    SharedPreferencesNotificationDataSource(),
    seedFor: MockNotificationSeed.forDriver,
  );
  addTearDown(notifications.dispose);

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
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<DriverRepository>(
              create: (_) =>
                  const DriverRepositoryImpl(MockDriverDataSource()),
            ),
            RepositoryProvider<FinanceRepository>.value(value: finance),
            RepositoryProvider<ApprovalRepository>.value(value: approvals),
            RepositoryProvider<HistoryRepository>.value(value: history),
            RepositoryProvider<NotificationRepository>.value(
              value: notifications,
            ),
            RepositoryProvider<ExpenseRepository>(
              create: (_) => ExpenseRepositoryImpl(ledger),
            ),
            RepositoryProvider<CashTransferRepository>(
              create: (_) => CashTransferRepositoryImpl(ledger),
            ),
            RepositoryProvider<CashRequestRepository>(
              create: (_) => CashRequestRepositoryImpl(ledger),
            ),
          ],
            child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => FinanceVisibilityCubit()),
              BlocProvider(
                create: (context) => HomeBloc(
                  GetCurrentDriver(context.read<DriverRepository>()),
                  GetFinancialSummary(context.read<FinanceRepository>()),
                  watchFinanceChanges: WatchFinanceChanges(
                    context.read<FinanceRepository>(),
                  ),
                )..add(const HomeStarted()),
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
            child: HomePage(now: () => DateTime(2026, 10, 20, 9)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await revealHomeFinance(tester);
}

class _GatedApprovalRepository implements ApprovalRepository {
  _GatedApprovalRepository(this._inner, this._gate);

  final ApprovalRepository _inner;
  final Completer<void> _gate;

  @override
  Stream<void> get changes => _inner.changes;

  @override
  Future<List<ApprovalItem>> getApprovals(String driverId) =>
      _inner.getApprovals(driverId);

  @override
  Future<int> getAvailableBalance(String driverId) =>
      _inner.getAvailableBalance(driverId);

  @override
  Future<void> approveVaultReceipt({
    required String driverId,
    required String receiptId,
    DateTime? finalizedAt,
  }) async {
    await _gate.future;
    return _inner.approveVaultReceipt(
      driverId: driverId,
      receiptId: receiptId,
      finalizedAt: finalizedAt,
    );
  }

  @override
  Future<void> approveIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) => _inner.approveIncomingTransfer(
    driverId: driverId,
    transferId: transferId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> declineIncomingTransfer({
    required String driverId,
    required String transferId,
    DateTime? finalizedAt,
  }) => _inner.declineIncomingTransfer(
    driverId: driverId,
    transferId: transferId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> confirmRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) => _inner.confirmRoadExpense(
    driverId: driverId,
    approvalId: approvalId,
    finalizedAt: finalizedAt,
  );

  @override
  Future<void> rejectRoadExpense({
    required String driverId,
    required String approvalId,
    DateTime? finalizedAt,
  }) => _inner.rejectRoadExpense(
    driverId: driverId,
    approvalId: approvalId,
    finalizedAt: finalizedAt,
  );
}
