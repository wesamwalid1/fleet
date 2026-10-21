import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/approvals/data/repositories/approval_repository_impl.dart';
import '../../features/approvals/domain/repositories/approval_repository.dart';
import '../../features/approvals/domain/usecases/approve_incoming_transfer.dart';
import '../../features/approvals/domain/usecases/approve_vault_receipt.dart';
import '../../features/approvals/domain/usecases/confirm_road_expense.dart';
import '../../features/approvals/domain/usecases/decline_incoming_transfer.dart';
import '../../features/approvals/domain/usecases/reject_road_expense.dart';
import '../../features/approvals/presentation/bloc/approvals_bloc.dart';
import '../../features/approvals/presentation/bloc/approvals_event.dart';
import '../../features/finance/data/datasources/mock_cash_ledger.dart';
import '../../features/finance/data/repositories/cash_transfer_repository_impl.dart';
import '../../features/finance/data/repositories/expense_repository_impl.dart';
import '../../features/finance/domain/repositories/cash_transfer_repository.dart';
import '../../features/finance/domain/repositories/expense_repository.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/bloc/history_event.dart';
import '../../features/home/data/datasources/mock_driver_data_source.dart';
import '../../features/home/data/datasources/mock_finance_data_source.dart';
import '../../features/home/data/repositories/driver_repository_impl.dart';
import '../../features/home/data/repositories/session_finance_repository.dart';
import '../../features/home/domain/repositories/driver_repository.dart';
import '../../features/home/domain/repositories/finance_repository.dart';
import '../../features/home/domain/summarize_transactions.dart';
import '../../features/home/domain/usecases/get_current_driver.dart';
import '../../features/home/domain/usecases/get_financial_summary.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../navigation/portal_shell.dart';

class HomeScope extends StatelessWidget {
  final DriverRepository? repository;
  final FinanceRepository? financeRepository;
  final DateTime Function()? now;
  final bool seedApprovals;
  final void Function(MockCashLedger ledger)? configureLedger;

  const HomeScope({
    super.key,
    this.repository,
    this.financeRepository,
    this.now,
    this.seedApprovals = true,
    this.configureLedger,
  });

  @override
  Widget build(BuildContext context) {
    final opening = summarizeTransactions(
      maxLimitEgp: MockFinanceDataSource.maxLimitEgp,
      transactions: [
        for (final transaction in MockFinanceDataSource.transactions)
          transaction.toEntity(),
      ],
    );
    final ledger = MockCashLedger(senderBalanceEgp: opening.balanceEgp);
    if (seedApprovals) ledger.seedDriverApprovals();
    configureLedger?.call(ledger);

    return RepositoryProvider<DriverRepository>(
      create: (_) =>
          repository ?? const DriverRepositoryImpl(MockDriverDataSource()),
      child: RepositoryProvider<FinanceRepository>(
        create: (_) =>
            financeRepository ??
            SessionFinanceRepository(const MockFinanceDataSource(), ledger),
        child: RepositoryProvider<CashTransferRepository>(
          create: (_) => CashTransferRepositoryImpl(ledger),
          child: RepositoryProvider<ExpenseRepository>(
            create: (_) => ExpenseRepositoryImpl(ledger),
            child: RepositoryProvider<ApprovalRepository>(
              create: (_) => ApprovalRepositoryImpl(ledger),
              child: RepositoryProvider<HistoryRepository>(
                create: (_) => HistoryRepositoryImpl(ledger),
                child: Builder(
                  builder: (context) {
                    final approvals = context.read<ApprovalRepository>();
                    final history = context.read<HistoryRepository>();
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) => HomeBloc(
                            GetCurrentDriver(context.read<DriverRepository>()),
                            GetFinancialSummary(
                              context.read<FinanceRepository>(),
                            ),
                          )..add(const HomeStarted()),
                        ),
                        BlocProvider(
                          create: (_) => ApprovalsBloc(
                            driverId: MockCashLedger.senderId,
                            repository: approvals,
                            approveVaultReceipt: ApproveVaultReceipt(approvals),
                            approveIncomingTransfer: ApproveIncomingTransfer(
                              approvals,
                            ),
                            declineIncomingTransfer: DeclineIncomingTransfer(
                              approvals,
                            ),
                            confirmRoadExpense: ConfirmRoadExpense(approvals),
                            rejectRoadExpense: RejectRoadExpense(approvals),
                          )..add(const ApprovalsStarted()),
                        ),
                        BlocProvider(
                          create: (_) => HistoryBloc(
                            driverId: MockCashLedger.senderId,
                            repository: history,
                          )..add(const HistoryStarted()),
                        ),
                      ],
                      child: PortalShell(now: now ?? DateTime.now),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
