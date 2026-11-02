import 'dart:async';

import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/finance_driver.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/finance/domain/repositories/cash_transfer_repository.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/send_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/send_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/send_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/send_cash_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transfer = CashTransfer(
    id: 'TRF-2026-0124',
    senderId: 'DR-001',
    recipientId: 'DR-003',
    amountEgp: 500,
    createdAt: DateTime(2026, 10, 20),
    status: TransferStatus.pending,
  );

  test('loads recipients and the sender balance', () async {
    final repository = _FakeTransfers();
    final bloc = _bloc(repository);

    bloc.add(const SendCashStarted());
    await expectLater(
      bloc.stream,
      emits(
        predicate<SendCashState>(
          (state) =>
              !state.loading &&
              state.senderBalanceEgp == 2200 &&
              state.recipients.single.id == 'DR-003',
        ),
      ),
    );
    await bloc.close();
  });

  test('stores the selected driver and amount', () async {
    final bloc = _bloc(_FakeTransfers());
    bloc.add(const SendCashStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    bloc.add(const SendCashRecipientSelected('DR-003'));
    bloc.add(const SendCashAmountChanged(500));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<SendCashState>(
          (state) => state.recipientId == 'DR-003' && state.amountEgp == 500,
        ),
      ),
    );
    await bloc.close();
  });

  test('successful submission returns the pending transfer', () async {
    final repository = _FakeTransfers();
    final bloc = _bloc(repository);
    bloc.add(const SendCashStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(const SendCashRecipientSelected('DR-003'));
    bloc.add(const SendCashAmountChanged(500));
    await bloc.stream.firstWhere((state) => state.amountEgp == 500);

    bloc.add(const SendCashSubmitted());
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<SendCashState>(
          (state) =>
              state.result?.transfer.id == 'TRF-2026-0124' &&
              state.result?.senderBalanceEgp == 1700 &&
              !state.submitting,
        ),
      ),
    );
    expect(repository.createCalls, 1);
    expect(repository.balance, 1700);
    await bloc.close();
  });

  test('invalid submission does not create a request', () async {
    final repository = _FakeTransfers();
    final bloc = _bloc(repository);
    bloc.add(const SendCashStarted());
    await bloc.stream.firstWhere((state) => !state.loading);

    bloc.add(const SendCashSubmitted());
    await expectLater(
      bloc.stream,
      emits(
        predicate<SendCashState>(
          (state) => state.error == SendCashError.selectRecipient,
        ),
      ),
    );

    bloc.add(const SendCashRecipientSelected('DR-003'));
    bloc.add(const SendCashAmountChanged(0));
    await bloc.stream.firstWhere((state) => state.recipientId == 'DR-003');
    bloc.add(const SendCashSubmitted());
    await expectLater(
      bloc.stream,
      emits(
        predicate<SendCashState>(
          (state) => state.error == SendCashError.invalidAmount,
        ),
      ),
    );
    expect(repository.createCalls, 0);
    expect(repository.balance, 2200);
    await bloc.close();
  });

  test('a second submit is ignored while the first is in progress', () async {
    final completer = Completer<CashTransfer>();
    final repository = _FakeTransfers(pending: completer);
    final bloc = _bloc(repository);
    bloc.add(const SendCashStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    bloc.add(const SendCashRecipientSelected('DR-003'));
    bloc.add(const SendCashAmountChanged(500));
    await bloc.stream.firstWhere((state) => state.canSubmit);

    bloc.add(const SendCashSubmitted());
    await expectLater(
      bloc.stream,
      emits(predicate<SendCashState>((state) => state.submitting)),
    );
    bloc.add(const SendCashSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(repository.createCalls, 1);
    completer.complete(transfer);
    await expectLater(
      bloc.stream,
      emits(predicate<SendCashState>((state) => state.result != null)),
    );
    expect(repository.createCalls, 1);
    await bloc.close();
  });
}

SendCashBloc _bloc(_FakeTransfers repository) {
  return SendCashBloc(
    senderId: 'DR-001',
    sendCash: SendCash(repository),
    repository: repository,
  );
}

class _FakeTransfers implements CashTransferRepository {
  final Completer<CashTransfer>? pending;
  int createCalls = 0;
  int balance = 2200;

  _FakeTransfers({this.pending});

  @override
  Future<List<FinanceDriver>> getRecipients(String senderId) async {
    return const [
      FinanceDriver(
        id: 'DR-003',
        fullName: LocalizedString(en: 'Khaled Ramadan', ar: 'خالد رمضان'),
        balanceEgp: 1100,
      ),
    ];
  }

  @override
  Future<int> getAvailableBalance(String senderId) async => balance;

  @override
  Future<int> getCurrentBalance(String senderId) async => balance;

  @override
  Future<CashTransfer> createPendingTransfer({
    required String senderId,
    required String recipientId,
    required int amountEgp,
    required DateTime createdAt,
  }) {
    createCalls += 1;
    if (pending != null) return pending!.future;
    if (amountEgp > balance) throw const InsufficientBalanceException();
    balance -= amountEgp;
    return Future.value(
      CashTransfer(
        id: 'TRF-2026-0124',
        senderId: senderId,
        recipientId: recipientId,
        amountEgp: amountEgp,
        createdAt: createdAt,
        status: TransferStatus.pending,
      ),
    );
  }

  @override
  Future<CashTransfer> approve(String transferId) => throw UnimplementedError();

  @override
  Future<CashTransfer> reject(String transferId) => throw UnimplementedError();

  @override
  Future<List<CashTransfer>> getTransfers() async => [];
}
