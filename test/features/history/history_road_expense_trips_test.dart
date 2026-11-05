import 'dart:async';

import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/domain/repositories/history_repository.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/history/presentation/history_format.dart';
import 'package:driver_portal_app/features/history/presentation/pages/history_page.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_ledger_row.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/transaction_detail_sheet.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  group('road expense mapping', () {
    test(
      'RE-2026-1041 maps once with related trips and no tripCode misuse',
      () async {
        final ledger = MockCashLedger(senderBalanceEgp: 2200)
          ..seedDriverApprovals();
        final entries = await HistoryRepositoryImpl(ledger)
            .getHistory(MockCashLedger.senderId);
        final road = entries.where((e) => e.id == 'RE-2026-1041');
        expect(road, hasLength(1));
        final entry = road.single;
        expect(entry.kind, HistoryKind.roadExpense);
        expect(entry.id, 'RE-2026-1041');
        expect(entry.tripCode, isEmpty);
        expect(entry.tripId, isEmpty);
        expect(entry.relatedTripCodes, [
          'TR-2026-0881',
          'TR-2026-0904',
          'TR-2026-0927',
        ]);
        expect(entry.relatedTripIds, [
          'trip-2026-0881',
          'trip-2026-0904',
          'trip-2026-0927',
        ]);
      },
    );
  });

  group('road expense trip matching', () {
    late HistoryEntry road;
    late HistoryEntry ordinary;

    setUp(() {
      road = HistoryEntry(
        id: 'RE-2026-1041',
        kind: HistoryKind.roadExpense,
        amountEgp: 300,
        credit: false,
        createdAt: DateTime(2026, 6, 22, 10, 15),
        updatedAt: DateTime(2026, 6, 22, 10, 15),
        status: HistoryDisplayStatus.awaitingApproval,
        relatedTripIds: const [
          'trip-2026-0881',
          'trip-2026-0904',
          'trip-2026-0927',
        ],
        relatedTripCodes: const [
          'TR-2026-0881',
          'TR-2026-0904',
          'TR-2026-0927',
        ],
      );
      ordinary = HistoryEntry(
        id: 'EXP-1',
        kind: HistoryKind.expense,
        amountEgp: 100,
        credit: false,
        createdAt: DateTime(2026, 10, 21, 10),
        updatedAt: DateTime(2026, 10, 21, 10),
        status: HistoryDisplayStatus.recorded,
        tripId: 'trip-2026-0927',
        tripCode: 'TR-2026-0927',
        settlementType: SettlementType.fuel,
      );
    });

    test('each related trip independently matches the same Approval', () {
      for (final id in road.relatedTripIds) {
        expect(
          road.matchesTrip(filter: HistoryFilter.expenses, tripIds: {id}),
          isTrue,
        );
      }
    });

    test('selecting two matching trips still returns the Approval once', () {
      final selected = {'trip-2026-0927', 'trip-2026-0904'};
      final visible = [
        for (final entry in [ordinary, road])
          if (entry.matchesTrip(
            filter: HistoryFilter.expenses,
            tripIds: selected,
          ))
            entry,
      ];
      expect(visible.where((e) => e.id == 'RE-2026-1041'), hasLength(1));
      expect(visible.any((e) => e.id == 'EXP-1'), isTrue);
    });

    test('an unrelated trip does not match the Approval', () {
      expect(
        road.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-2026-0812'},
        ),
        isFalse,
      );
    });

    test('ordinary Record Expense matching remains unchanged', () {
      expect(
        ordinary.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-2026-0927'},
        ),
        isTrue,
      );
      expect(
        ordinary.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-2026-0904'},
        ),
        isFalse,
      );
    });

    test('no selected trips preserves unfiltered behavior', () {
      expect(
        road.matchesTrip(filter: HistoryFilter.expenses, tripIds: const {}),
        isTrue,
      );
      expect(
        ordinary.matchesTrip(filter: HistoryFilter.expenses, tripIds: const {}),
        isTrue,
      );
    });

    test('unknown related codes without ids never match a trip filter', () {
      final unresolved = HistoryEntry(
        id: 'RE-UNKNOWN',
        kind: HistoryKind.roadExpense,
        amountEgp: 50,
        credit: false,
        createdAt: DateTime(2026, 6, 22),
        updatedAt: DateTime(2026, 6, 22),
        status: HistoryDisplayStatus.awaitingApproval,
        relatedTripCodes: const ['TR-MISSING'],
      );
      expect(
        unresolved.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-2026-0927'},
        ),
        isFalse,
      );
    });
  });

  group('road expense search and details', () {
    testWidgets('Approval ID and each related trip code find the Approval', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final entry = HistoryEntry(
        id: 'RE-2026-1041',
        kind: HistoryKind.roadExpense,
        amountEgp: 300,
        credit: false,
        createdAt: DateTime(2026, 6, 22, 10, 15),
        updatedAt: DateTime(2026, 6, 22, 10, 15),
        status: HistoryDisplayStatus.awaitingApproval,
        relatedTripIds: const [
          'trip-2026-0881',
          'trip-2026-0904',
          'trip-2026-0927',
        ],
        relatedTripCodes: const [
          'TR-2026-0881',
          'TR-2026-0904',
          'TR-2026-0927',
        ],
      );
      expect(historyMatches(l10n, entry, 'RE-2026-1041'), isTrue);
      for (final code in entry.relatedTripCodes) {
        expect(historyMatches(l10n, entry, code), isTrue);
      }
      expect(historyMatches(l10n, entry, 'TR-MISSING'), isFalse);
    });

    testWidgets('detail lists related trip codes without duplicating them', (
      tester,
    ) async {
      final entry = HistoryEntry(
        id: 'RE-2026-1041',
        kind: HistoryKind.roadExpense,
        amountEgp: 300,
        credit: false,
        createdAt: DateTime(2026, 6, 22, 10, 15),
        updatedAt: DateTime(2026, 6, 22, 10, 15),
        status: HistoryDisplayStatus.awaitingApproval,
        note: 'Admin · Hassan Allam',
        relatedTripCodes: const [
          'TR-2026-0881',
          'TR-2026-0904',
          'TR-2026-0927',
        ],
      );
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _localized(Scaffold(body: TransactionDetailSheet(entry: entry))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Related trips'), findsOneWidget);
      expect(find.text('RE-2026-1041'), findsOneWidget);
      expect(find.text('TR-2026-0881'), findsOneWidget);
      expect(find.text('TR-2026-0904'), findsOneWidget);
      expect(find.text('TR-2026-0927'), findsOneWidget);
      expect(find.text('Trip Code'), findsNWidgets(3));
    });

    testWidgets('list shows Approval ID as the operation reference', (
      tester,
    ) async {
      final entry = HistoryEntry(
        id: 'RE-2026-1041',
        kind: HistoryKind.roadExpense,
        amountEgp: 300,
        credit: false,
        createdAt: DateTime(2026, 6, 22, 10, 15),
        updatedAt: DateTime(2026, 6, 22, 10, 15),
        status: HistoryDisplayStatus.awaitingApproval,
        relatedTripCodes: const ['TR-2026-0927'],
        relatedTripIds: const ['trip-2026-0927'],
      );
      await tester.pumpWidget(
        _localized(
          Scaffold(
            body: HistoryLedgerRow(
              entry: entry,
              when: '10:15 AM',
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is HistoryReferenceLine &&
              widget.reference == 'RE-2026-1041' &&
              widget.status.startsWith('Awaiting your approval'),
        ),
        findsOneWidget,
      );
    });
  });

  group('road expense filter UI', () {
    testWidgets('trip filtering keeps matching Road Expenses visible', (
      tester,
    ) async {
      await _openHistory(tester);
      await tester.tap(find.byKey(const Key('history-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-filter-expenses')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-road-trip-note')), findsNothing);
      await tester.tap(find.byKey(const Key('history-trip-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-trip-2026-0927')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-trip-2026-0904')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-trip-done')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-filter-apply')));
      await tester.pumpAndSettle();

      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Road Expense Approval'), findsOneWidget);
      expect(
        find.byKey(const Key('history-entry-RE-2026-1041')),
        findsOneWidget,
      );
    });
  });

  group('history refresh', () {
    testWidgets('approval revision refreshes without a full-screen spinner', (
      tester,
    ) async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final history = HistoryRepositoryImpl(ledger);
      final approvals = ApprovalRepositoryImpl(ledger);
      late ApprovalsBloc approvalsBloc;
      await tester.pumpWidget(
        _localized(
          withConnectivity(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => HistoryBloc(
                    driverId: MockCashLedger.senderId,
                    repository: history,
                  )..add(const HistoryStarted()),
                ),
                BlocProvider(
                  create: (context) {
                    approvalsBloc = ApprovalsBloc(
                      driverId: MockCashLedger.senderId,
                      repository: approvals,
                      approveVaultReceipt: ApproveVaultReceipt(approvals),
                      approveIncomingTransfer: ApproveIncomingTransfer(
                        approvals,
                      ),
                      declineIncomingTransfer: DeclineIncomingTransfer(
                        approvals,
                      ),
                      confirmRoadExpense: ConfirmRoadExpense(approvals),
                      rejectRoadExpense: RejectRoadExpense(approvals),
                    )..add(const ApprovalsStarted());
                    return approvalsBloc;
                  },
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
      expect(find.text('Road Expense Approval'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      approvalsBloc.add(
        const ApprovalActionRequested(
          id: 'RE-2026-1041',
          command: ApprovalCommand.confirmRoad,
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Road Expense Approval'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is HistoryReferenceLine &&
              widget.reference == 'RE-2026-1041' &&
              widget.status.startsWith('Approved'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('refresh failure keeps entries and shows a retry banner', (
      tester,
    ) async {
      final repository = _ControllableHistoryRepository([
        [
          HistoryEntry(
            id: 'RE-2026-1041',
            kind: HistoryKind.roadExpense,
            amountEgp: 300,
            credit: false,
            createdAt: DateTime(2026, 6, 22, 10, 15),
            updatedAt: DateTime(2026, 6, 22, 10, 15),
            status: HistoryDisplayStatus.awaitingApproval,
            relatedTripCodes: const ['TR-2026-0927'],
            relatedTripIds: const ['trip-2026-0927'],
          ),
        ],
        null,
        [
          HistoryEntry(
            id: 'RE-2026-1041',
            kind: HistoryKind.roadExpense,
            amountEgp: 300,
            credit: false,
            createdAt: DateTime(2026, 6, 22, 10, 15),
            updatedAt: DateTime(2026, 6, 22, 11),
            status: HistoryDisplayStatus.approved,
            relatedTripCodes: const ['TR-2026-0927'],
            relatedTripIds: const ['trip-2026-0927'],
          ),
        ],
      ]);
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
                  ),
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
      expect(find.text('Road Expense Approval'), findsOneWidget);
      expect(find.byKey(const Key('history-refresh-failed')), findsNothing);

      final bloc = tester.element(find.byType(HistoryPage)).read<HistoryBloc>();
      bloc.add(const HistoryRefreshed());
      await tester.pumpAndSettle();

      expect(find.text('Road Expense Approval'), findsOneWidget);
      expect(find.byKey(const Key('history-load-error')), findsNothing);
      expect(find.byKey(const Key('history-refresh-failed')), findsOneWidget);
      expect(find.text("Couldn't refresh"), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-refresh-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-refresh-failed')), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is HistoryReferenceLine &&
              widget.reference == 'RE-2026-1041' &&
              widget.status.startsWith('Approved'),
        ),
        findsOneWidget,
      );
    });
  });
}

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
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-history')));
  await tester.pumpAndSettle();
}

Widget _localized(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
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

/// Returns scripted history pages. A null page throws to simulate refresh failure.
class _ControllableHistoryRepository implements HistoryRepository {
  final List<List<HistoryEntry>?> pages;
  int calls = 0;
  final _controller = StreamController<void>.broadcast();

  _ControllableHistoryRepository(this.pages);

  @override
  Stream<void> get changes => _controller.stream;

  @override
  Future<List<HistoryEntry>> getHistory(String driverId) async {
    final index = calls.clamp(0, pages.length - 1);
    calls += 1;
    final page = pages[index];
    if (page == null) throw StateError('refresh failed');
    return page;
  }
}
