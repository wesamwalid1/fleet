import 'package:equatable/equatable.dart';

import '../../domain/entities/cash_request_result.dart';

enum RequestCashError { invalidAmount, exceedsCapacity, unexpected }

class RequestCashState extends Equatable {
  final bool loading;
  final int currentBalanceEgp;
  final int maxLimitEgp;
  final int availableRequestCapacityEgp;
  final int amountEgp;
  final String note;
  final bool submitting;
  final RequestCashError? error;
  final CashRequestResult? result;

  const RequestCashState({
    this.loading = true,
    this.currentBalanceEgp = 0,
    this.maxLimitEgp = 0,
    this.availableRequestCapacityEgp = 0,
    this.amountEgp = 0,
    this.note = '',
    this.submitting = false,
    this.error,
    this.result,
  });

  bool get canSubmit =>
      !loading &&
      !submitting &&
      result == null &&
      amountEgp > 0 &&
      amountEgp <= availableRequestCapacityEgp;

  RequestCashState copyWith({
    bool? loading,
    int? currentBalanceEgp,
    int? maxLimitEgp,
    int? availableRequestCapacityEgp,
    int? amountEgp,
    String? note,
    bool? submitting,
    RequestCashError? error,
    bool clearError = false,
    CashRequestResult? result,
  }) {
    return RequestCashState(
      loading: loading ?? this.loading,
      currentBalanceEgp: currentBalanceEgp ?? this.currentBalanceEgp,
      maxLimitEgp: maxLimitEgp ?? this.maxLimitEgp,
      availableRequestCapacityEgp:
          availableRequestCapacityEgp ?? this.availableRequestCapacityEgp,
      amountEgp: amountEgp ?? this.amountEgp,
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    currentBalanceEgp,
    maxLimitEgp,
    availableRequestCapacityEgp,
    amountEgp,
    note,
    submitting,
    error,
    result,
  ];
}
