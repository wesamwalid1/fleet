import 'package:equatable/equatable.dart';

enum TransferStatus { pending, approved, rejected }

class CashTransfer extends Equatable {
  final String id;
  final String senderId;
  final String recipientId;
  final int amountEgp;
  final DateTime createdAt;
  final TransferStatus status;
  final DateTime? finalizedAt;

  /// Sender balance immediately before the send debit. Set at creation.
  final int? senderBalanceBeforeEgp;

  /// Sender balance immediately after the send debit. Set at creation.
  final int? senderBalanceAfterEgp;

  /// Recipient balance immediately before the approve credit. Null until approved.
  final int? recipientBalanceBeforeEgp;

  /// Recipient balance immediately after the approve credit. Null until approved.
  final int? recipientBalanceAfterEgp;

  const CashTransfer({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.amountEgp,
    required this.createdAt,
    required this.status,
    this.finalizedAt,
    this.senderBalanceBeforeEgp,
    this.senderBalanceAfterEgp,
    this.recipientBalanceBeforeEgp,
    this.recipientBalanceAfterEgp,
  });

  CashTransfer copyWith({
    TransferStatus? status,
    DateTime? finalizedAt,
    int? senderBalanceBeforeEgp,
    int? senderBalanceAfterEgp,
    int? recipientBalanceBeforeEgp,
    int? recipientBalanceAfterEgp,
  }) {
    return CashTransfer(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      senderBalanceBeforeEgp:
          senderBalanceBeforeEgp ?? this.senderBalanceBeforeEgp,
      senderBalanceAfterEgp:
          senderBalanceAfterEgp ?? this.senderBalanceAfterEgp,
      recipientBalanceBeforeEgp:
          recipientBalanceBeforeEgp ?? this.recipientBalanceBeforeEgp,
      recipientBalanceAfterEgp:
          recipientBalanceAfterEgp ?? this.recipientBalanceAfterEgp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    recipientId,
    amountEgp,
    createdAt,
    status,
    finalizedAt,
    senderBalanceBeforeEgp,
    senderBalanceAfterEgp,
    recipientBalanceBeforeEgp,
    recipientBalanceAfterEgp,
  ];
}
