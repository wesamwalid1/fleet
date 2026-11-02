import 'package:equatable/equatable.dart';

import 'expense_attachment.dart';
import 'settlement_type.dart';

enum ExpenseStatus { recorded }

class ExpenseRequest extends Equatable {
  final String id;
  final String driverId;
  final String tripId;
  final SettlementType settlementType;
  final int amountEgp;
  final String? notes;
  final List<ExpenseAttachment> attachments;
  final DateTime createdAt;
  final ExpenseStatus status;

  /// Driver balance immediately before the expense debit.
  final int? balanceBeforeEgp;

  /// Driver balance immediately after the expense debit.
  final int? balanceAfterEgp;

  const ExpenseRequest({
    required this.id,
    required this.driverId,
    required this.tripId,
    required this.settlementType,
    required this.amountEgp,
    required this.notes,
    required this.attachments,
    required this.createdAt,
    required this.status,
    this.balanceBeforeEgp,
    this.balanceAfterEgp,
  });

  ExpenseRequest copyWith({
    ExpenseStatus? status,
    int? balanceBeforeEgp,
    int? balanceAfterEgp,
  }) {
    return ExpenseRequest(
      id: id,
      driverId: driverId,
      tripId: tripId,
      settlementType: settlementType,
      amountEgp: amountEgp,
      notes: notes,
      attachments: attachments,
      createdAt: createdAt,
      status: status ?? this.status,
      balanceBeforeEgp: balanceBeforeEgp ?? this.balanceBeforeEgp,
      balanceAfterEgp: balanceAfterEgp ?? this.balanceAfterEgp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    tripId,
    settlementType,
    amountEgp,
    notes,
    attachments,
    createdAt,
    status,
    balanceBeforeEgp,
    balanceAfterEgp,
  ];
}
