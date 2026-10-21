import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/expense_exception.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/record_expense.dart';
import 'record_expense_event.dart';
import 'record_expense_state.dart';

class RecordExpenseBloc extends Bloc<RecordExpenseEvent, RecordExpenseState> {
  final String driverId;
  final RecordExpense recordExpense;
  final ExpenseRepository repository;

  RecordExpenseBloc({
    required this.driverId,
    required this.recordExpense,
    required this.repository,
  }) : super(const RecordExpenseState()) {
    on<RecordExpenseStarted>(_onStarted);
    on<RecordExpenseTripQueryChanged>(_onTripQueryChanged);
    on<RecordExpenseTripSelected>(_onTripSelected);
    on<RecordExpenseSettlementSelected>(_onSettlementSelected);
    on<RecordExpenseAmountChanged>(_onAmountChanged);
    on<RecordExpenseNotesChanged>(_onNotesChanged);
    on<RecordExpenseAttachmentAdded>(_onAttachmentAdded);
    on<RecordExpenseAttachmentRemoved>(_onAttachmentRemoved);
    on<RecordExpenseAttachmentFailed>(_onAttachmentFailed);
    on<RecordExpenseReviewRequested>(_onReviewRequested);
    on<RecordExpenseReviewCancelled>(_onReviewCancelled);
    on<RecordExpenseSubmitted>(_onSubmitted, transformer: droppable());
  }

  Future<void> _onStarted(
    RecordExpenseStarted event,
    Emitter<RecordExpenseState> emit,
  ) async {
    try {
      final trips = await repository.getAssignedTrips(driverId);
      final balance = await repository.getAvailableBalance(driverId);
      emit(
        state.copyWith(
          loading: false,
          trips: trips,
          balanceEgp: balance,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(loading: false, error: RecordExpenseError.unexpected),
      );
    }
  }

  void _onTripQueryChanged(
    RecordExpenseTripQueryChanged event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(state.copyWith(tripQuery: event.query));
  }

  void _onTripSelected(
    RecordExpenseTripSelected event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(state.copyWith(tripId: event.tripId, clearError: true));
  }

  void _onSettlementSelected(
    RecordExpenseSettlementSelected event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(
      state.copyWith(settlementType: event.settlementType, clearError: true),
    );
  }

  void _onAmountChanged(
    RecordExpenseAmountChanged event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(state.copyWith(amountEgp: event.amountEgp, clearError: true));
  }

  void _onNotesChanged(
    RecordExpenseNotesChanged event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  void _onAttachmentAdded(
    RecordExpenseAttachmentAdded event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(
      state.copyWith(
        attachments: [...state.attachments, event.attachment],
        clearError: true,
      ),
    );
  }

  void _onAttachmentRemoved(
    RecordExpenseAttachmentRemoved event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(
      state.copyWith(
        attachments: [
          for (final attachment in state.attachments)
            if (attachment.id != event.attachmentId) attachment,
        ],
      ),
    );
  }

  void _onAttachmentFailed(
    RecordExpenseAttachmentFailed event,
    Emitter<RecordExpenseState> emit,
  ) {
    emit(state.copyWith(error: RecordExpenseError.attachmentFailed));
  }

  void _onReviewRequested(
    RecordExpenseReviewRequested event,
    Emitter<RecordExpenseState> emit,
  ) {
    if (state.submitting || state.result != null) return;
    final error = _validationError(state);
    if (error != null) {
      emit(state.copyWith(stage: RecordExpenseStage.form, error: error));
      return;
    }
    emit(state.copyWith(stage: RecordExpenseStage.confirm, clearError: true));
  }

  void _onReviewCancelled(
    RecordExpenseReviewCancelled event,
    Emitter<RecordExpenseState> emit,
  ) {
    if (state.submitting || state.result != null) return;
    emit(state.copyWith(stage: RecordExpenseStage.form, clearError: true));
  }

  Future<void> _onSubmitted(
    RecordExpenseSubmitted event,
    Emitter<RecordExpenseState> emit,
  ) async {
    if (state.submitting || state.result != null) return;
    final error = _validationError(state);
    if (error != null) {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: error,
        ),
      );
      return;
    }

    emit(state.copyWith(submitting: true, clearError: true));
    final notes = state.notes.trim();
    try {
      final result = await recordExpense(
        driverId: driverId,
        tripId: state.tripId,
        settlementType: state.settlementType,
        amountEgp: state.amountEgp,
        notes: notes.isEmpty ? null : notes,
        attachments: state.attachments,
      );
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.recorded,
          result: result,
          balanceEgp: result.balanceEgp,
        ),
      );
    } on InvalidExpenseAmountException {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.invalidAmount,
        ),
      );
    } on InsufficientExpenseBalanceException {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.insufficientBalance,
        ),
      );
    } on MissingTripException {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.selectTrip,
        ),
      );
    } on MissingSettlementTypeException {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.selectSettlement,
        ),
      );
    } on IneligibleTripException {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.ineligibleTrip,
        ),
      );
    } on TripAssignedToAnotherDriverException {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.ineligibleTrip,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submitting: false,
          stage: RecordExpenseStage.form,
          error: RecordExpenseError.unexpected,
        ),
      );
    }
  }

  RecordExpenseError? _validationError(RecordExpenseState state) {
    if (state.tripId == null) return RecordExpenseError.selectTrip;
    if (state.settlementType == null) {
      return RecordExpenseError.selectSettlement;
    }
    if (state.amountEgp <= 0) return RecordExpenseError.invalidAmount;
    if (state.amountEgp > state.balanceEgp) {
      return RecordExpenseError.insufficientBalance;
    }
    return null;
  }
}
