import 'package:driver_portal_app/core/connectivity/domain/network_status.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  test('startup with no interface is offline', () async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: false);
    final reachability = FakeInternetReachability(reachable: true);
    final bloc = ConnectivityBloc(monitor: monitor, reachability: reachability);
    addTearDown(bloc.close);

    bloc.add(const ConnectivityStarted());
    await pumpEventQueue();

    expect(bloc.state.status, NetworkStatus.offline);
    expect(reachability.checks, 0);
  });

  test('interface without confirmed Internet is unreachable', () async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: false);
    final bloc = ConnectivityBloc(monitor: monitor, reachability: reachability);
    addTearDown(bloc.close);

    bloc.add(const ConnectivityStarted());
    await pumpEventQueue();

    expect(bloc.state.status, NetworkStatus.unreachable);
    expect(reachability.checks, 1);
  });

  test('confirmed Internet is online', () async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);
    final bloc = ConnectivityBloc(monitor: monitor, reachability: reachability);
    addTearDown(bloc.close);

    bloc.add(const ConnectivityStarted());
    await pumpEventQueue();

    expect(bloc.state.status, NetworkStatus.online);
    expect(reachability.checks, 1);
  });

  test('retry re-runs the probe', () async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: false);
    final bloc = ConnectivityBloc(monitor: monitor, reachability: reachability);
    addTearDown(bloc.close);

    bloc.add(const ConnectivityStarted());
    await pumpEventQueue();
    expect(bloc.state.status, NetworkStatus.unreachable);

    reachability.reachable = true;
    bloc.add(const ConnectivityRetryRequested());
    await pumpEventQueue();

    expect(bloc.state.status, NetworkStatus.online);
    expect(reachability.checks, 2);
  });

  test('interface change triggers a new check', () async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);
    final bloc = ConnectivityBloc(monitor: monitor, reachability: reachability);
    addTearDown(bloc.close);

    bloc.add(const ConnectivityStarted());
    await pumpEventQueue();
    expect(bloc.state.status, NetworkStatus.online);

    monitor.setHasInterface(false);
    await pumpEventQueue();

    expect(bloc.state.status, NetworkStatus.offline);
  });

  test('close cancels the interface subscription', () async {
    final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
    final reachability = FakeInternetReachability(reachable: true);
    final bloc = ConnectivityBloc(monitor: monitor, reachability: reachability);

    bloc.add(const ConnectivityStarted());
    await pumpEventQueue();
    expect(bloc.state.status, NetworkStatus.online);

    await bloc.close();
    expect(bloc.isClosed, isTrue);
    expect(reachability.checks, 1);
    expect(reachability.disposed, isTrue);
  });

  test(
    'close waits for an in-flight probe before disposing reachability',
    () async {
      final monitor = FakeNetworkInterfaceMonitor(hasInterface: true);
      final reachability = GateInternetReachability();
      final bloc = ConnectivityBloc(
        monitor: monitor,
        reachability: reachability,
        probeTimeout: const Duration(seconds: 5),
      );

      bloc.add(const ConnectivityStarted());
      await pumpEventQueue();
      expect(bloc.state.status, NetworkStatus.checking);
      expect(reachability.checks, 1);
      expect(reachability.disposed, isFalse);

      final closing = bloc.close();
      await pumpEventQueue();
      expect(reachability.disposed, isFalse);

      reachability.complete(reachable: true);
      await closing;

      expect(bloc.isClosed, isTrue);
      expect(reachability.disposed, isTrue);
    },
  );
}
