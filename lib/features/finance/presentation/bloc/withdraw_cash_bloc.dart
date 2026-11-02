import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/cash_request_exception.dart';
import '../../domain/repositories/cash_request_repository.dart';
import '../../domain/usecases/withdraw_cash.dart';
import 'withdraw_cash_event.dart';
import 'withdraw_cash_state.dart';

class WithdrawCashBloc extends Bloc<WithdrawCashEvent, WithdrawCashState> {
  final String driverId;
  final WithdrawCash withdrawCash;
  final CashRequestRepository repository;

  WithdrawCashBloc({
    required this.driverId,
    required this.withdrawCash,
    required this.repository,
  }) : super(const WithdrawCashState()) {
    on<WithdrawCashStarted>(_onStarted);
    on<WithdrawCashAmountChanged>(_onAmountChanged);
    on<WithdrawCashNoteChanged>(_onNoteChanged);
    on<WithdrawCashSubmitted>(_onSubmitted, transformer: droppable());
  }

  Future<void> _onStarted(
    WithdrawCashStarted event,
    Emitter<WithdrawCashState> emit,
  ) async {
    try {
      final form = await repository.getWithdrawFormSummary(driverId);
      emit(
        state.copyWith(
          loading: false,
          currentBalanceEgp: form.currentBalanceEgp,
          availableBalanceEgp: form.availableBalanceEgp,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loading: false, error: WithdrawCashError.unexpected));
    }
  }

  void _onAmountChanged(
    WithdrawCashAmountChanged event,
    Emitter<WithdrawCashState> emit,
  ) {
    emit(state.copyWith(amountEgp: event.amountEgp, clearError: true));
  }

  void _onNoteChanged(
    WithdrawCashNoteChanged event,
    Emitter<WithdrawCashState> emit,
  ) {
    emit(state.copyWith(note: event.note, clearError: true));
  }

  Future<void> _onSubmitted(
    WithdrawCashSubmitted event,
    Emitter<WithdrawCashState> emit,
  ) async {
    if (state.submitting || state.result != null) return;
    if (state.amountEgp <= 0) {
      emit(state.copyWith(error: WithdrawCashError.invalidAmount));
      return;
    }

    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final result = await withdrawCash(
        driverId: driverId,
        amountEgp: state.amountEgp,
        note: state.note,
      );
      emit(
        state.copyWith(
          submitting: false,
          result: result,
          currentBalanceEgp: result.currentBalanceEgp,
          availableBalanceEgp: result.availableBalanceEgp,
        ),
      );
    } on InvalidCashRequestAmountException {
      emit(
        state.copyWith(
          submitting: false,
          error: WithdrawCashError.invalidAmount,
        ),
      );
    } on InsufficientWithdrawBalanceException {
      emit(
        state.copyWith(
          submitting: false,
          error: WithdrawCashError.exceedsAvailable,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(submitting: false, error: WithdrawCashError.unexpected),
      );
    }
  }
}
