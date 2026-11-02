import 'package:equatable/equatable.dart';

enum CashRequestType { requestCash, withdraw }

enum CashRequestStatus { pending, approved, rejected }

/// A driver-initiated vault request. Balance moves only when approved.
class CashRequest extends Equatable {
  final String id;
  final String requestNumber;
  final String driverId;
  final CashRequestType type;
  final int amountEgp;
  final String? note;
  final CashRequestStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  /// Driver balance immediately before the approval movement. Set on approve.
  final int? balanceBeforeEgp;

  /// Driver balance immediately after the approval movement. Set on approve.
  final int? balanceAfterEgp;

  const CashRequest({
    required this.id,
    required this.requestNumber,
    required this.driverId,
    required this.type,
    required this.amountEgp,
    required this.createdAt,
    required this.status,
    this.note,
    this.processedAt,
    this.balanceBeforeEgp,
    this.balanceAfterEgp,
  });

  CashRequest copyWith({
    CashRequestStatus? status,
    DateTime? processedAt,
    int? balanceBeforeEgp,
    int? balanceAfterEgp,
  }) {
    return CashRequest(
      id: id,
      requestNumber: requestNumber,
      driverId: driverId,
      type: type,
      amountEgp: amountEgp,
      note: note,
      status: status ?? this.status,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      balanceBeforeEgp: balanceBeforeEgp ?? this.balanceBeforeEgp,
      balanceAfterEgp: balanceAfterEgp ?? this.balanceAfterEgp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    requestNumber,
    driverId,
    type,
    amountEgp,
    note,
    status,
    createdAt,
    processedAt,
    balanceBeforeEgp,
    balanceAfterEgp,
  ];
}
