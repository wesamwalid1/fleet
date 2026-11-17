import 'dart:async';

import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/driver_repository.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_current_driver.dart';
import 'package:driver_portal_app/features/home/domain/usecases/get_financial_summary.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_event.dart';
import 'package:driver_portal_app/features/home/presentation/bloc/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/paint_frame.dart';

void main() {
  const driver = Driver(
    fullName: LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي'),
  );
  const summary = FinancialSummary(
    balanceEgp: 2200,
    chargeEgp: 3200,
    maxLimitEgp: 5000,
  );
  final loading = HomeReady(
    driver: driver,
    summary: null,
    financeStatus: HomeFinanceStatus.loading,
  );
  final failed = HomeReady(
    driver: driver,
    summary: null,
    financeStatus: HomeFinanceStatus.failed,
  );
  final ready = HomeReady(
    driver: driver,
    summary: summary,
    financeStatus: HomeFinanceStatus.ready,
  );

  test('initial loading loads the driver and the financial summary', () async {
    final drivers = _FakeDriverRepository(onGet: () async => driver);
    final finance = _FakeFinanceRepository(onGet: () async => summary);
    final bloc = _bloc(drivers, finance);

    final states = _record(bloc);
    bloc.add(const HomeStarted());
    await paintFrame();
    expect(states, [const HomeLoading(), loading, ready]);

    expect(drivers.calls, 1);
    expect(finance.calls, 1);
    await bloc.close();
  });

  test(
    'finance retry keeps the driver and shows the returned summary',
    () async {
      final drivers = _FakeDriverRepository(onGet: () async => driver);
      final finance = _FakeFinanceRepository(
        onGet: () async => throw Exception('balance unavailable'),
      );
      final bloc = _bloc(drivers, finance);

      final started = _record(bloc);
      bloc.add(const HomeStarted());
      await paintFrame();
      expect(started, [const HomeLoading(), loading, failed]);

      finance.onGet = () async => summary;
      final retried = _record(bloc);
      bloc.add(const HomeFinanceRetried());
      await paintFrame();
      expect(retried, [loading, ready]);

      expect(drivers.calls, 1);
      expect(finance.calls, 2);
      expect(bloc.state, ready);
      await bloc.close();
    },
  );

  test(
    'a failed finance retry keeps the driver and the failed state',
    () async {
      final drivers = _FakeDriverRepository(onGet: () async => driver);
      final finance = _FakeFinanceRepository(
        onGet: () async => throw Exception('balance unavailable'),
      );
      final bloc = _bloc(drivers, finance);

      final started = _record(bloc);
      bloc.add(const HomeStarted());
      await paintFrame();
      expect(started, [const HomeLoading(), loading, failed]);

      final retried = _record(bloc);
      bloc.add(const HomeFinanceRetried());
      await paintFrame();
      expect(retried, [loading, failed]);

      expect(drivers.calls, 1);
      expect(finance.calls, 2);
      expect(bloc.state, failed);
      await bloc.close();
    },
  );

  test('a second finance retry is ignored while one is loading', () async {
    final completer = Completer<FinancialSummary>();
    final drivers = _FakeDriverRepository(onGet: () async => driver);
    final finance = _FakeFinanceRepository(
      onGet: () async => throw Exception('balance unavailable'),
    );
    final bloc = _bloc(drivers, finance);

    final started = _record(bloc);
    bloc.add(const HomeStarted());
    await paintFrame();
    expect(started, [const HomeLoading(), loading, failed]);

    finance.onGet = () => completer.future;
    final retried = _record(bloc);
    bloc.add(const HomeFinanceRetried());
    await paintFrame();
    expect(retried, [loading]);

    bloc.add(const HomeFinanceRetried());
    await Future<void>.delayed(Duration.zero);

    expect(drivers.calls, 1);
    expect(finance.calls, 2);
    completer.complete(summary);
    await expectLater(bloc.stream, emits(ready));
    expect(drivers.calls, 1);
    expect(finance.calls, 2);
    await bloc.close();
  });

  test('refreshing the summary does not reload the driver', () async {
    final drivers = _FakeDriverRepository(onGet: () async => driver);
    final finance = _FakeFinanceRepository(onGet: () async => summary);
    final bloc = _bloc(drivers, finance);
    const updated = FinancialSummary(
      balanceEgp: 1700,
      chargeEgp: 3200,
      maxLimitEgp: 5000,
    );

    final started = _record(bloc);
    bloc.add(const HomeStarted());
    await paintFrame();
    expect(started, [const HomeLoading(), loading, ready]);

    finance.onGet = () async => updated;
    final refreshed = _record(bloc);
    bloc.add(const HomeSummaryRefreshed());
    await paintFrame();
    expect(refreshed, [
      const HomeReady(
        driver: driver,
        summary: summary,
        financeStatus: HomeFinanceStatus.loading,
      ),
      const HomeReady(
        driver: driver,
        summary: updated,
        financeStatus: HomeFinanceStatus.ready,
      ),
    ]);

    expect(drivers.calls, 1);
    expect(finance.calls, 2);
    await bloc.close();
  });

  test(
    'HomeSummaryRefreshed failure keeps the last summary and completes done',
    () async {
      final drivers = _FakeDriverRepository(onGet: () async => driver);
      final finance = _FakeFinanceRepository(onGet: () async => summary);
      final bloc = _bloc(drivers, finance);

      final started = _record(bloc);
      bloc.add(const HomeStarted());
      await paintFrame();
      expect(started, [const HomeLoading(), loading, ready]);

      finance.onGet = () async => throw StateError('summary failed');
      final done = Completer<void>();
      bloc.add(HomeSummaryRefreshed(done: done));
      await paintFrame();
      await done.future;
      expect(bloc.state, ready);
      expect((bloc.state as HomeReady).summary, summary);
      expect(drivers.calls, 1);
      expect(finance.calls, 2);

      const updated = FinancialSummary(
        balanceEgp: 1900,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      );
      finance.onGet = () async => updated;
      final refreshed = _record(bloc);
      bloc.add(const HomeSummaryRefreshed());
      await paintFrame();
      expect(refreshed, [
        const HomeReady(
          driver: driver,
          summary: summary,
          financeStatus: HomeFinanceStatus.loading,
        ),
        const HomeReady(
          driver: driver,
          summary: updated,
          financeStatus: HomeFinanceStatus.ready,
        ),
      ]);
      await bloc.close();
    },
  );

  test(
    'HomeSummaryRefreshed failure with no prior summary stays failed',
    () async {
      final drivers = _FakeDriverRepository(onGet: () async => driver);
      final finance = _FakeFinanceRepository(
        onGet: () async => throw StateError('initial failed'),
      );
      final bloc = _bloc(drivers, finance);

      final started = _record(bloc);
      bloc.add(const HomeStarted());
      await paintFrame();
      expect(started, [const HomeLoading(), loading, failed]);

      final done = Completer<void>();
      bloc.add(HomeSummaryRefreshed(done: done));
      await paintFrame();
      await done.future;
      expect(bloc.state, failed);
      expect((bloc.state as HomeReady).summary, isNull);
      await bloc.close();
    },
  );
}

List<HomeState> _record(HomeBloc bloc) {
  final states = <HomeState>[];
  final sub = bloc.stream.listen(states.add);
  addTearDown(sub.cancel);
  return states;
}

HomeBloc _bloc(_FakeDriverRepository drivers, _FakeFinanceRepository finance) {
  return HomeBloc(GetCurrentDriver(drivers), GetFinancialSummary(finance));
}

class _FakeDriverRepository implements DriverRepository {
  final Future<Driver> Function() onGet;
  int calls = 0;

  _FakeDriverRepository({required this.onGet});

  @override
  Future<Driver> getCurrentDriver() {
    calls += 1;
    return onGet();
  }
}

class _FakeFinanceRepository implements FinanceRepository {
  Future<FinancialSummary> Function() onGet;
  int calls = 0;

  _FakeFinanceRepository({required this.onGet});

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() {
    calls += 1;
    return onGet();
  }
}
