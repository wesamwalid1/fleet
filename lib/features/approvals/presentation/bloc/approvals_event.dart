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

final class ApprovalsFilterSelected extends ApprovalsEvent {
  final ApprovalFilter filter;

  const ApprovalsFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
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
