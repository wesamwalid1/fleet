import 'package:equatable/equatable.dart';

import 'expense_request.dart';

class RecordExpenseResult extends Equatable {
  final ExpenseRequest expense;
  final int balanceEgp;

  const RecordExpenseResult({required this.expense, required this.balanceEgp});

  @override
  List<Object?> get props => [expense, balanceEgp];
}
