import 'package:equatable/equatable.dart';

enum MoneyTransactionType { cashReceived, expense }

/// A whole-EGP movement. [amountEgp] must be greater than zero.
/// The transaction type decides whether that amount raises or lowers the balance.
///
/// Opening-balance seed rows omit [id] / [cashRequestId]. Ledger rows created
/// when a [CashRequest] is approved set both so the movement stays linked.
class MoneyTransaction extends Equatable {
  final MoneyTransactionType type;
  final int amountEgp;
  final String label;
  final String? id;
  final String? cashRequestId;
  final DateTime? createdAt;

  const MoneyTransaction({
    required this.type,
    required this.amountEgp,
    required this.label,
    this.id,
    this.cashRequestId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    type,
    amountEgp,
    label,
    id,
    cashRequestId,
    createdAt,
  ];
}
