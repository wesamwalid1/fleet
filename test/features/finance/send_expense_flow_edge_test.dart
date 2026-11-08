import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_transfer_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_attachment.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/expense_attachment_picker.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/record_expense.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/send_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_event.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/send_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/send_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/pages/record_expense_flow_page.dart';
import 'package:driver_portal_app/features/finance/presentation/pages/send_cash_flow_page.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/record_expense_success.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/send_cash_success.dart';
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
  testWidgets('send cash failure stays on review and retries once', (
    tester,
  ) async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = _FailingTransferRepository(ledger);
    await _pumpSendFlow(tester, ledger: ledger, repository: repository);

    await tester.ensureVisible(
      find.byKey(const Key('send-cash-driver-DR-003')),
    );
    await tester.tap(find.byKey(const Key('send-cash-driver-DR-003')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-cash-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Review transfer'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('send-cash-submit')));
    await tester.tap(find.byKey(const Key('send-cash-submit')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.byType(RequestSentPage), findsNothing);
    expect(find.text('Review transfer'), findsOneWidget);
    expect(find.byKey(const Key('send-cash-error')), findsOneWidget);
    expect(find.text('Could not send the request.'), findsOneWidget);
    expect(find.text('Khaled Ramadan'), findsWidgets);
    expect(find.textContaining('500'), findsWidgets);
    expect(ledger.transfers, isEmpty);
    expect(ledger.balanceOf(_me), 2200);

    repository.fail = false;
    await tester.tap(find.byKey(const Key('send-cash-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(RequestSentPage), findsOneWidget);
    expect(find.text('Request Sent!'), findsOneWidget);
    expect(find.textContaining('TRF-'), findsWidgets);
    expect(repository.createCalls, 2);
    expect(find.byType(RequestSentPage), findsOneWidget);
  });

  testWidgets('record expense failure stays on review and retries once', (
    tester,
  ) async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);
    final repository = _FailingExpenseRepository(ledger);
    await _pumpExpenseFlow(tester, ledger: ledger, repository: repository);

    await tester.ensureVisible(
      find.byKey(const Key('expense-trip-trip-2026-0927')),
    );
    await tester.tap(find.byKey(const Key('expense-trip-trip-2026-0927')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('expense-settlement-fuel')),
    );
    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-continue')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('expense-notes')),
      ' keep note ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-camera')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense-remove-ATT-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Review expense'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('expense-confirm')));
    await tester.tap(find.byKey(const Key('expense-confirm')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.byType(ExpenseRecordedPage), findsNothing);
    expect(find.text('Review expense'), findsOneWidget);
    expect(find.byKey(const Key('expense-error')), findsOneWidget);
    expect(find.text('Could not record the expense.'), findsOneWidget);
    expect(find.text('TR-2026-0927'), findsWidgets);
    expect(find.text('Fuel'), findsWidgets);
    expect(find.text('keep note'), findsOneWidget);
    expect(
      find.byKey(const Key('expense-confirm-attachment-ATT-1')),
      findsOneWidget,
    );
    expect(ledger.expenses, isEmpty);
    expect(ledger.balanceOf(_me), 2200);

    repository.fail = false;
    await tester.tap(find.byKey(const Key('expense-confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseRecordedPage), findsOneWidget);
    expect(find.text('Expense Recorded'), findsOneWidget);
    expect(find.textContaining('EXP-'), findsWidgets);
    expect(repository.createCalls, 2);
    expect(find.byType(ExpenseRecordedPage), findsOneWidget);
  });
}

Future<void> _pumpSendFlow(
  WidgetTester tester, {
  required MockCashLedger ledger,
  required CashTransferRepositoryImpl repository,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    withConnectivity(
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
              create: (_) => SendCashBloc(
                senderId: _me,
                sendCash: SendCash(repository),
                repository: repository,
              )..add(const SendCashStarted()),
              child: const SendCashFlowPage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final connectivity = tester
      .element(find.byType(SendCashFlowPage))
      .read<ConnectivityBloc>();
  if (!connectivity.state.isOnline) {
    connectivity.add(const ConnectivityRetryRequested());
    await tester.pumpAndSettle();
  }
  expect(connectivity.state.isOnline, isTrue);
}

Future<void> _pumpExpenseFlow(
  WidgetTester tester, {
  required MockCashLedger ledger,
  required ExpenseRepositoryImpl repository,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    withConnectivity(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RepositoryProvider<ExpenseAttachmentPicker>.value(
            value: _FakePicker(),
            child: BlocProvider(
              create: (_) => HomeBloc(
                GetCurrentDriver(
                  const DriverRepositoryImpl(MockDriverDataSource()),
                ),
                GetFinancialSummary(
                  SessionFinanceRepository(
                    const MockFinanceDataSource(),
                    ledger,
                  ),
                ),
              ),
              child: BlocProvider(
                create: (_) => RecordExpenseBloc(
                  driverId: _me,
                  recordExpense: RecordExpense(repository),
                  repository: repository,
                  tripScope: ExpenseTripScope.anyTrip,
                )..add(const RecordExpenseStarted()),
                child: const RecordExpenseFlowPage(picker: _FakePicker()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final connectivity = tester
      .element(find.byType(RecordExpenseFlowPage))
      .read<ConnectivityBloc>();
  if (!connectivity.state.isOnline) {
    connectivity.add(const ConnectivityRetryRequested());
    await tester.pumpAndSettle();
  }
  expect(connectivity.state.isOnline, isTrue);
}

class _FailingTransferRepository extends CashTransferRepositoryImpl {
  bool fail = true;
  int createCalls = 0;

  _FailingTransferRepository(super.ledger);

  @override
  Future<CashTransfer> createPendingTransfer({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    required DateTime createdAt,
  }) async {
    createCalls += 1;
    if (fail) throw Exception('submit failed');
    return super.createPendingTransfer(
      senderId: senderId,
      recipientId: recipientId,
      amountEgp: amountEgp,
      createdAt: createdAt,
    );
  }
}

class _FailingExpenseRepository extends ExpenseRepositoryImpl {
  bool fail = true;
  int createCalls = 0;

  _FailingExpenseRepository(super.ledger);

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
  }) async {
    createCalls += 1;
    if (fail) throw Exception('submit failed');
    return super.createRecordedExpense(
      driverId: driverId,
      tripId: tripId,
      settlementType: settlementType,
      amountEgp: amountEgp,
      notes: notes,
      attachments: attachments,
      createdAt: createdAt,
      tripScope: tripScope,
    );
  }
}

class _FakePicker implements ExpenseAttachmentPicker {
  const _FakePicker();

  @override
  Future<ExpenseAttachment?> pickCamera() async {
    return const ExpenseAttachment(
      id: 'ATT-1',
      name: 'receipt.pdf',
      path: '/tmp/receipt.pdf',
      kind: ExpenseAttachmentKind.file,
    );
  }

  @override
  Future<ExpenseAttachment?> pickGallery() async => null;

  @override
  Future<ExpenseAttachment?> pickFile() async => null;
}
