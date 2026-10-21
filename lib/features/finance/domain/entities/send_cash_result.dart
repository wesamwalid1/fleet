import 'package:equatable/equatable.dart';

import 'cash_transfer.dart';

class SendCashResult extends Equatable {
  final CashTransfer transfer;
  final int senderBalanceEgp;

  const SendCashResult({
    required this.transfer,
    required this.senderBalanceEgp,
  });

  @override
  List<Object?> get props => [transfer, senderBalanceEgp];
}
