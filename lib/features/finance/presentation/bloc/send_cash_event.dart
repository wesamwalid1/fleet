sealed class SendCashEvent {
  const SendCashEvent();
}

final class SendCashStarted extends SendCashEvent {
  const SendCashStarted();
}

final class SendCashRecipientSelected extends SendCashEvent {
  final String recipientId;

  const SendCashRecipientSelected(this.recipientId);
}

final class SendCashAmountChanged extends SendCashEvent {
  final int amountEgp;

  const SendCashAmountChanged(this.amountEgp);
}

final class SendCashSubmitted extends SendCashEvent {
  const SendCashSubmitted();
}
