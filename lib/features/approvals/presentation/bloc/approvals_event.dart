import 'package:equatable/equatable.dart';

import '../../domain/entities/approval_item.dart';

sealed class ApprovalsEvent extends Equatable {
  const ApprovalsEvent();

  @override
  List<Object?> get props => [];
}

final class ApprovalsStarted extends ApprovalsEvent {
  const ApprovalsStarted();
}

/// The session ledger changed; reload items and balance without touching
/// [ApprovalsState.busy] or [ApprovalsState.revision].
final class ApprovalsRefreshed extends ApprovalsEvent {
  const ApprovalsRefreshed();
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
