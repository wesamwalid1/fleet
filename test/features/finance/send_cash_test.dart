import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_transfer_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/finance_driver.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/cash_transfer_repository.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/approve_cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/reject_cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/send_cash.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/withdraw_cash.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/summarize_transactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 10, 20, 9);

  test('a valid request is pending and reduces only the sender', () async {
    final harness = _Harness();
    final result = await harness.send(
      senderId: MockCashLedger.senderId,
      recipientId: 'DR-003',
      amountEgp: 500,
      createdAt: createdAt,
    );

    expect(result.transfer.status, TransferStatus.pending);
    expect(result.transfer.senderId, 'DR-001');
    expect(result.transfer.recipientId, 'DR-003');
    expect(result.transfer.amountEgp, 500);
    expect(result.transfer.createdAt, createdAt);
    expect(result.transfer.id, 'TRF-2026-0124');
    expect(result.senderBalanceEgp, 1700);
    expect(harness.ledger.balanceOf('DR-001'), 1700);
    expect(harness.ledger.balanceOf('DR-003'), 1100);
    expect(
      (await harness.repository.getTransfers()).single.status,
      TransferStatus.pending,
    );
  });

  test('zero and negative amounts are rejected without a transfer', () async {
    final repository = _ThrowingRepository();
    final harness = _Harness(repository: repository);

    expect(
      () =>
          harness.send(senderId: 'DR-001', recipientId: 'DR-003', amountEgp: 0),
      throwsA(isA<InvalidTransferAmountException>()),
    );
    expect(
      () => harness.send(
        senderId: 'DR-001',
        recipientId: 'DR-003',
        amountEgp: -100,
      ),
      throwsA(
        isA<InvalidTransferAmountException>().having(
          (error) => error.amountEgp,
          'amountEgp',
          -100,
        ),
      ),
    );
    expect(repository.createCalls, 0);
  });

  test('an amount above the balance changes nothing', () async {
    final harness = _Harness();

    expect(
      () => harness.send(
        senderId: MockCashLedger.senderId,
        recipientId: 'DR-003',
        amountEgp: 2201,
        createdAt: createdAt,
      ),
      throwsA(isA<InsufficientBalanceException>()),
    );
    expect(harness.ledger.balanceOf('DR-001'), 2200);
    expect(harness.ledger.balanceOf('DR-003'), 1100);
    expect(harness.ledger.transfers, isEmpty);
  });

  test('sending to oneself is rejected', () async {
    final repository = _ThrowingRepository();
    final harness = _Harness(repository: repository);

    expect(
      () => harness.send(
        senderId: 'DR-001',
        recipientId: 'DR-001',
        amountEgp: 500,
      ),
      throwsA(isA<SendCashToSelfException>()),
    );
    expect(repository.createCalls, 0);
  });

  test(
    'approval credits the recipient once and does not deduct again',
    () async {
      final harness = _Harness();
      final created = await harness.send(
        senderId: MockCashLedger.senderId,
        recipientId: 'DR-003',
        amountEgp: 500,
        createdAt: createdAt,
      );

      final approved = await harness.approve(created.transfer.id);

      expect(approved.status, TransferStatus.approved);
      expect(harness.ledger.balanceOf('DR-001'), 1700);
      expect(harness.ledger.balanceOf('DR-003'), 1600);

      expect(
        () => harness.approve(created.transfer.id),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(
        () => harness.reject(created.transfer.id),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(harness.ledger.balanceOf('DR-001'), 1700);
      expect(harness.ledger.balanceOf('DR-003'), 1600);
      expect(
        (await harness.repository.getTransfers()).single.status,
        TransferStatus.approved,
      );
    },
  );

  test(
    'rejection refunds the sender once and does not credit the recipient',
    () async {
      final harness = _Harness();
      final created = await harness.send(
        senderId: MockCashLedger.senderId,
        recipientId: 'DR-003',
        amountEgp: 500,
        createdAt: createdAt,
      );

      final rejected = await harness.reject(created.transfer.id);

      expect(rejected.status, TransferStatus.rejected);
      expect(harness.ledger.balanceOf('DR-001'), 2200);
      expect(harness.ledger.balanceOf('DR-003'), 1100);

      expect(
        () => harness.reject(created.transfer.id),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(
        () => harness.approve(created.transfer.id),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(harness.ledger.balanceOf('DR-001'), 2200);
      expect(harness.ledger.balanceOf('DR-003'), 1100);
    },
  );

  test(
    'the home summary keeps charge and max limit after a transfer',
    () async {
      final opening = summarizeTransactions(
        maxLimitEgp: MockFinanceDataSource.maxLimitEgp,
        transactions: [
          for (final transaction in MockFinanceDataSource.transactions)
            transaction.toEntity(),
        ],
      );
      final ledger = MockCashLedger(senderBalanceEgp: opening.balanceEgp);
      final summaryRepository = SessionFinanceRepository(
        const MockFinanceDataSource(),
        ledger,
      );
      final transfers = CashTransferRepositoryImpl(ledger);

      final before = await summaryRepository.getFinancialSummary();
      expect(before.balanceEgp, 2200);
      expect(before.chargeEgp, 3200);
      expect(before.maxLimitEgp, 5000);

      await SendCash(transfers)(
        senderId: MockCashLedger.senderId,
        recipientId: 'DR-003',
        amountEgp: 500,
        createdAt: createdAt,
      );
      final after = await summaryRepository.getFinancialSummary();

      expect(after.balanceEgp, 1700);
      expect(after.chargeEgp, 3200);
      expect(after.maxLimitEgp, 5000);
      expect(ledger.balanceOf('DR-003'), 1100);
    },
  );

  test('the sender is excluded from recipients', () async {
    final harness = _Harness();
    final recipients = await harness.repository.getRecipients(
      MockCashLedger.senderId,
    );

    expect(recipients.map((driver) => driver.id), [
      'DR-003',
      'DR-002',
      'DR-004',
    ]);
    expect(
      recipients.any((driver) => driver.id == MockCashLedger.senderId),
      isFalse,
    );
  });

  test(
    'success result reports Current Balance when a Withdraw is reserved',
    () async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final requests = CashRequestRepositoryImpl(ledger);
      final transfers = CashTransferRepositoryImpl(ledger);

      await WithdrawCash(requests)(
        driverId: MockCashLedger.senderId,
        amountEgp: 500,
        createdAt: createdAt,
      );
      expect(ledger.currentBalance(MockCashLedger.senderId), 2200);
      expect(ledger.availableBalance(MockCashLedger.senderId), 1700);

      final result = await SendCash(transfers)(
        senderId: MockCashLedger.senderId,
        recipientId: 'DR-003',
        amountEgp: 200,
        createdAt: createdAt.add(const Duration(minutes: 1)),
      );

      // Current after send: 2000; Available: 1500. Success UI needs Current.
      expect(ledger.currentBalance(MockCashLedger.senderId), 2000);
      expect(ledger.availableBalance(MockCashLedger.senderId), 1500);
      expect(result.senderBalanceEgp, 2000);
      expect(
        await transfers.getAvailableBalance(MockCashLedger.senderId),
        1500,
      );
    },
  );
}

class _Harness {
  final MockCashLedger ledger;
  final CashTransferRepository repository;
  final SendCash send;
  final ApproveCashTransfer approve;
  final RejectCashTransfer reject;

  _Harness._(this.ledger, this.repository)
    : send = SendCash(repository),
      approve = ApproveCashTransfer(repository),
      reject = RejectCashTransfer(repository);

  factory _Harness({CashTransferRepository? repository}) {
    final ledger = MockCashLedger(senderBalanceEgp: 2200);
    return _Harness._(ledger, repository ?? CashTransferRepositoryImpl(ledger));
  }
}

class _ThrowingRepository implements CashTransferRepository {
  int createCalls = 0;

  @override
  Future<CashTransfer> createPendingTransfer({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    required DateTime createdAt,
  }) async {
    createCalls += 1;
    throw StateError('create should not be called');
  }

  @override
  Future<List<FinanceDriver>> getRecipients(String senderId) async => [];

  @override
  Future<int> getAvailableBalance(String senderId) async => 0;

  @override
  Future<int> getCurrentBalance(String senderId) async => 0;

  @override
  Future<CashTransfer> approve(String transferId) => throw UnimplementedError();

  @override
  Future<CashTransfer> reject(String transferId) => throw UnimplementedError();

  @override
  Future<List<CashTransfer>> getTransfers() async => [];
}
