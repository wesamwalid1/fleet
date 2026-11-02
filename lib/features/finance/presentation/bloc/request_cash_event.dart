sealed class RequestCashEvent {
  const RequestCashEvent();
}

final class RequestCashStarted extends RequestCashEvent {
  const RequestCashStarted();
}

final class RequestCashAmountChanged extends RequestCashEvent {
  final int amountEgp;

  const RequestCashAmountChanged(this.amountEgp);
}

final class RequestCashNoteChanged extends RequestCashEvent {
  final String note;

  const RequestCashNoteChanged(this.note);
}

final class RequestCashSubmitted extends RequestCashEvent {
  const RequestCashSubmitted();
}
