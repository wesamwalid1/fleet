import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/cash_request_exception.dart';
import '../../domain/repositories/cash_request_repository.dart';
import '../../domain/usecases/request_cash.dart';
import 'request_cash_event.dart';
import 'request_cash_state.dart';

class RequestCashBloc extends Bloc<RequestCashEvent, RequestCashState> {
  final String driverId;
  final RequestCash requestCash;
  final CashRequestRepository repository;

  RequestCashBloc({
    required this.driverId,
    required this.requestCash,
    required this.repository,
  }) : super(const RequestCashState()) {
    on<RequestCashStarted>(_onStarted);
    on<RequestCashAmountChanged>(_onAmountChanged);
    on<RequestCashNoteChanged>(_onNoteChanged);
    on<RequestCashSubmitted>(_onSubmitted, transformer: droppable());
  }

  Future<void> _onStarted(
    RequestCashStarted event,
    Emitter<RequestCashState> emit,
  ) async {
    try {
      final form = await repository.getRequestCashFormSummary(driverId);
      emit(
        state.copyWith(
          loading: false,
          currentBalanceEgp: form.currentBalanceEgp,
          maxLimitEgp: form.maxLimitEgp,
          availableRequestCapacityEgp: form.availableRequestCapacityEgp,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loading: false, error: RequestCashError.unexpected));
    }
  }

  void _onAmountChanged(
    RequestCashAmountChanged event,
    Emitter<RequestCashState> emit,
  ) {
    emit(state.copyWith(amountEgp: event.amountEgp, clearError: true));
  }

  void _onNoteChanged(
    RequestCashNoteChanged event,
    Emitter<RequestCashState> emit,
  ) {
    emit(state.copyWith(note: event.note, clearError: true));
  }

  Future<void> _onSubmitted(
    RequestCashSubmitted event,
    Emitter<RequestCashState> emit,
  ) async {
    if (state.submitting || state.result != null) return;
    if (state.amountEgp <= 0) {
      emit(state.copyWith(error: RequestCashError.invalidAmount));
      return;
    }

    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final result = await requestCash(
        driverId: driverId,
        amountEgp: state.amountEgp,
        note: state.note,
      );
      emit(
        state.copyWith(
          submitting: false,
          result: result,
          currentBalanceEgp: result.currentBalanceEgp,
          availableRequestCapacityEgp: result.availableRequestCapacityEgp,
        ),
      );
    } on InvalidCashRequestAmountException {
      emit(
        state.copyWith(
          submitting: false,
          error: RequestCashError.invalidAmount,
        ),
      );
    } on InsufficientRequestCapacityException {
      emit(
        state.copyWith(
          submitting: false,
          error: RequestCashError.exceedsCapacity,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(submitting: false, error: RequestCashError.unexpected),
      );
    }
  }
}
