sealed class WithdrawCashEvent {
  const WithdrawCashEvent();
}

final class WithdrawCashStarted extends WithdrawCashEvent {
  const WithdrawCashStarted();
}

final class WithdrawCashAmountChanged extends WithdrawCashEvent {
  final int amountEgp;

  const WithdrawCashAmountChanged(this.amountEgp);
}

final class WithdrawCashNoteChanged extends WithdrawCashEvent {
  final String note;

  const WithdrawCashNoteChanged(this.note);
}

final class WithdrawCashSubmitted extends WithdrawCashEvent {
  const WithdrawCashSubmitted();
}
