import 'package:flutter/material.dart';

import '../pages/request_cash_flow_page.dart';

export 'cash_request_success.dart' show CashRequestSubmittedPage;
export '../pages/request_cash_flow_page.dart'
    show RequestCashFlowPage, openRequestCashFlow;

/// Opens the full-screen Request Cash flow. Kept for existing call sites.
Future<void> showRequestCashSheet(
  BuildContext context, {
  required String driverId,
  void Function(String requestId)? onViewTransaction,
}) {
  return openRequestCashFlow(
    context,
    driverId: driverId,
    onViewTransaction: onViewTransaction,
  );
}

/// Compatibility alias for widget tests that pump the flow content directly.
typedef RequestCashSheet = RequestCashFlowPage;
