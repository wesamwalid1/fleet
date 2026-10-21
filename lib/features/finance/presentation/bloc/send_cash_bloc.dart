import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/send_cash_exception.dart';
import '../../domain/repositories/cash_transfer_repository.dart';
import '../../domain/usecases/send_cash.dart';
import 'send_cash_event.dart';
import 'send_cash_state.dart';

class SendCashBloc extends Bloc<SendCashEvent, SendCashState> {
  final String senderId;
  final SendCash sendCash;
  final CashTransferRepository repository;

  SendCashBloc({
    required this.senderId,
    required this.sendCash,
    required this.repository,
  }) : super(const SendCashState()) {
    on<SendCashStarted>(_onStarted);
    on<SendCashRecipientSelected>(_onRecipientSelected);
    on<SendCashAmountChanged>(_onAmountChanged);
    on<SendCashSubmitted>(_onSubmitted, transformer: droppable());
  }

  Future<void> _onStarted(
    SendCashStarted event,
    Emitter<SendCashState> emit,
  ) async {
    try {
      final recipients = await repository.getRecipients(senderId);
      final balance = await repository.getAvailableBalance(senderId);
      emit(
        state.copyWith(
          loading: false,
          recipients: recipients,
          senderBalanceEgp: balance,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loading: false, error: SendCashError.unexpected));
    }
  }

  void _onRecipientSelected(
    SendCashRecipientSelected event,
    Emitter<SendCashState> emit,
  ) {
    emit(state.copyWith(recipientId: event.recipientId, clearError: true));
  }

  void _onAmountChanged(
    SendCashAmountChanged event,
    Emitter<SendCashState> emit,
  ) {
    emit(state.copyWith(amountEgp: event.amountEgp, clearError: true));
  }

  Future<void> _onSubmitted(
    SendCashSubmitted event,
    Emitter<SendCashState> emit,
  ) async {
    if (state.submitting || state.result != null) return;

    final recipientId = state.recipientId;
    if (recipientId == null) {
      emit(state.copyWith(error: SendCashError.selectRecipient));
      return;
    }
    if (state.amountEgp <= 0) {
      emit(state.copyWith(error: SendCashError.invalidAmount));
      return;
    }

    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final result = await sendCash(
        senderId: senderId,
        recipientId: recipientId,
        amountEgp: state.amountEgp,
      );
      emit(
        state.copyWith(
          submitting: false,
          result: result,
          senderBalanceEgp: result.senderBalanceEgp,
        ),
      );
    } on InvalidTransferAmountException {
      emit(
        state.copyWith(submitting: false, error: SendCashError.invalidAmount),
      );
    } on InsufficientBalanceException {
      emit(
        state.copyWith(
          submitting: false,
          error: SendCashError.insufficientBalance,
        ),
      );
    } catch (_) {
      emit(state.copyWith(submitting: false, error: SendCashError.unexpected));
    }
  }
}
