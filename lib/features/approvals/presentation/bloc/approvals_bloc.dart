import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/approval_repository.dart';
import '../../domain/usecases/approve_incoming_transfer.dart';
import '../../domain/usecases/approve_vault_receipt.dart';
import '../../domain/usecases/confirm_road_expense.dart';
import '../../domain/usecases/decline_incoming_transfer.dart';
import '../../domain/usecases/reject_road_expense.dart';
import 'approvals_event.dart';
import 'approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  final String driverId;
  final ApprovalRepository repository;
  final ApproveVaultReceipt approveVaultReceipt;
  final ApproveIncomingTransfer approveIncomingTransfer;
  final DeclineIncomingTransfer declineIncomingTransfer;
  final ConfirmRoadExpense confirmRoadExpense;
  final RejectRoadExpense rejectRoadExpense;
  late final StreamSubscription<void> _ledgerChanges;

  /// Numbers each load so a slower, older load never overwrites newer data.
  /// Refreshes run side by side and only the newest one emits.
  int _loads = 0;

  ApprovalsBloc({
    required this.driverId,
    required this.repository,
    required this.approveVaultReceipt,
    required this.approveIncomingTransfer,
    required this.declineIncomingTransfer,
    required this.confirmRoadExpense,
    required this.rejectRoadExpense,
  }) : super(const ApprovalsState()) {
    on<ApprovalsStarted>(_onStarted);
    on<ApprovalsRefreshed>(_onRefreshed);
    on<ApprovalsFilterSelected>(_onFilterSelected);
    on<ApprovalActionRequested>(_onAction, transformer: droppable());
    _ledgerChanges = repository.changes.listen(
      (_) => add(const ApprovalsRefreshed()),
    );
  }

  Future<void> _onStarted(
    ApprovalsStarted event,
    Emitter<ApprovalsState> emit,
  ) async {
    await _reload(emit, revision: state.revision);
  }

  Future<void> _onRefreshed(
    ApprovalsRefreshed event,
    Emitter<ApprovalsState> emit,
  ) async {
    final load = ++_loads;
    try {
      final items = await repository.getApprovals(driverId);
      final balance = await repository.getAvailableBalance(driverId);
      if (load != _loads) return;
      emit(state.copyWith(loading: false, balanceEgp: balance, items: items));
    } catch (_) {
      // Keep the current state; the next ledger change reloads again.
    }
  }

  void _onFilterSelected(
    ApprovalsFilterSelected event,
    Emitter<ApprovalsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter, failed: false));
  }

  Future<void> _onAction(
    ApprovalActionRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, failed: false));
    try {
      switch (event.command) {
        case ApprovalCommand.approveVault:
          await approveVaultReceipt(driverId: driverId, receiptId: event.id);
        case ApprovalCommand.approveTransfer:
          await approveIncomingTransfer(
            driverId: driverId,
            transferId: event.id,
          );
        case ApprovalCommand.declineTransfer:
          await declineIncomingTransfer(
            driverId: driverId,
            transferId: event.id,
          );
        case ApprovalCommand.confirmRoad:
          await confirmRoadExpense(driverId: driverId, approvalId: event.id);
        case ApprovalCommand.rejectRoad:
          await rejectRoadExpense(driverId: driverId, approvalId: event.id);
      }
      await _reload(emit, revision: state.revision + 1);
    } catch (_) {
      emit(state.copyWith(busy: false, failed: true));
    }
  }

  Future<void> _reload(
    Emitter<ApprovalsState> emit, {
    required int revision,
  }) async {
    final load = ++_loads;
    try {
      final items = await repository.getApprovals(driverId);
      final balance = await repository.getAvailableBalance(driverId);
      if (load != _loads) {
        // A newer load already holds fresher data; only settle this one.
        emit(
          state.copyWith(
            loading: false,
            busy: false,
            failed: false,
            revision: revision,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          loading: false,
          busy: false,
          failed: false,
          revision: revision,
          balanceEgp: balance,
          items: items,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loading: false, busy: false, failed: true));
    }
  }

  @override
  Future<void> close() async {
    await _ledgerChanges.cancel();
    return super.close();
  }
}
