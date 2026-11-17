import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/domain/repositories/history_repository.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/history/presentation/pages/history_page.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/transaction_detail_sheet.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  group('balance change wording', () {
    testWidgets('expense shows the recorded deduction', (tester) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.expense, HistoryDisplayStatus.recorded, 2200, 2110),
      );
      expect(_value(tester, 'history-detail-balance-before'), '2,200 EGP');
      expect(_value(tester, 'history-detail-balance-after'), '2,110 EGP');
      expect(_note(tester), 'Deducted when recorded.');
    });

    testWidgets('road expense never changes the balance', (tester) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.roadExpense, HistoryDisplayStatus.approved),
      );
      expect(_value(tester, 'history-detail-balance-value'), 'No change');
      expect(_note(tester), "Road expenses don't affect your balance.");
      expect(
        find.byKey(const Key('history-detail-balance-before')),
        findsNothing,
      );
    });

    testWidgets('pending and approved vault receipts', (tester) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.vault, HistoryDisplayStatus.awaitingApproval),
      );
      expect(
        _value(tester, 'history-detail-balance-value'),
        'Not credited yet',
      );
      expect(_note(tester), 'Credited after you approve.');

      await _pumpDetails(
        tester,
        _entry(HistoryKind.vault, HistoryDisplayStatus.approved, 2200, 4200),
      );
      expect(_value(tester, 'history-detail-balance-after'), '4,200 EGP');
      expect(_note(tester), 'Credited when approved.');
    });

    testWidgets('a rejected incoming transfer was never credited', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.incoming, HistoryDisplayStatus.rejected),
      );
      expect(_value(tester, 'history-detail-balance-value'), 'No change');
      expect(_note(tester), 'Rejected, so it was never credited.');
    });

    testWidgets('rejected send cash keeps only the recorded deduction', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.outgoing, HistoryDisplayStatus.rejected, 2200, 2000),
      );
      expect(_value(tester, 'history-detail-balance-before'), '2,200 EGP');
      expect(_value(tester, 'history-detail-balance-after'), '2,000 EGP');
      expect(find.text('2,200 EGP'), findsOneWidget);
      expect(
        _note(tester),
        'Deducted when sent, then returned to your balance after rejection.',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('history-detail-timeline')),
          matching: find.text('Amount returned to your balance'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pending and rejected withdraw', (tester) async {
      await _pumpDetails(
        tester,
        _entry(
          HistoryKind.withdraw,
          HistoryDisplayStatus.pendingConfirm,
          2200,
          1700,
        ),
      );
      expect(
        _note(tester),
        'Deducted when requested. Returned to your balance if rejected.',
      );
      expect(find.text('Amount returned to your balance'), findsNothing);

      await _pumpDetails(
        tester,
        _entry(HistoryKind.withdraw, HistoryDisplayStatus.rejected, 2200, 1700),
      );
      expect(_value(tester, 'history-detail-balance-after'), '1,700 EGP');
      expect(
        _note(tester),
        'Deducted when requested, then returned to your balance after '
        'rejection.',
      );
      expect(find.text('Amount returned to your balance'), findsOneWidget);
    });

    testWidgets('pending and rejected request cash', (tester) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.requestCash, HistoryDisplayStatus.pendingConfirm),
      );
      expect(
        _value(tester, 'history-detail-balance-value'),
        'Not credited yet',
      );
      expect(_note(tester), 'Credited after approval.');

      await _pumpDetails(
        tester,
        _entry(HistoryKind.requestCash, HistoryDisplayStatus.rejected),
      );
      expect(_value(tester, 'history-detail-balance-value'), 'No change');
      expect(find.text('Amount returned to your balance'), findsNothing);
    });

    testWidgets('missing figures read Not recorded and are never rebuilt', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.incoming, HistoryDisplayStatus.approved),
      );
      expect(_value(tester, 'history-detail-balance-before'), 'Not recorded');
      expect(_value(tester, 'history-detail-balance-after'), 'Not recorded');
      expect(_note(tester), 'Credited when approved.');
    });

    testWidgets('Arabic wording uses the approved text', (tester) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.vault, HistoryDisplayStatus.awaitingApproval),
        locale: const Locale('ar'),
      );
      expect(_value(tester, 'history-detail-balance-value'), 'لم يضف بعد');

      await _pumpDetails(
        tester,
        _entry(HistoryKind.vault, HistoryDisplayStatus.approved),
        locale: const Locale('ar'),
      );
      expect(_value(tester, 'history-detail-balance-before'), 'غير مسجل');
      expect(_note(tester), 'أضيف عند الموافقة.');

      await _pumpDetails(
        tester,
        _entry(HistoryKind.outgoing, HistoryDisplayStatus.rejected, 2200, 2000),
        locale: const Locale('ar'),
      );
      expect(find.text('أعيد المبلغ إلى رصيدك'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('history-detail-timeline'))),
        ),
        TextDirection.rtl,
      );
    });
  });

  group('timeline', () {
    testWidgets('pending shows Created, then the current state', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.incoming, HistoryDisplayStatus.awaitingApproval),
      );
      final timeline = find.byKey(const Key('history-detail-timeline'));
      Finder inTimeline(Finder finder) =>
          find.descendant(of: timeline, matching: finder);
      expect(inTimeline(find.text('Created')), findsOneWidget);
      expect(inTimeline(find.text('Still pending')), findsOneWidget);
      expect(inTimeline(find.text('Current')), findsOneWidget);
      expect(
        inTimeline(find.textContaining('Awaiting your approval · since')),
        findsOneWidget,
      );
    });

    testWidgets('settled shows Created and its final status', (tester) async {
      await _pumpDetails(
        tester,
        _entry(
          HistoryKind.outgoing,
          HistoryDisplayStatus.confirmed,
          2200,
          2000,
        ),
      );
      final timeline = find.byKey(const Key('history-detail-timeline'));
      expect(
        find.descendant(of: timeline, matching: find.text('Confirmed')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: timeline, matching: find.text('Current')),
        findsNothing,
      );
    });

    testWidgets('a recorded expense has a single Recorded event', (
      tester,
    ) async {
      await _pumpDetails(
        tester,
        _entry(HistoryKind.expense, HistoryDisplayStatus.recorded, 2200, 2110),
      );
      final timeline = find.byKey(const Key('history-detail-timeline'));
      expect(
        find.descendant(of: timeline, matching: find.text('Recorded')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: timeline, matching: find.text('Created')),
        findsNothing,
      );
    });

    testWidgets(
      'road expense details list related trips and keep the Approval ID',
      (tester) async {
        await _pumpDetails(
          tester,
          _entry(
            HistoryKind.roadExpense,
            HistoryDisplayStatus.awaitingApproval,
          ),
        );
        expect(find.text('Related trips'), findsOneWidget);
        expect(find.text('Reference'), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.byKey(const Key('history-detail-related-trip-0')),
              )
              .data,
          'TR-2026-0881',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const Key('history-detail-related-trip-1')),
              )
              .data,
          'TR-2026-0904',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const Key('history-detail-related-trip-2')),
              )
              .data,
          'TR-2026-0927',
        );
        expect(find.text('ID-1'), findsWidgets);
      },
    );
  });

  group('trip filter', () {
    testWidgets('the picker searches, pins the selection, and clears', (
      tester,
    ) async {
      await _openHistory(tester);
      await tester.tap(find.byKey(const Key('history-filter-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-road-trip-note')), findsNothing);
      await tester.tap(find.byKey(const Key('history-filter-expenses')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-road-trip-note')), findsNothing);

      await tester.tap(find.byKey(const Key('history-trip-field')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-trip-picker')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('history-trip-search')),
        'suez',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('history-trip-trip-2026-0927')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('history-trip-trip-2026-0904')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('history-trip-trip-2026-0881')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('history-trip-search')),
        'zzz',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-trip-no-results')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('history-trip-search')),
        'TR-2026-0927',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-trip-2026-0927')));
      await tester.pumpAndSettle();
      expect(find.text('Selected · 1'), findsOneWidget);
      expect(find.text('Done · 1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-trip-clear-selection')));
      await tester.pumpAndSettle();
      expect(find.text('Selected · 1'), findsNothing);
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history-trip-picker-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-trip-picker')), findsNothing);
      expect(find.text('All Trips'), findsOneWidget);
    });

    testWidgets('pills show active filters and remove one at a time', (
      tester,
    ) async {
      await _openHistory(tester);
      await tester.tap(find.byKey(const Key('history-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-filter-expenses')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-trip-2026-0927')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-done')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-filter-apply')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history-pill-type')), findsOneWidget);
      expect(find.byKey(const Key('history-pill-trip')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('history-pill-trip')),
          matching: find.text('TR-2026-0927'),
        ),
        findsOneWidget,
      );
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Cross Border'), findsNothing);
      expect(find.text('Road Expense Approval'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('history-pill-trip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-pill-trip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-pill-trip')), findsNothing);
      expect(find.byKey(const Key('history-pill-type')), findsOneWidget);
      expect(find.text('Cross Border'), findsOneWidget);
      expect(find.text('Road Expense Approval'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-pill-type')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-pill-type')), findsNothing);
      expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    });
  });

  testWidgets('a failed load offers Retry that loads again', (tester) async {
    final repository = _FailingHistoryRepository();
    final ledger = MockCashLedger(senderBalanceEgp: 2200);
    final approvals = ApprovalRepositoryImpl(ledger);
    await tester.pumpWidget(
      _localized(
        withConnectivity(
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
              body: HistoryPage(now: () => DateTime(2026, 10, 21, 12)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-load-error')), findsOneWidget);
    expect(find.text("Couldn't load your history."), findsOneWidget);
    final calls = repository.calls;
    await tester.tap(find.byKey(const Key('history-retry')));
    await tester.pumpAndSettle();
    expect(repository.calls, calls + 1);
  });
}

HistoryEntry _entry(
  HistoryKind kind,
  HistoryDisplayStatus status, [
  int? before,
  int? after,
]) {
  final created = DateTime(2026, 10, 20, 9, 30);
  final settled =
      status != HistoryDisplayStatus.pendingConfirm &&
      status != HistoryDisplayStatus.awaitingApproval;
  return HistoryEntry(
    id: 'ID-1',
    kind: kind,
    amountEgp: kind == HistoryKind.outgoing ? 200 : 500,
    credit:
        kind == HistoryKind.vault ||
        kind == HistoryKind.incoming ||
        kind == HistoryKind.requestCash,
    createdAt: created,
    updatedAt: settled && kind != HistoryKind.expense
        ? DateTime(2026, 10, 20, 15, 5)
        : created,
    status: status,
    settlementType: kind == HistoryKind.expense ? SettlementType.fuel : null,
    tripCode: kind == HistoryKind.expense ? 'TR-2026-0927' : '',
    tripId: kind == HistoryKind.expense ? 'trip-2026-0927' : '',
    relatedTripIds: kind == HistoryKind.roadExpense
        ? const ['trip-2026-0881', 'trip-2026-0904', 'trip-2026-0927']
        : const [],
    relatedTripCodes: kind == HistoryKind.roadExpense
        ? const ['TR-2026-0881', 'TR-2026-0904', 'TR-2026-0927']
        : const [],
    counterpartyName: const LocalizedString(
      en: 'Khaled Ramadan',
      ar: 'خالد رمضان',
    ),
    counterpartyId: 'DR-003',
    note: kind == HistoryKind.roadExpense ? 'Admin · Hassan Allam' : null,
    requestNumber: 'WD-001',
    balanceBeforeEgp: before,
    balanceAfterEgp: after,
  );
}

Future<void> _pumpDetails(
  WidgetTester tester,
  HistoryEntry entry, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _localized(
      Scaffold(body: TransactionDetailSheet(entry: entry)),
      locale: locale,
      key: ValueKey(entry),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _localized(Widget home, {Locale locale = const Locale('en'), Key? key}) {
  return MaterialApp(
    key: key,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

String? _value(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data;

String? _note(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('history-detail-balance-note')))
    .data;

Future<void> _openHistory(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _localized(
      HomeScope(
        now: () => DateTime(2026, 10, 21, 12),
        configureLedger: (ledger) {
          ledger.createRecordedExpense(
            driverId: MockCashLedger.senderId,
            tripId: 'trip-2026-0927',
            settlementType: SettlementType.fuel,
            amountEgp: 100,
            notes: null,
            attachments: const [],
            createdAt: DateTime(2026, 10, 21, 10),
          );
          ledger.createRecordedExpense(
            driverId: MockCashLedger.senderId,
            tripId: 'trip-2026-0904',
            settlementType: SettlementType.crossBorder,
            amountEgp: 200,
            notes: null,
            attachments: const [],
            createdAt: DateTime(2026, 10, 21, 11),
            tripScope: ExpenseTripScope.anyTrip,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-history')));
  await tester.pumpAndSettle();
}

class _FailingHistoryRepository implements HistoryRepository {
  int calls = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) async {
    calls += 1;
    throw StateError('history unavailable');
  }
}
