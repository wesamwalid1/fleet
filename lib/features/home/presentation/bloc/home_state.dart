import 'package:equatable/equatable.dart';

import '../../domain/entities/driver.dart';
import '../../domain/entities/financial_summary.dart';

enum HomeFinanceStatus { loading, ready, failed }

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeReady extends HomeState {
  final Driver driver;
  final FinancialSummary? summary;
  final HomeFinanceStatus financeStatus;

  const HomeReady({
    required this.driver,
    required this.summary,
    required this.financeStatus,
  });

  @override
  List<Object?> get props => [driver, summary, financeStatus];
}

final class HomeFailure extends HomeState {
  const HomeFailure();
}
