import 'package:driver_portal_app/features/finance/domain/entities/cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request_result.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/record_expense_result.dart';
import 'package:driver_portal_app/features/finance/domain/entities/send_cash_result.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/cash_request_success.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/record_expense_success.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/send_cash_success.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/haptic_log.dart';

void main() {
  testWidgets('cash request success fires success once across rebuilds', (
    tester,
  ) async {
    await _expectOneShotSuccess(
      tester,
      CashRequestSubmittedPage(result: _cashResult()),
    );
  });

  testWidgets('expense success fires success once across rebuilds', (
    tester,
  ) async {
    await _expectOneShotSuccess(
      tester,
      ExpenseRecordedPage(result: _expenseResult()),
    );
  });

  testWidgets('send cash success fires success once across rebuilds', (
    tester,
  ) async {
    await _expectOneShotSuccess(
      tester,
      RequestSentPage(
        result: _sendResult(),
        recipientName: 'Khaled Ramadan',
        recipientGivenName: 'Khaled',
      ),
    );
  });
}

Future<void> _expectOneShotSuccess(WidgetTester tester, Widget page) async {
  final log = HapticLog.install();
  late StateSetter setParentState;

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: StatefulBuilder(
        builder: (context, setState) {
          setParentState = setState;
          return page;
        },
      ),
    ),
  );
  await tester.pump();
  log.expectOnly(['HapticFeedbackType.mediumImpact']);

  setParentState(() {});
  await tester.pump();
  log.expectOnly(['HapticFeedbackType.mediumImpact']);
}

CashRequestResult _cashResult() {
  return CashRequestResult(
    request: CashRequest(
      id: 'req-1',
      requestNumber: 'REQ-1',
      driverId: 'DR-001',
      type: CashRequestType.requestCash,
      amountEgp: 500,
      createdAt: DateTime(2026, 10, 20),
      status: CashRequestStatus.pending,
    ),
    currentBalanceEgp: 2200,
    availableBalanceEgp: 2000,
    availableRequestCapacityEgp: 2800,
  );
}

RecordExpenseResult _expenseResult() {
  return RecordExpenseResult(
    expense: ExpenseRequest(
      id: 'exp-1',
      driverId: 'DR-001',
      tripId: 'trip-1',
      settlementType: SettlementType.fuel,
      amountEgp: 100,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 20),
      status: ExpenseStatus.recorded,
    ),
    balanceEgp: 2100,
  );
}

SendCashResult _sendResult() {
  return SendCashResult(
    transfer: CashTransfer(
      id: 'TRF-1',
      senderId: 'DR-001',
      recipientId: 'DR-003',
      amountEgp: 500,
      createdAt: DateTime(2026, 10, 20),
      status: TransferStatus.pending,
    ),
    senderBalanceEgp: 1700,
  );
}
