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

  /// Available + Frozen, read from the same ledger snapshot as capacity.
  final int totalBalanceEgp;
  final int maxLimitEgp;

  /// Sum of Request Cash amounts still Pending.
  final int pendingRequestCashEgp;
  final int availableRequestCapacityEgp;

  const RequestCashFormSummary({
    required this.currentBalanceEgp,
    required this.totalBalanceEgp,
    required this.maxLimitEgp,
    required this.pendingRequestCashEgp,
    required this.availableRequestCapacityEgp,
  });

  @override
  List<Object?> get props => [
    currentBalanceEgp,
    totalBalanceEgp,
    maxLimitEgp,
    pendingRequestCashEgp,
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
