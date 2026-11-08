import 'package:flutter/material.dart';

import '../../domain/entities/expense_trip_scope.dart';
import '../../domain/expense_attachment_picker.dart';
import '../pages/record_expense_flow_page.dart';

export 'record_expense_success.dart' show ExpenseRecordedPage;

/// Opens the full-screen Record Expense flow. Kept for existing call sites.
Future<void> showRecordExpenseSheet(
  BuildContext context, {
  required String driverId,
  String? tripId,
  ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
  ExpenseAttachmentPicker? picker,
}) {
  return openRecordExpenseFlow(
    context,
    driverId: driverId,
    tripId: tripId,
    tripScope: tripScope,
    picker: picker,
  );
}
