import 'package:flutter/material.dart';

import '../pages/withdraw_cash_flow_page.dart';

export '../pages/withdraw_cash_flow_page.dart'
    show WithdrawCashFlowPage, openWithdrawCashFlow;

/// Opens the full-screen Withdraw flow. Kept for existing call sites.
Future<void> showWithdrawCashSheet(
  BuildContext context, {
  required String driverId,
  void Function(String requestId)? onViewTransaction,
}) {
  return openWithdrawCashFlow(
    context,
    driverId: driverId,
    onViewTransaction: onViewTransaction,
  );
}

/// Compatibility alias for widget tests that pump the flow content directly.
typedef WithdrawCashSheet = WithdrawCashFlowPage;
