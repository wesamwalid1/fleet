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
  });

  CashRequest copyWith({CashRequestStatus? status, DateTime? processedAt}) {
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
  ];
}
