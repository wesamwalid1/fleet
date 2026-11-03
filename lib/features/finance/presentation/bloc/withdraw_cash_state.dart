import 'package:equatable/equatable.dart';

import '../../domain/entities/cash_request_result.dart';

enum WithdrawCashError { invalidAmount, exceedsAvailable, unexpected }

class WithdrawCashState extends Equatable {
  final bool loading;

  /// The form summary failed to load, so its figures are not known.
  final bool summaryUnavailable;
  final int currentBalanceEgp;
  final int availableBalanceEgp;
  final int amountEgp;
  final String note;
  final bool submitting;
  final WithdrawCashError? error;
  final CashRequestResult? result;

  const WithdrawCashState({
    this.loading = true,
    this.summaryUnavailable = false,
    this.currentBalanceEgp = 0,
    this.availableBalanceEgp = 0,
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
      amountEgp <= availableBalanceEgp;

  WithdrawCashState copyWith({
    bool? loading,
    bool? summaryUnavailable,
    int? currentBalanceEgp,
    int? availableBalanceEgp,
    int? amountEgp,
    String? note,
    bool? submitting,
    WithdrawCashError? error,
    bool clearError = false,
    CashRequestResult? result,
  }) {
    return WithdrawCashState(
      loading: loading ?? this.loading,
      summaryUnavailable: summaryUnavailable ?? this.summaryUnavailable,
      currentBalanceEgp: currentBalanceEgp ?? this.currentBalanceEgp,
      availableBalanceEgp: availableBalanceEgp ?? this.availableBalanceEgp,
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
    availableBalanceEgp,
    amountEgp,
    note,
    submitting,
    error,
    result,
  ];
}
