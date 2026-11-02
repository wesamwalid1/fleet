import 'package:equatable/equatable.dart';

import 'cash_request.dart';

class CashRequestResult extends Equatable {
  final CashRequest request;
  final int currentBalanceEgp;
  final int availableBalanceEgp;
  final int availableRequestCapacityEgp;

  const CashRequestResult({
    required this.request,
    required this.currentBalanceEgp,
    required this.availableBalanceEgp,
    required this.availableRequestCapacityEgp,
  });

  @override
  List<Object?> get props => [
    request,
    currentBalanceEgp,
    availableBalanceEgp,
    availableRequestCapacityEgp,
  ];
}

class RequestCashFormSummary extends Equatable {
  final int currentBalanceEgp;
  final int maxLimitEgp;
  final int availableRequestCapacityEgp;

  const RequestCashFormSummary({
    required this.currentBalanceEgp,
    required this.maxLimitEgp,
    required this.availableRequestCapacityEgp,
  });

  @override
  List<Object?> get props => [
    currentBalanceEgp,
    maxLimitEgp,
    availableRequestCapacityEgp,
  ];
}

class WithdrawFormSummary extends Equatable {
  final int currentBalanceEgp;
  final int availableBalanceEgp;

  const WithdrawFormSummary({
    required this.currentBalanceEgp,
    required this.availableBalanceEgp,
  });

  @override
  List<Object?> get props => [currentBalanceEgp, availableBalanceEgp];
}
