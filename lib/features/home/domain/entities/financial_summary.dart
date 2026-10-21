import 'package:equatable/equatable.dart';

class FinancialSummary extends Equatable {
  final int balanceEgp;
  final int chargeEgp;
  final int maxLimitEgp;

  const FinancialSummary({
    required this.balanceEgp,
    required this.chargeEgp,
    required this.maxLimitEgp,
  });

  @override
  List<Object?> get props => [balanceEgp, chargeEgp, maxLimitEgp];
}
