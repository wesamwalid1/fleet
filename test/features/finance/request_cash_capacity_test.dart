import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/failures/cash_request_exception.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/request_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_event.dart';
import 'package:driver_portal_app/features/home/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = MockCashLedger.senderId;
final _at = DateTime(2026, 11, 3, 10);

MockCashLedger _ledger() =>
    MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000);

/// Asserts the figures and
/// Capacity = Max Limit − Total Balance − Pending Request Cash.
void _expectCapacity(
  MockCashLedger ledger, {
  required int total,
  required int pending,
  required int capacity,
}) {
  expect(ledger.totalBalance(_me), total, reason: 'total');
  expect(ledger.pendingRequestCash(_me), pending, reason: 'pending');
  expect(ledger.availableRequestCapacity(_me), capacity, reason: 'capacity');
  expect(
    ledger.availableRequestCapacity(_me),
    ledger.maxLimitEgp -
        ledger.totalBalance(_me) -
        ledger.pendingRequestCash(_me),
    reason: 'invariant',
  );
}

String _request(MockCashLedger ledger, int amount, {int minute = 0}) {
  return ledger
      .submitRequestCash(
        driverId: _me,
        amountEgp: amount,
        createdAt: _at.add(Duration(minutes: minute)),
      )
      .id;
}

void main() {
  group('scenarios with Max Limit 5,000 and Total 2,200', () {
    test('A: before any request', () {
      _expectCapacity(_ledger(), total: 2200, pending: 0, capacity: 2800);
    });

    test('B: a 1,000 pending request reduces capacity only', () {
      final ledger = _ledger();
      _request(ledger, 1000);

      expect(ledger.balanceOf(_me), 2200);
      expect(ledger.availableBalance(_me), 2200);
      expect(ledger.frozenBalance(_me), 0);
      _expectCapacity(ledger, total: 2200, pending: 1000, capacity: 1800);
    });

    test('C: approval credits once and keeps capacity unchanged', () {
      final ledger = _ledger();
      final id = _request(ledger, 1000);
      ledger.approveCashRequest(id, processedAt: _at);

      expect(ledger.balanceOf(_me), 3200);
      expect(ledger.transactions, hasLength(1));
      _expectCapacity(ledger, total: 3200, pending: 0, capacity: 1800);
    });

    test('D: rejection restores capacity without moving money', () {
      final ledger = _ledger();
      final id = _request(ledger, 1000);
      ledger.rejectCashRequest(id, processedAt: _at);

      expect(ledger.balanceOf(_me), 2200);
      expect(ledger.transactions, isEmpty);
      _expectCapacity(ledger, total: 2200, pending: 0, capacity: 2800);
    });
  });

  group('pending reservations', () {
    test('multiple pending requests reduce capacity cumulatively', () {
      final ledger = _ledger();
      _request(ledger, 1000);
      _request(ledger, 800, minute: 1);
      _expectCapacity(ledger, total: 2200, pending: 1800, capacity: 1000);
    });

    test('only pending requests are counted as reservations', () {
      final ledger = _ledger();
      final approved = _request(ledger, 500);
      final rejected = _request(ledger, 300, minute: 1);
      _request(ledger, 200, minute: 2);
      ledger.approveCashRequest(approved);
      ledger.rejectCashRequest(rejected);

      _expectCapacity(ledger, total: 2700, pending: 200, capacity: 2100);
    });

    test('a request above capacity is rejected and changes nothing', () {
      final ledger = _ledger();
      _request(ledger, 2000);

      expect(
        () => _request(ledger, 801, minute: 1),
        throwsA(isA<InsufficientRequestCapacityException>()),
      );
      expect(ledger.cashRequests, hasLength(1));
      _expectCapacity(ledger, total: 2200, pending: 2000, capacity: 800);
    });

    test('pending requests can fill but never exceed Max Limit', () {
      final ledger = _ledger();
      _request(ledger, 1500);
      _request(ledger, 1300, minute: 1);
      _expectCapacity(ledger, total: 2200, pending: 2800, capacity: 0);

      expect(
        () => _request(ledger, 1, minute: 2),
        throwsA(isA<InsufficientRequestCapacityException>()),
      );
      expect(
        ledger.totalBalance(_me) + ledger.pendingRequestCash(_me),
        ledger.maxLimitEgp,
      );
    });

    test('validation uses the latest capacity after a rejection', () {
      final ledger = _ledger();
      final first = _request(ledger, 2800);
      expect(
        () => _request(ledger, 500, minute: 1),
        throwsA(isA<InsufficientRequestCapacityException>()),
      );

      ledger.rejectCashRequest(first);
      _request(ledger, 500, minute: 2);
      _expectCapacity(ledger, total: 2200, pending: 500, capacity: 2300);
    });
  });

  group('Send Cash and Withdraw reduce capacity through Total Balance', () {
    test('pending Send Cash and Withdraw keep Total and capacity', () {
      final ledger = _ledger();
      ledger.createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-003',
        amountEgp: 300,
        createdAt: _at,
      );
      ledger.submitWithdraw(driverId: _me, amountEgp: 200, createdAt: _at);

      expect(ledger.availableBalance(_me), 1700);
      expect(ledger.frozenBalance(_me), 500);
      _expectCapacity(ledger, total: 2200, pending: 0, capacity: 2800);

      _request(ledger, 1000);
      _expectCapacity(ledger, total: 2200, pending: 1000, capacity: 1800);
    });

    test('approved Send Cash lowers Total and raises capacity', () {
      final ledger = _ledger();
      final transfer = ledger.createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-003',
        amountEgp: 300,
        createdAt: _at,
      );
      final withdraw = ledger.submitWithdraw(
        driverId: _me,
        amountEgp: 200,
        createdAt: _at,
      );
      _request(ledger, 1000);

      ledger.approve(transfer.id);
      _expectCapacity(ledger, total: 1900, pending: 1000, capacity: 2100);

      ledger.approveCashRequest(withdraw.id);
      _expectCapacity(ledger, total: 1700, pending: 1000, capacity: 2300);
    });

    test('rejected Send Cash and Withdraw leave capacity unchanged', () {
      final ledger = _ledger();
      final transfer = ledger.createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-003',
        amountEgp: 300,
        createdAt: _at,
      );
      final withdraw = ledger.submitWithdraw(
        driverId: _me,
        amountEgp: 200,
        createdAt: _at,
      );

      ledger.reject(transfer.id);
      ledger.rejectCashRequest(withdraw.id);
      _expectCapacity(ledger, total: 2200, pending: 0, capacity: 2800);
    });
  });

  group('form summary pending Request Cash', () {
    Future<void> expectForm(
      MockCashLedger ledger, {
      required int pending,
      required int capacity,
    }) async {
      final form = await CashRequestRepositoryImpl(ledger)
          .getRequestCashFormSummary(_me);
      expect(form.pendingRequestCashEgp, pending, reason: 'pending');
      expect(form.availableRequestCapacityEgp, capacity, reason: 'capacity');
      expect(
        form.availableRequestCapacityEgp,
        form.maxLimitEgp -
            ledger.totalBalance(_me) -
            form.pendingRequestCashEgp,
        reason: 'invariant',
      );
    }

    test('no pending requests reports 0', () async {
      await expectForm(_ledger(), pending: 0, capacity: 2800);
    });

    test('one pending request reports its amount', () async {
      final ledger = _ledger();
      _request(ledger, 1000);
      await expectForm(ledger, pending: 1000, capacity: 1800);
    });

    test('multiple pending requests are summed once each', () async {
      final ledger = _ledger();
      _request(ledger, 1000);
      _request(ledger, 800, minute: 1);
      expect(
        ledger.cashRequests.map((request) => request.id).toSet(),
        hasLength(2),
      );
      await expectForm(ledger, pending: 1800, capacity: 1000);
    });

    test('approved requests are excluded and credited to Total', () async {
      final ledger = _ledger();
      ledger.approveCashRequest(_request(ledger, 1000));
      expect(ledger.totalBalance(_me), 3200);
      await expectForm(ledger, pending: 0, capacity: 1800);
    });

    test('rejected requests are excluded and restore capacity', () async {
      final ledger = _ledger();
      ledger.rejectCashRequest(_request(ledger, 1000));
      expect(ledger.totalBalance(_me), 2200);
      await expectForm(ledger, pending: 0, capacity: 2800);
    });

    test('withdraw requests are not counted as pending Request Cash', () async {
      final ledger = _ledger();
      ledger.submitWithdraw(driverId: _me, amountEgp: 200, createdAt: _at);
      await expectForm(ledger, pending: 0, capacity: 2800);
    });

    test('the bloc passes the pending amount into state', () async {
      final ledger = _ledger();
      _request(ledger, 1000);
      final repository = CashRequestRepositoryImpl(ledger);
      final bloc = RequestCashBloc(
        driverId: _me,
        requestCash: RequestCash(repository),
        repository: repository,
      )..add(const RequestCashStarted());
      addTearDown(bloc.close);

      final state = await bloc.stream.firstWhere((state) => !state.loading);
      expect(state.pendingRequestCashEgp, 1000);
      expect(state.maxLimitEgp, 5000);
      expect(state.availableRequestCapacityEgp, 1800);
    });
  });

  group('finalization and existing behavior', () {
    test('repeated approval or rejection is blocked and changes nothing', () {
      final ledger = _ledger();
      final approved = _request(ledger, 400);
      final rejected = _request(ledger, 300, minute: 1);
      ledger.approveCashRequest(approved);
      ledger.rejectCashRequest(rejected);

      for (final id in [approved, rejected]) {
        expect(
          () => ledger.approveCashRequest(id),
          throwsA(isA<CashRequestAlreadyFinalizedException>()),
        );
        expect(
          () => ledger.rejectCashRequest(id),
          throwsA(isA<CashRequestAlreadyFinalizedException>()),
        );
      }
      expect(ledger.balanceOf(_me), 2600);
      expect(ledger.transactions, hasLength(1));
      _expectCapacity(ledger, total: 2600, pending: 0, capacity: 2400);
    });

    test('approval records one cash received transaction', () {
      final ledger = _ledger();
      final id = _request(ledger, 400);
      final approved = ledger.approveCashRequest(id, processedAt: _at);

      expect(approved.status, CashRequestStatus.approved);
      expect(approved.balanceBeforeEgp, 2200);
      expect(approved.balanceAfterEgp, 2600);
      final transaction = ledger.transactions.single;
      expect(transaction.type, MoneyTransactionType.cashReceived);
      expect(transaction.amountEgp, 400);
      expect(transaction.cashRequestId, id);
    });

    test('use case and form summary report the updated capacity', () async {
      final ledger = _ledger();
      ledger.createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-003',
        amountEgp: 300,
        createdAt: _at,
      );
      final repository = CashRequestRepositoryImpl(ledger);

      final result = await RequestCash(repository)(
        driverId: _me,
        amountEgp: 1000,
        createdAt: _at,
      );
      expect(result.availableRequestCapacityEgp, 1800);

      final form = await repository.getRequestCashFormSummary(_me);
      expect(form.maxLimitEgp, 5000);
      expect(form.availableRequestCapacityEgp, 1800);

      expect(
        () => RequestCash(repository)(
          driverId: _me,
          amountEgp: 1801,
          createdAt: _at,
        ),
        throwsA(isA<InsufficientRequestCapacityException>()),
      );
    });
  });
}
