import 'package:equatable/equatable.dart';

import '../../domain/entities/cash_request_result.dart';

enum RequestCashError { invalidAmount, exceedsCapacity, unexpected }

class RequestCashState extends Equatable {
  final bool loading;

  /// The form summary failed to load, so its figures are not known.
  final bool summaryUnavailable;
  final int currentBalanceEgp;
  final int totalBalanceEgp;
  final int maxLimitEgp;
  final int pendingRequestCashEgp;
  final int availableRequestCapacityEgp;
  final int amountEgp;
  final String note;
  final bool submitting;
  final RequestCashError? error;
  final CashRequestResult? result;

  const RequestCashState({
    this.loading = true,
    this.summaryUnavailable = false,
    this.currentBalanceEgp = 0,
    this.totalBalanceEgp = 0,
    this.maxLimitEgp = 0,
    this.pendingRequestCashEgp = 0,
    this.availableRequestCapacityEgp = 0,
    this.amountEgp = 0,
    this.note = '',
    this.submitting = false,
    this.error,
    this.result,
  });

  bool get canSubmit =>
      !loading &&
      !summaryUnavailable &&
      !submitting &&
      result == null &&
      amountEgp > 0 &&
      amountEgp <= availableRequestCapacityEgp;

  RequestCashState copyWith({
    bool? loading,
    bool? summaryUnavailable,
    int? currentBalanceEgp,
    int? totalBalanceEgp,
    int? maxLimitEgp,
    int? pendingRequestCashEgp,
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
      summaryUnavailable: summaryUnavailable ?? this.summaryUnavailable,
      currentBalanceEgp: currentBalanceEgp ?? this.currentBalanceEgp,
      totalBalanceEgp: totalBalanceEgp ?? this.totalBalanceEgp,
      maxLimitEgp: maxLimitEgp ?? this.maxLimitEgp,
      pendingRequestCashEgp:
          pendingRequestCashEgp ?? this.pendingRequestCashEgp,
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
    summaryUnavailable,
    currentBalanceEgp,
    totalBalanceEgp,
    maxLimitEgp,
    pendingRequestCashEgp,
    availableRequestCapacityEgp,
    amountEgp,
    note,
    submitting,
    error,
    result,
  ];
}
