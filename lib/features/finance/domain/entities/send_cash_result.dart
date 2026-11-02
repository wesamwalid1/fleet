import 'package:equatable/equatable.dart';

import 'cash_transfer.dart';

class SendCashResult extends Equatable {
  final CashTransfer transfer;

  /// Sender's Current Balance after the send (not Available Balance).
  final int senderBalanceEgp;

  const SendCashResult({
    required this.transfer,
    required this.senderBalanceEgp,
  });

  @override
  List<Object?> get props => [transfer, senderBalanceEgp];
}
