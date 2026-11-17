import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../../core/loading/minimum_loading_window.dart';
import '../../domain/entities/approval_item.dart';

sealed class ApprovalsEvent extends Equatable {
  const ApprovalsEvent();

  @override
  List<Object?> get props => [];
}

final class ApprovalsStarted extends ApprovalsEvent {
  const ApprovalsStarted();
}

/// Reload items and balance without touching [ApprovalsState.busy] or
/// [ApprovalsState.revision].
///
/// Used for ledger sync and Home pull-to-refresh. Leaving [revision]
/// unchanged is intentional: Home listeners that react to revision bumps
/// (post-action finance/history sync) must not re-fire for these reloads.
///
/// [done] completes after the attempt finishes (including silent failures).
/// It is not part of [props] so stream-driven refreshes stay equal.
final class ApprovalsRefreshed extends ApprovalsEvent {
  final Completer<void>? done;

  /// When set, the result is held until this pull's sections reveal together.
  /// Not part of [props].
  final MinimumLoadingWindow? window;

  const ApprovalsRefreshed({this.done, this.window});
}

final class ApprovalsFilterSelected extends ApprovalsEvent {
  final ApprovalFilter filter;

  const ApprovalsFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
}

final class ApprovalsSearchChanged extends ApprovalsEvent {
  final String query;

  const ApprovalsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

enum ApprovalCommand {
  approveVault,
  approveTransfer,
  declineTransfer,
  confirmRoad,
  rejectRoad,
}

final class ApprovalActionRequested extends ApprovalsEvent {
  final String id;
  final ApprovalCommand command;

  const ApprovalActionRequested({required this.id, required this.command});

  @override
  List<Object?> get props => [id, command];
}
