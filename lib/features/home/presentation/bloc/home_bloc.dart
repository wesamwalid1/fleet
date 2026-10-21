import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/driver.dart';
import '../../domain/usecases/get_current_driver.dart';
import '../../domain/usecases/get_financial_summary.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentDriver _getCurrentDriver;
  final GetFinancialSummary _getFinancialSummary;

  HomeBloc(this._getCurrentDriver, this._getFinancialSummary)
    : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeFinanceRetried>(_onFinanceRetried, transformer: droppable());
    on<HomeSummaryRefreshed>(_onSummaryRefreshed);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    if (state is HomeLoading) return;
    emit(const HomeLoading());

    final Driver driver;
    try {
      driver = await _getCurrentDriver();
    } catch (_) {
      emit(const HomeFailure());
      return;
    }

    emit(
      HomeReady(
        driver: driver,
        summary: null,
        financeStatus: HomeFinanceStatus.loading,
      ),
    );

    try {
      final summary = await _getFinancialSummary();
      emit(
        HomeReady(
          driver: driver,
          summary: summary,
          financeStatus: HomeFinanceStatus.ready,
        ),
      );
    } catch (_) {
      emit(
        HomeReady(
          driver: driver,
          summary: null,
          financeStatus: HomeFinanceStatus.failed,
        ),
      );
    }
  }

  Future<void> _onFinanceRetried(
    HomeFinanceRetried event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeReady ||
        current.financeStatus != HomeFinanceStatus.failed) {
      return;
    }

    emit(
      HomeReady(
        driver: current.driver,
        summary: null,
        financeStatus: HomeFinanceStatus.loading,
      ),
    );

    try {
      final summary = await _getFinancialSummary();
      emit(
        HomeReady(
          driver: current.driver,
          summary: summary,
          financeStatus: HomeFinanceStatus.ready,
        ),
      );
    } catch (_) {
      emit(
        HomeReady(
          driver: current.driver,
          summary: null,
          financeStatus: HomeFinanceStatus.failed,
        ),
      );
    }
  }

  Future<void> _onSummaryRefreshed(
    HomeSummaryRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeReady ||
        current.financeStatus == HomeFinanceStatus.loading) {
      return;
    }

    try {
      final summary = await _getFinancialSummary();
      emit(
        HomeReady(
          driver: current.driver,
          summary: summary,
          financeStatus: HomeFinanceStatus.ready,
        ),
      );
    } catch (_) {
      emit(
        HomeReady(
          driver: current.driver,
          summary: null,
          financeStatus: HomeFinanceStatus.failed,
        ),
      );
    }
  }
}
