import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/frame/after_next_frame.dart';

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

  /// Completer from a pull that arrived while finance was still loading.
  Completer<void>? _queuedRefreshDone;

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
    if (current is! HomeReady) {
      _completeDone(event.done);
      await event.window?.participantFinished();
      return;
    }
    if (current.financeStatus == HomeFinanceStatus.loading) {
      _refreshWhenReady = true;
      _queueRefreshDone(event.done);
      await event.window?.participantFinished();
      return;
    }

    final prior = current.summary;
    // Enter loading so Home can show finance skeletons; keep [prior] for
    // failure restore. LimitMeter unmounts while loading and remounts from
    // zero when ready — including when the returned target is unchanged.
    emit(
      HomeReady(
        driver: current.driver,
        summary: prior,
        financeStatus: HomeFinanceStatus.loading,
      ),
    );

    final load = ++_loads;
    final window = event.window;
    try {
      await afterNextFrame();
      window?.markPainted();
      if (isClosed || load != _loads) {
        await window?.participantFinished();
        return;
      }
      final FinancialSummary summary;
      try {
        summary = await _getFinancialSummary();
      } catch (_) {
        if (load != _loads) {
          await window?.participantFinished();
          return;
        }
        await window?.participantFinished();
        if (prior != null) {
          emit(
            HomeReady(
              driver: current.driver,
              summary: prior,
              financeStatus: HomeFinanceStatus.ready,
            ),
          );
        } else {
          emit(
            HomeReady(
              driver: current.driver,
              summary: null,
              financeStatus: HomeFinanceStatus.failed,
            ),
          );
        }
        return;
      }
      if (load != _loads) {
        await window?.participantFinished();
        return;
      }
      await window?.participantFinished();
      emit(
        HomeReady(
          driver: current.driver,
          summary: summary,
          financeStatus: HomeFinanceStatus.ready,
        ),
      );
    } finally {
      _completeDone(event.done);
    }
    if (_refreshWhenReady) {
      _refreshWhenReady = false;
      final queued = _queuedRefreshDone;
      _queuedRefreshDone = null;
      add(HomeSummaryRefreshed(done: queued));
    }
  }

  Future<void> _loadSummary(Emitter<HomeState> emit, Driver driver) async {
    final load = ++_loads;
    _refreshWhenReady = false;
    // Loading was already emitted by the caller. Paint that frame before
    // the summary read can replace it.
    await afterNextFrame();
    if (isClosed || load != _loads) return;
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
      final queued = _queuedRefreshDone;
      _queuedRefreshDone = null;
      add(HomeSummaryRefreshed(done: queued));
    }
  }

  void _queueRefreshDone(Completer<void>? done) {
    if (done == null) return;
    final previous = _queuedRefreshDone;
    _queuedRefreshDone = done;
    if (previous != null && previous != done && !previous.isCompleted) {
      // Link older waiters to the newest queued completer.
      done.future.whenComplete(() => _completeDone(previous));
    }
  }

  void _completeDone(Completer<void>? done) {
    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }

  @override
  Future<void> close() async {
    await _financeChanges?.cancel();
    return super.close();
  }
}
