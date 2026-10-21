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

  const CashTransfer({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.amountEgp,
    required this.createdAt,
    required this.status,
    this.finalizedAt,
  });

  CashTransfer copyWith({TransferStatus? status, DateTime? finalizedAt}) {
    return CashTransfer(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
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
  ];
}
