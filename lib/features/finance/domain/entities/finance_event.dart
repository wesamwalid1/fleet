import 'cash_transfer.dart';
import 'custody_receipt.dart';
import 'expense_request.dart';

/// A business outcome that already happened. Emitted only after the ledger
/// has applied the change successfully.
sealed class FinanceEvent {
  const FinanceEvent();
}

final class TransferCreated extends FinanceEvent {
  final CashTransfer transfer;

  const TransferCreated(this.transfer);
}

final class TransferApproved extends FinanceEvent {
  final CashTransfer transfer;

  const TransferApproved(this.transfer);
}

final class TransferRejected extends FinanceEvent {
  final CashTransfer transfer;

  const TransferRejected(this.transfer);
}

final class ExpenseRecorded extends FinanceEvent {
  final ExpenseRequest expense;

  const ExpenseRecorded(this.expense);
}

final class VaultReceiptCreated extends FinanceEvent {
  final CustodyReceipt receipt;

  const VaultReceiptCreated(this.receipt);
}
