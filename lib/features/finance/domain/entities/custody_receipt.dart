import 'package:equatable/equatable.dart';

enum CustodyReceiptStatus { pending, approved }

class CustodyReceipt extends Equatable {
  final String id;
  final String driverId;
  final int amountEgp;
  final DateTime createdAt;
  final CustodyReceiptStatus status;
  final DateTime? finalizedAt;

  /// Driver balance immediately before the vault credit. Set on approval.
  final int? balanceBeforeEgp;

  /// Driver balance immediately after the vault credit. Set on approval.
  final int? balanceAfterEgp;

  const CustodyReceipt({
    required this.id,
    required this.driverId,
    required this.amountEgp,
    required this.createdAt,
    required this.status,
    this.finalizedAt,
    this.balanceBeforeEgp,
    this.balanceAfterEgp,
  });

  CustodyReceipt copyWith({
    CustodyReceiptStatus? status,
    DateTime? finalizedAt,
    int? balanceBeforeEgp,
    int? balanceAfterEgp,
  }) {
    return CustodyReceipt(
      id: id,
      driverId: driverId,
      amountEgp: amountEgp,
      createdAt: createdAt,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      balanceBeforeEgp: balanceBeforeEgp ?? this.balanceBeforeEgp,
      balanceAfterEgp: balanceAfterEgp ?? this.balanceAfterEgp,
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
    balanceBeforeEgp,
    balanceAfterEgp,
  ];
}
