import 'package:equatable/equatable.dart';

class FinancialSummary extends Equatable {
  /// Available balance: the actual ledger balance, already reduced by pending
  /// outgoing reservations.
  final int balanceEgp;

  /// Pending Send Cash and pending Withdraw amounts.
  final int frozenBalanceEgp;
  final int chargeEgp;
  final int maxLimitEgp;

  const FinancialSummary({
    required this.balanceEgp,
    required this.chargeEgp,
    required this.maxLimitEgp,
    this.frozenBalanceEgp = 0,
  });

  int get availableBalanceEgp => balanceEgp;

  int get totalBalanceEgp => balanceEgp + frozenBalanceEgp;

  @override
  List<Object?> get props => [
    balanceEgp,
    frozenBalanceEgp,
    chargeEgp,
    maxLimitEgp,
  ];
}
