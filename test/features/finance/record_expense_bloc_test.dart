import 'dart:async';

import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/features/finance/domain/entities/assigned_trip.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_attachment.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/expense_repository.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/record_expense.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_event.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const attachment = ExpenseAttachment(
    id: 'ATT-1',
    name: 'note.pdf',
    path: '/tmp/note.pdf',
    kind: ExpenseAttachmentKind.file,
  );

  test('loads assigned trips and the available balance', () async {
    final repository = _FakeExpenses();
    final bloc = _bloc(repository);

    bloc.add(const RecordExpenseStarted());
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) =>
              !state.loading &&
              state.balanceEgp == 2200 &&
              state.trips.length == 2 &&
              state.visibleTrips.length == 2,
        ),
      ),
    );
    await bloc.close();
  });

  test('a preselected eligible trip is applied once trips load', () async {
    final bloc = _bloc(_FakeExpenses(), initialTripId: 'trip-2026-0927');
    bloc.add(const RecordExpenseStarted());
    final loaded = await bloc.stream.firstWhere((state) => !state.loading);

    expect(loaded.tripId, 'trip-2026-0927');
    expect(loaded.selectedTrip?.code, 'TR-2026-0927');
    expect(loaded.error, isNull);
    await bloc.close();
  });

  test('a preselected trip that is not eligible is not applied', () async {
    for (final id in ['trip-2026-0904', 'trip-unknown']) {
      final bloc = _bloc(_FakeExpenses(), initialTripId: id);
      bloc.add(const RecordExpenseStarted());
      final loaded = await bloc.stream.firstWhere((state) => !state.loading);

      expect(loaded.tripId, isNull);
      await bloc.close();
    }
  });

  test('the any-trip scope selects and submits a completed trip', () async {
    final repository = _FakeExpenses();
    final bloc = _bloc(repository, tripScope: ExpenseTripScope.anyTrip);
    bloc.add(const RecordExpenseStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    bloc
      ..add(const RecordExpenseTripSelected('trip-2026-0904'))
      ..add(const RecordExpenseSettlementSelected(SettlementType.fuel))
      ..add(const RecordExpenseAmountChanged(300))
      ..add(const RecordExpenseReviewRequested());
    final review = await bloc.stream.firstWhere(
      (state) => state.stage == RecordExpenseStage.confirm,
    );
    expect(review.tripId, 'trip-2026-0904');
    expect(review.error, isNull);

    bloc.add(const RecordExpenseSubmitted());
    final done = await bloc.stream.firstWhere((state) => state.result != null);
    expect(done.result!.expense.tripId, 'trip-2026-0904');
    expect(repository.lastTripScope, ExpenseTripScope.anyTrip);
    await bloc.close();
  });

  test('search filters by code and route', () async {
    final bloc = _bloc(_FakeExpenses());
    bloc.add(const RecordExpenseStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    bloc.add(const RecordExpenseTripQueryChanged('suez'));
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) => state.visibleTrips.length == 2,
        ),
      ),
    );

    bloc.add(const RecordExpenseTripQueryChanged('0904'));
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) => state.visibleTrips.single.id == 'trip-2026-0904',
        ),
      ),
    );
    await bloc.close();
  });

  test('a completed trip stays searchable but cannot be selected', () async {
    final bloc = _bloc(_FakeExpenses());
    bloc.add(const RecordExpenseStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    bloc.add(const RecordExpenseTripQueryChanged('0904'));
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) =>
              state.visibleTrips.single.id == 'trip-2026-0904' &&
              !state.visibleTrips.single.isEligible,
        ),
      ),
    );

    bloc.add(const RecordExpenseTripSelected('trip-2026-0904'));
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) =>
              state.tripId == null &&
              state.error == RecordExpenseError.ineligibleTrip,
        ),
      ),
    );

    bloc.add(const RecordExpenseTripSelected('trip-2026-0927'));
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) =>
              state.tripId == 'trip-2026-0927' &&
              state.selectedTrip!.isEligible &&
              state.error == null,
        ),
      ),
    );
    await bloc.close();
  });

  test('settlement, amount, and notes update the balance preview', () async {
    final bloc = _bloc(_FakeExpenses());
    bloc.add(const RecordExpenseStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(const RecordExpenseSettlementSelected(SettlementType.fuel));
    bloc.add(const RecordExpenseAmountChanged(44));
    bloc.add(const RecordExpenseNotesChanged('fuel stop'));
    bloc.add(const RecordExpenseAttachmentAdded(attachment));

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<RecordExpenseState>(
          (state) =>
              state.settlementType == SettlementType.fuel &&
              state.amountEgp == 44 &&
              state.balanceAfterEgp == 2156 &&
              state.notes == 'fuel stop' &&
              state.attachments.length == 1 &&
              state.attachments.first == attachment,
        ),
      ),
    );
    await bloc.close();
  });

  test('a valid review then submit records a pending expense', () async {
    final repository = _FakeExpenses();
    final bloc = _bloc(repository);
    bloc.add(const RecordExpenseStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(const RecordExpenseTripSelected('trip-2026-0927'));
    bloc.add(const RecordExpenseSettlementSelected(SettlementType.fuel));
    bloc.add(const RecordExpenseAmountChanged(300));
    bloc.add(const RecordExpenseNotesChanged('night'));
    await bloc.stream.firstWhere(
      (state) => state.canReview && state.notes == 'night',
    );

    bloc.add(const RecordExpenseReviewRequested());
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) =>
              state.stage == RecordExpenseStage.confirm &&
              repository.createCalls == 0,
        ),
      ),
    );

    bloc.add(const RecordExpenseSubmitted());
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<RecordExpenseState>(
          (state) =>
              state.stage == RecordExpenseStage.recorded &&
              state.result!.expense.status == ExpenseStatus.recorded &&
              state.result!.expense.tripId == 'trip-2026-0927' &&
              state.result!.balanceEgp == 1900 &&
              state.balanceEgp == 1900,
        ),
      ),
    );
    expect(repository.createCalls, 1);
    expect(repository.balance, 1900);
    await bloc.close();
  });

  test(
    'invalid submission shows feedback and does not create a request',
    () async {
      final repository = _FakeExpenses();
      final bloc = _bloc(repository);
      bloc.add(const RecordExpenseStarted());
      await bloc.stream.firstWhere((state) => !state.loading);

      bloc.add(const RecordExpenseReviewRequested());
      await expectLater(
        bloc.stream,
        emits(
          predicate<RecordExpenseState>(
            (state) => state.error == RecordExpenseError.selectTrip,
          ),
        ),
      );

      bloc.add(const RecordExpenseTripSelected('trip-2026-0927'));
      await bloc.stream.firstWhere((state) => state.tripId != null);
      bloc.add(const RecordExpenseReviewRequested());
      await expectLater(
        bloc.stream,
        emits(
          predicate<RecordExpenseState>(
            (state) => state.error == RecordExpenseError.selectSettlement,
          ),
        ),
      );
      expect(repository.createCalls, 0);
      expect(repository.balance, 2200);
      await bloc.close();
    },
  );

  test('a second submit is ignored while the first is in progress', () async {
    final completer = Completer<ExpenseRequest>();
    final repository = _FakeExpenses(pending: completer);
    final bloc = _bloc(repository);
    bloc.add(const RecordExpenseStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(const RecordExpenseTripSelected('trip-2026-0927'));
    bloc.add(const RecordExpenseSettlementSelected(SettlementType.fuel));
    bloc.add(const RecordExpenseAmountChanged(300));
    await bloc.stream.firstWhere((state) => state.canReview);
    bloc.add(const RecordExpenseReviewRequested());
    await bloc.stream.firstWhere(
      (state) => state.stage == RecordExpenseStage.confirm,
    );

    bloc.add(const RecordExpenseSubmitted());
    await expectLater(
      bloc.stream,
      emits(predicate<RecordExpenseState>((state) => state.submitting)),
    );
    bloc.add(const RecordExpenseSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(repository.createCalls, 1);
    completer.complete(repository.recorded);
    await expectLater(
      bloc.stream,
      emits(
        predicate<RecordExpenseState>(
          (state) => state.result != null && !state.submitting,
        ),
      ),
    );
    expect(repository.createCalls, 1);
    await bloc.close();
  });
}

RecordExpenseBloc _bloc(
  _FakeExpenses repository, {
  String? initialTripId,
  ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
}) {
  return RecordExpenseBloc(
    driverId: 'DR-001',
    recordExpense: RecordExpense(repository),
    repository: repository,
    initialTripId: initialTripId,
    tripScope: tripScope,
  );
}

class _FakeExpenses implements ExpenseRepository {
  final Completer<ExpenseRequest>? pending;
  int createCalls = 0;
  ExpenseTripScope? lastTripScope;
  int balance = 2200;
  late final ExpenseRequest recorded = ExpenseRequest(
    id: 'EXP-412138',
    driverId: 'DR-001',
    tripId: 'trip-2026-0927',
    settlementType: SettlementType.fuel,
    amountEgp: 300,
    notes: 'night',
    attachments: const [],
    createdAt: DateTime(2026, 10, 20),
    status: ExpenseStatus.recorded,
  );

  _FakeExpenses({this.pending});

  @override
  Future<List<AssignedTrip>> getAssignedTrips(String driverId) async {
    return [
      AssignedTrip(
        id: 'trip-2026-0927',
        code: 'TR-2026-0927',
        driverId: 'DR-001',
        status: TripStatus.active,
        origin: const LocalizedString(en: 'Suez', ar: 'السويس'),
        destination: const LocalizedString(en: 'Cairo', ar: 'القاهرة'),
        date: DateTime(2026, 5, 28),
        vehicle: 'Telescope',
      ),
      AssignedTrip(
        id: 'trip-2026-0904',
        code: 'TR-2026-0904',
        driverId: 'DR-001',
        status: TripStatus.completed,
        origin: const LocalizedString(en: 'Alexandria', ar: 'الإسكندرية'),
        destination: const LocalizedString(en: 'Suez', ar: 'السويس'),
        date: DateTime(2026, 5, 14),
        vehicle: 'Telescope',
      ),
    ];
  }

  @override
  Future<int> getAvailableBalance(String driverId) async => balance;

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
  }) {
    createCalls += 1;
    lastTripScope = tripScope;
    if (pending != null) return pending!.future;
    balance -= amountEgp;
    return Future.value(
      ExpenseRequest(
        id: 'EXP-412138',
        driverId: driverId,
        tripId: tripId,
        settlementType: settlementType,
        amountEgp: amountEgp,
        notes: notes,
        attachments: attachments,
        createdAt: createdAt,
        status: ExpenseStatus.recorded,
      ),
    );
  }

  @override
  Future<ExpenseRequest> approve(String expenseId) =>
      throw UnimplementedError();

  @override
  Future<ExpenseRequest> reject(String expenseId) => throw UnimplementedError();

  @override
  Future<void> cancel(String expenseId) => throw UnimplementedError();

  @override
  Future<List<ExpenseRequest>> getExpenses() async => [];
}
