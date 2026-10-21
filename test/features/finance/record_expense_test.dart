import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_transfer_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/assigned_trip.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_attachment.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/failures/expense_exception.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/expense_repository.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/record_expense.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/send_cash.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 10, 20, 9);
  const attachment = ExpenseAttachment(
    id: 'ATT-1',
    name: 'receipt.jpg',
    path: '/tmp/receipt.jpg',
    kind: ExpenseAttachmentKind.image,
  );

  test('a valid expense is pending and stores the trip', () async {
    final harness = _Harness();
    final result = await harness.record(
      driverId: MockCashLedger.senderId,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: '  night fuel  ',
      attachments: const [attachment],
      createdAt: createdAt,
    );

    expect(result.expense.status, ExpenseStatus.recorded);
    expect(result.expense.driverId, 'DR-001');
    expect(result.expense.tripId, 'trip-2026-0927');
    expect(result.expense.settlementType, SettlementType.fuel);
    expect(result.expense.amountEgp, 300);
    expect(result.expense.notes, 'night fuel');
    expect(result.expense.attachments, [attachment]);
    expect(result.expense.createdAt, createdAt);
    expect(result.expense.id, 'EXP-412138');
    expect(result.balanceEgp, 1900);
    expect(harness.ledger.balanceOf('DR-001'), 1900);
    expect(harness.ledger.balanceOf('DR-003'), 1100);
    expect(
      (await harness.repository.getExpenses()).single.status,
      ExpenseStatus.recorded,
    );
  });

  test('active and completed trips are eligible', () async {
    final harness = _Harness();
    final trips = await harness.repository.getAssignedTrips(
      MockCashLedger.senderId,
    );

    expect(trips, hasLength(6));
    expect(trips.map((trip) => trip.id), isNot(contains('trip-2026-0600')));
    expect(trips.map((trip) => trip.id), isNot(contains('trip-2026-0700')));

    await harness.record(
      driverId: MockCashLedger.senderId,
      tripId: 'trip-2026-0904',
      settlementType: SettlementType.roadFeesClient,
      amountEgp: 100,
      createdAt: createdAt,
    );
    expect(harness.ledger.balanceOf('DR-001'), 2100);
  });

  test('zero and negative amounts are rejected without an expense', () async {
    final repository = _ThrowingRepository();
    final record = RecordExpense(repository);

    expect(
      () => record(
        driverId: 'DR-001',
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 0,
        notes: null,
        attachments: const [],
      ),
      throwsA(isA<InvalidExpenseAmountException>()),
    );
    expect(
      () => record(
        driverId: 'DR-001',
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: -50,
        notes: null,
        attachments: const [],
      ),
      throwsA(
        isA<InvalidExpenseAmountException>().having(
          (error) => error.amountEgp,
          'amountEgp',
          -50,
        ),
      ),
    );
    expect(repository.createCalls, 0);
  });

  test('a missing trip or settlement does not change the balance', () async {
    final repository = _ThrowingRepository();
    final record = RecordExpense(repository);

    expect(
      () => record(
        driverId: 'DR-001',
        tripId: null,
        settlementType: SettlementType.fuel,
        amountEgp: 100,
        notes: null,
        attachments: const [],
      ),
      throwsA(isA<MissingTripException>()),
    );
    expect(
      () => record(
        driverId: 'DR-001',
        tripId: 'trip-2026-0927',
        settlementType: null,
        amountEgp: 100,
        notes: null,
        attachments: const [],
      ),
      throwsA(isA<MissingSettlementTypeException>()),
    );
    expect(repository.createCalls, 0);
  });

  test('an amount above the balance changes nothing', () async {
    final harness = _Harness();

    expect(
      () => harness.record(
        driverId: MockCashLedger.senderId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 2201,
        createdAt: createdAt,
      ),
      throwsA(isA<InsufficientExpenseBalanceException>()),
    );
    expect(harness.ledger.balanceOf('DR-001'), 2200);
    expect(harness.ledger.expenses, isEmpty);
  });

  test('an ineligible trip and another driver trip are rejected', () async {
    final harness = _Harness();

    expect(
      () => harness.record(
        driverId: MockCashLedger.senderId,
        tripId: 'trip-2026-0600',
        settlementType: SettlementType.maintenance,
        amountEgp: 100,
        createdAt: createdAt,
      ),
      throwsA(isA<IneligibleTripException>()),
    );
    expect(
      () => harness.record(
        driverId: MockCashLedger.senderId,
        tripId: 'trip-2026-0700',
        settlementType: SettlementType.maintenance,
        amountEgp: 100,
        createdAt: createdAt,
      ),
      throwsA(isA<TripAssignedToAnotherDriverException>()),
    );
    expect(
      () => harness.record(
        driverId: MockCashLedger.senderId,
        tripId: 'missing',
        settlementType: SettlementType.fuel,
        amountEgp: 100,
        createdAt: createdAt,
      ),
      throwsA(isA<IneligibleTripException>()),
    );
    expect(harness.ledger.balanceOf('DR-001'), 2200);
    expect(harness.ledger.expenses, isEmpty);
  });

  test(
    'a recorded expense cannot be approved, rejected, or refunded',
    () async {
      final harness = _Harness();
      final created = await harness.record(
        driverId: MockCashLedger.senderId,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 300,
        createdAt: createdAt,
      );

      expect(created.expense.status, ExpenseStatus.recorded);
      expect(
        () => harness.repository.approve(created.expense.id),
        throwsA(isA<ExpenseAlreadyFinalizedException>()),
      );
      expect(
        () => harness.repository.reject(created.expense.id),
        throwsA(isA<ExpenseAlreadyFinalizedException>()),
      );
      expect(
        () => harness.repository.cancel(created.expense.id),
        throwsA(isA<ExpenseCannotBeCancelledException>()),
      );
      expect(harness.ledger.balanceOf('DR-001'), 1900);
      expect(harness.ledger.expenses.single.status, ExpenseStatus.recorded);
    },
  );

  test('charge and max limit stay unchanged', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200);
    final expenses = ExpenseRepositoryImpl(ledger);
    final summary = SessionFinanceRepository(
      const MockFinanceDataSource(),
      ledger,
    );

    await RecordExpense(expenses)(
      driverId: MockCashLedger.senderId,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: null,
      attachments: const [],
      createdAt: createdAt,
    );
    final after = await summary.getFinancialSummary();

    expect(after.balanceEgp, 1900);
    expect(after.chargeEgp, 3200);
    expect(after.maxLimitEgp, 5000);
  });

  test('an expense and a transfer share one balance', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200);
    final expenses = ExpenseRepositoryImpl(ledger);
    final transfers = CashTransferRepositoryImpl(ledger);

    await RecordExpense(expenses)(
      driverId: MockCashLedger.senderId,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: null,
      attachments: const [],
      createdAt: createdAt,
    );
    final sent = await SendCash(transfers)(
      senderId: MockCashLedger.senderId,
      recipientId: 'DR-003',
      amountEgp: 500,
      createdAt: createdAt,
    );

    expect(sent.senderBalanceEgp, 1400);
    expect(sent.transfer.status, TransferStatus.pending);
    expect(ledger.balanceOf('DR-003'), 1100);
    expect(ledger.expenses.single.status, ExpenseStatus.recorded);
    expect(ledger.transfers.single.status, TransferStatus.pending);
  });
}

class _Harness {
  final MockCashLedger ledger;
  final ExpenseRepository repository;
  final RecordExpense record;

  _Harness._(this.ledger, this.repository) : record = RecordExpense(repository);

  factory _Harness() {
    final ledger = MockCashLedger(senderBalanceEgp: 2200);
    return _Harness._(ledger, ExpenseRepositoryImpl(ledger));
  }
}

class _ThrowingRepository implements ExpenseRepository {
  int createCalls = 0;

  @override
  Future<ExpenseRequest> createRecordedExpense({
    required String driverId,
    required String tripId,
    required SettlementType settlementType,
    required int amountEgp,
    required String? notes,
    required List<ExpenseAttachment> attachments,
    required DateTime createdAt,
  }) async {
    createCalls += 1;
    throw StateError('create should not be called');
  }

  @override
  Future<List<AssignedTrip>> getAssignedTrips(String driverId) async => [];

  @override
  Future<int> getAvailableBalance(String driverId) async => 2200;

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
