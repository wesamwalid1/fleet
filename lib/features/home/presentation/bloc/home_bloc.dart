import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/driver.dart';
import '../../domain/entities/financial_summary.dart';
import '../../domain/usecases/get_current_driver.dart';
import '../../domain/usecases/get_financial_summary.dart';
import '../../domain/usecases/watch_finance_changes.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentDriver _getCurrentDriver;
  final GetFinancialSummary _getFinancialSummary;
  StreamSubscription<void>? _financeChanges;

  /// Numbers each summary load so a slower, older one never overwrites
  /// newer figures. Refreshes run side by side and only the newest emits.
  int _loads = 0;

  /// A change arrived while the summary was loading; refresh once it lands.
  bool _refreshWhenReady = false;

  HomeBloc(
    this._getCurrentDriver,
    this._getFinancialSummary, {
    WatchFinanceChanges? watchFinanceChanges,
  }) : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeFinanceRetried>(_onFinanceRetried, transformer: droppable());
    on<HomeSummaryRefreshed>(_onSummaryRefreshed);
    _financeChanges = watchFinanceChanges?.call().listen(
      (_) => add(const HomeSummaryRefreshed()),
    );
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
    await _loadSummary(emit, driver);
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
    await _loadSummary(emit, current.driver);
  }

  Future<void> _onSummaryRefreshed(
    HomeSummaryRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeReady) return;
    if (current.financeStatus == HomeFinanceStatus.loading) {
      _refreshWhenReady = true;
      return;
    }

    final load = ++_loads;
    final FinancialSummary summary;
    try {
      summary = await _getFinancialSummary();
    } catch (_) {
      if (load != _loads) return;
      emit(
        HomeReady(
          driver: current.driver,
          summary: null,
          financeStatus: HomeFinanceStatus.failed,
        ),
      );
      return;
    }
    if (load != _loads) return;
    emit(
      HomeReady(
        driver: current.driver,
        summary: summary,
        financeStatus: HomeFinanceStatus.ready,
      ),
    );
  }

  Future<void> _loadSummary(Emitter<HomeState> emit, Driver driver) async {
    final load = ++_loads;
    _refreshWhenReady = false;
    try {
      final summary = await _getFinancialSummary();
      if (load != _loads) return;
      emit(
        HomeReady(
          driver: driver,
          summary: summary,
          financeStatus: HomeFinanceStatus.ready,
        ),
      );
    } catch (_) {
      if (load != _loads) return;
      emit(
        HomeReady(
          driver: driver,
          summary: null,
          financeStatus: HomeFinanceStatus.failed,
        ),
      );
    }
    if (_refreshWhenReady) {
      _refreshWhenReady = false;
      add(const HomeSummaryRefreshed());
    }
  }

  @override
  Future<void> close() async {
    await _financeChanges?.cancel();
    return super.close();
  }
}
