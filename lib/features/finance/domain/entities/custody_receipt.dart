import 'package:equatable/equatable.dart';

enum CustodyReceiptStatus { pending, approved }

class CustodyReceipt extends Equatable {
  final String id;
  final String driverId;
  final int amountEgp;
  final DateTime createdAt;
  final CustodyReceiptStatus status;
  final DateTime? finalizedAt;

  const CustodyReceipt({
    required this.id,
    required this.driverId,
    required this.amountEgp,
    required this.createdAt,
    required this.status,
    this.finalizedAt,
  });

  CustodyReceipt copyWith({
    CustodyReceiptStatus? status,
    DateTime? finalizedAt,
  }) {
    return CustodyReceipt(
      id: id,
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    amountEgp,
    createdAt,
    status,
    finalizedAt,
  ];
}
