import 'package:flutter/material.dart';

import '../pages/send_cash_flow_page.dart';

export 'send_cash_success.dart' show RequestSentPage;

const sendCashQuickAmounts = [500, 1000, 1500, 2000];

/// Opens the full-screen Send Cash flow. Kept for existing call sites.
Future<void> showSendCashSheet(
  BuildContext context, {
  required String senderId,
  void Function(String transferId)? onViewTransaction,
}) {
  return openSendCashFlow(
    context,
    senderId: senderId,
    onViewTransaction: onViewTransaction,
  );
}
