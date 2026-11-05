import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_event.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_state.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('History trips multi-select matching', () {
    final tripA = _expense(id: 'e-a', tripId: 'trip-a');
    final tripB = _expense(id: 'e-b', tripId: 'trip-b');
    final tripC = _expense(id: 'e-c', tripId: 'trip-c');
    final tripD = _expense(id: 'e-d', tripId: 'trip-d');
    final noTrip = _expense(id: 'e-none', tripId: '');
    final transfer = HistoryEntry(
      id: 't1',
      kind: HistoryKind.outgoing,
      amountEgp: 50,
      credit: false,
      createdAt: DateTime(2026, 10, 20, 12),
      updatedAt: DateTime(2026, 10, 20, 12),
      status: HistoryDisplayStatus.confirmed,
    );

    test('1. no trips selected leaves all expense trips visible', () {
      for (final entry in [tripA, tripB, tripC, noTrip]) {
        expect(
          entry.matchesTrip(filter: HistoryFilter.expenses, tripIds: const {}),
          isTrue,
        );
      }
    });

    test('2. one trip selected matches only that trip', () {
      expect(
        tripA.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-a'},
        ),
        isTrue,
      );
      expect(
        tripB.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-a'},
        ),
        isFalse,
      );
    });

    test('3. two trips selected uses OR matching', () {
      final selected = {'trip-a', 'trip-c'};
      expect(
        tripA.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected),
        isTrue,
      );
      expect(
        tripC.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected),
        isTrue,
      );
      expect(
        tripB.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected),
        isFalse,
      );
    });

    test('4. three or more trips selected matches any selected trip', () {
      final selected = {'trip-a', 'trip-c', 'trip-d'};
      expect(
        [tripA, tripC, tripD].every(
          (e) =>
              e.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected),
        ),
        isTrue,
      );
      expect(
        tripB.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected),
        isFalse,
      );
    });

    test('5. duplicate trip IDs cannot create duplicate selection state', () {
      final fromList = <String>{
        ...['trip-a', 'trip-a', 'trip-c'],
      };
      final draft = HistoryFilterDraft(
        filter: HistoryFilter.expenses,
        tripIds: fromList,
      );
      expect(draft.tripIds, {'trip-a', 'trip-c'});
      expect(draft.tripIds.length, 2);

      final next = Set<String>.from(draft.tripIds)..add('trip-a');
      expect(next, {'trip-a', 'trip-c'});
      expect(next.length, 2);
    });

    test('6. multiple trips compose with transaction type filter', () {
      final selected = {'trip-a', 'trip-c'};
      expect(
        tripA.matches(HistoryFilter.expenses) &&
            tripA.matchesTrip(
              filter: HistoryFilter.expenses,
              tripIds: selected,
            ),
        isTrue,
      );
      expect(transfer.matches(HistoryFilter.expenses), isFalse);
      expect(
        transfer.matchesTrip(
          filter: HistoryFilter.cashTransfers,
          tripIds: selected,
        ),
        isTrue,
        reason: 'trip filter is ignored outside expenses',
      );
    });

    test('7. multiple trips compose with from date', () {
      final early = _expense(
        id: 'early',
        tripId: 'trip-a',
        at: DateTime(2026, 10, 10, 8),
      );
      final late = _expense(
        id: 'late',
        tripId: 'trip-c',
        at: DateTime(2026, 10, 20, 8),
      );
      final selected = {'trip-a', 'trip-c'};
      final from = DateTime(2026, 10, 15);

      expect(
        early.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected) &&
            early.matchesDate(
              mode: HistoryDateMode.range,
              startDate: from,
              endDate: DateTime(2099, 1, 1),
            ),
        isFalse,
      );
      expect(
        late.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected) &&
            late.matchesDate(
              mode: HistoryDateMode.range,
              startDate: from,
              endDate: DateTime(2099, 1, 1),
            ),
        isTrue,
      );
    });

    test('8. multiple trips compose with to date', () {
      final early = _expense(
        id: 'early',
        tripId: 'trip-a',
        at: DateTime(2026, 10, 10, 8),
      );
      final late = _expense(
        id: 'late',
        tripId: 'trip-c',
        at: DateTime(2026, 10, 20, 8),
      );
      final selected = {'trip-a', 'trip-c'};
      final to = DateTime(2026, 10, 15);

      expect(
        early.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected) &&
            early.matchesDate(
              mode: HistoryDateMode.range,
              startDate: DateTime(2000, 1, 1),
              endDate: to,
            ),
        isTrue,
      );
      expect(
        late.matchesTrip(filter: HistoryFilter.expenses, tripIds: selected) &&
            late.matchesDate(
              mode: HistoryDateMode.range,
              startDate: DateTime(2000, 1, 1),
              endDate: to,
            ),
        isFalse,
      );
    });

    test('9. multiple trips compose with from/to date range', () {
      final inRange = _expense(
        id: 'in',
        tripId: 'trip-a',
        at: DateTime(2026, 10, 18, 8),
      );
      final outOfRange = _expense(
        id: 'out',
        tripId: 'trip-c',
        at: DateTime(2026, 10, 25, 8),
      );
      final selected = {'trip-a', 'trip-c'};

      expect(
        inRange.matchesTrip(
              filter: HistoryFilter.expenses,
              tripIds: selected,
            ) &&
            inRange.matchesDate(
              mode: HistoryDateMode.range,
              startDate: DateTime(2026, 10, 15),
              endDate: DateTime(2026, 10, 20),
            ),
        isTrue,
      );
      expect(
        outOfRange.matchesTrip(
              filter: HistoryFilter.expenses,
              tripIds: selected,
            ) &&
            outOfRange.matchesDate(
              mode: HistoryDateMode.range,
              startDate: DateTime(2026, 10, 15),
              endDate: DateTime(2026, 10, 20),
            ),
        isFalse,
      );
    });

    test('10. multiple trips compose with expense filter via HistoryState', () {
      final state = HistoryState(
        loading: false,
        filter: HistoryFilter.expenses,
        tripIds: const {'trip-a', 'trip-c'},
        entries: [tripA, tripB, tripC, transfer, noTrip],
      );
      expect(state.visible.map((e) => e.id), ['e-a', 'e-c']);
    });

    test('11. entry without trip does not match when trips are selected', () {
      expect(
        noTrip.matchesTrip(
          filter: HistoryFilter.expenses,
          tripIds: const {'trip-a'},
        ),
        isFalse,
      );
    });

    test('12. entry without trip remains eligible when no trips selected', () {
      expect(
        noTrip.matchesTrip(filter: HistoryFilter.expenses, tripIds: const {}),
        isTrue,
      );
    });
  });

  group('History trips multi-select reset', () {
    test(
      '13-14. clearing trips removes selection and restores unfiltered',
      () async {
        final ledger = MockCashLedger(senderBalanceEgp: 5000)
          ..seedDriverApprovals();
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

        final bloc = HistoryBloc(
          driverId: MockCashLedger.senderId,
          repository: HistoryRepositoryImpl(ledger),
        )..add(const HistoryStarted());
        addTearDown(bloc.close);
        await bloc.stream.firstWhere((state) => !state.loading);

        bloc.add(
          HistoryFiltersApplied(
            HistoryFilterDraft(
              filter: HistoryFilter.expenses,
              tripIds: const {'trip-2026-0927', 'trip-2026-0904'},
            ),
          ),
        );
        await bloc.stream.firstWhere((state) => state.tripIds.length == 2);
        expect(bloc.state.tripIds, {'trip-2026-0927', 'trip-2026-0904'});
        final filteredCount = bloc.state.visible.length;

        bloc.add(
          const HistoryFiltersApplied(
            HistoryFilterDraft(filter: HistoryFilter.expenses, tripIds: {}),
          ),
        );
        await bloc.stream.firstWhere((state) => state.tripIds.isEmpty);
        expect(bloc.state.tripIds, isEmpty);
        expect(bloc.state.visible.length, greaterThanOrEqualTo(filteredCount));

        bloc.add(
          HistoryFiltersApplied(
            HistoryFilterDraft(
              filter: HistoryFilter.expenses,
              tripIds: const {'trip-2026-0927'},
            ),
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state.tripIds.contains('trip-2026-0927'),
        );
        bloc.add(const HistoryFiltersReset());
        await bloc.stream.firstWhere((state) => state.tripIds.isEmpty);
        expect(bloc.state.filter, HistoryFilter.all);
        expect(bloc.state.tripIds, isEmpty);
      },
    );
  });

  group('History trips multi-select UI / localization', () {
    testWidgets('15. English multi-select state renders correctly', (
      tester,
    ) async {
      await _openHistoryWithTwoExpenses(tester);

      await tester.tap(find.byKey(const Key('history-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-filter-expenses')));
      await tester.pumpAndSettle();

      await _pickTrip(tester, 'trip-2026-0927');
      expect(find.text('1 trip selected'), findsOneWidget);

      await _pickTrip(tester, 'trip-2026-0904');
      expect(find.text('2 trips selected'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-filter-apply')));
      await tester.pumpAndSettle();
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Cross Border'), findsOneWidget);
      expect(find.text('Road Expense Approval'), findsOneWidget);
    });

    testWidgets('16. Arabic multi-select state renders correctly', (
      tester,
    ) async {
      await _openHistoryWithTwoExpenses(tester, locale: const Locale('ar'));

      await tester.tap(find.byKey(const Key('history-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history-filter-expenses')));
      await tester.pumpAndSettle();

      await _pickTrip(tester, 'trip-2026-0927');
      expect(find.text('رحلة واحدة محددة'), findsOneWidget);

      await _pickTrip(tester, 'trip-2026-0904');
      expect(find.text('رحلتان محددتان'), findsOneWidget);
    });

    testWidgets('17. long trip names do not overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Wrap(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: FilterChip(
                    label: const Text(
                      'TR-VERY-LONG-CODE · Extremely Long Origin City Name to Extremely Long Destination City Name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: true,
                    onSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final chipSize = tester.getSize(find.byType(FilterChip));
      expect(chipSize.width, lessThanOrEqualTo(280));
    });
  });
}

HistoryEntry _expense({
  required String id,
  required String tripId,
  DateTime? at,
}) {
  final stamp = at ?? DateTime(2026, 10, 20, 12);
  return HistoryEntry(
    id: id,
    kind: HistoryKind.expense,
    amountEgp: 10,
    credit: false,
    createdAt: stamp,
    updatedAt: stamp,
    status: HistoryDisplayStatus.recorded,
    tripId: tripId,
    tripCode: tripId.isEmpty ? '' : 'TR-$tripId',
  );
}

/// Opens the trip picker from the filter sheet, adds [tripId], and returns.
Future<void> _pickTrip(WidgetTester tester, String tripId) async {
  await tester.tap(find.byKey(const Key('history-trip-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('history-trip-$tripId')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('history-trip-done')));
  await tester.pumpAndSettle();
}

Future<void> _openHistoryWithTwoExpenses(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScope(
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
