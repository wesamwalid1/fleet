import 'package:equatable/equatable.dart';

enum MoneyTransactionType { cashReceived, expense }

/// A whole-EGP movement. [amountEgp] must be greater than zero.
/// The transaction type decides whether that amount raises or lowers the balance.
class MoneyTransaction extends Equatable {
  final MoneyTransactionType type;
  final int amountEgp;
  final String label;

  const MoneyTransaction({
    required this.type,
    required this.amountEgp,
    required this.label,
  });

  @override
  List<Object?> get props => [type, amountEgp, label];
}
