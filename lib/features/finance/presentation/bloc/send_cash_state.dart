import 'package:equatable/equatable.dart';

import '../../domain/entities/finance_driver.dart';
import '../../domain/entities/send_cash_result.dart';

enum SendCashError {
  selectRecipient,
  invalidAmount,
  insufficientBalance,
  unexpected,
}

class SendCashState extends Equatable {
  final bool loading;
  final List<FinanceDriver> recipients;
  final String? recipientId;
  final int amountEgp;
  final int senderBalanceEgp;
  final bool submitting;
  final SendCashError? error;
  final SendCashResult? result;

  const SendCashState({
    this.loading = true,
    this.recipients = const [],
    this.recipientId,
    this.amountEgp = 0,
    this.senderBalanceEgp = 0,
    this.submitting = false,
    this.error,
    this.result,
  });

  FinanceDriver? get selectedRecipient {
    for (final driver in recipients) {
      if (driver.id == recipientId) return driver;
    }
    return null;
  }

  bool get canSubmit =>
      !loading &&
      !submitting &&
      result == null &&
      recipientId != null &&
      amountEgp > 0 &&
      amountEgp <= senderBalanceEgp;

  SendCashState copyWith({
    bool? loading,
    List<FinanceDriver>? recipients,
    String? recipientId,
    int? amountEgp,
    int? senderBalanceEgp,
    bool? submitting,
    SendCashError? error,
    bool clearError = false,
    SendCashResult? result,
  }) {
    return SendCashState(
      loading: loading ?? this.loading,
      recipients: recipients ?? this.recipients,
      recipientId: recipientId ?? this.recipientId,
      amountEgp: amountEgp ?? this.amountEgp,
      senderBalanceEgp: senderBalanceEgp ?? this.senderBalanceEgp,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    recipients,
    recipientId,
    amountEgp,
    senderBalanceEgp,
    submitting,
    error,
    result,
  ];
}
