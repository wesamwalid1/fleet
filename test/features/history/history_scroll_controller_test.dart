import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/approve_vault_receipt.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/confirm_road_expense.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/decline_incoming_transfer.dart';
import 'package:driver_portal_app/features/approvals/domain/usecases/reject_road_expense.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/pages/history_page.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  testWidgets('standalone HistoryPage owns and disposes its scroll controller', (
    tester,
  ) async {
    await _pumpHistory(tester);
    final controller = _ledgerController(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(controller.hasClients, isFalse);
    expect(() => controller.dispose(), throwsFlutterError);
  });

  testWidgets('injected HistoryPage controller is not disposed by the page', (
    tester,
  ) async {
    final injected = ScrollController();

    await _pumpHistory(tester, scrollController: injected);
    expect(identical(_ledgerController(tester), injected), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(injected.hasClients, isFalse);
    // First dispose succeeds only if the page left ownership to the shell/caller.
    expect(() => injected.dispose(), returnsNormally);
    expect(() => injected.dispose(), throwsFlutterError);
  });
}

ScrollController _ledgerController(WidgetTester tester) {
  return tester
      .widget<CustomScrollView>(
        find.descendant(
          of: find.ancestor(
            of: find.byKey(const Key('history-title')),
            matching: find.byType(Column),
          ),
          matching: find.byType(CustomScrollView),
        ),
      )
      .controller!;
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  ScrollController? scrollController,
}) async {
  final ledger = MockCashLedger(senderBalanceEgp: 2200)..seedDriverApprovals();
  final approvals = ApprovalRepositoryImpl(ledger);
  final history = HistoryRepositoryImpl(ledger);

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
      home: withConnectivity(
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => HistoryBloc(
                driverId: MockCashLedger.senderId,
                repository: history,
              ),
            ),
            BlocProvider(
              create: (_) => ApprovalsBloc(
                driverId: MockCashLedger.senderId,
                repository: approvals,
                approveVaultReceipt: ApproveVaultReceipt(approvals),
                approveIncomingTransfer: ApproveIncomingTransfer(approvals),
                declineIncomingTransfer: DeclineIncomingTransfer(approvals),
                confirmRoadExpense: ConfirmRoadExpense(approvals),
                rejectRoadExpense: RejectRoadExpense(approvals),
              ),
            ),
          ],
          child: Scaffold(
            body: HistoryPage(
              now: () => DateTime(2026, 10, 21, 12),
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
