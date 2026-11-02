import 'package:flutter/material.dart';

import '../../domain/entities/history_entry.dart';
import 'transaction_detail_sheet.dart';

/// Opens the shared transaction details sheet for a recorded expense.
Future<void> showExpenseDetailSheet(
  BuildContext context, {
  required HistoryEntry entry,
}) {
  return showTransactionDetailSheet(context, entry: entry);
}
