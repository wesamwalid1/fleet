import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/internet_reachability.dart';
import '../../domain/network_interface_monitor.dart';
import '../../domain/network_status.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

/// App-level connectivity: interface monitor + on-demand Internet probe.
///
/// Checks run only on start, interface change, and Retry — never on a timer.
///
/// Owns disposal of [monitor] and [reachability]: call them only from [close],
/// after any in-flight probe completes, so the HTTP client is not closed mid-
/// request. Repository providers must not dispose these dependencies.
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final NetworkInterfaceMonitor monitor;
  final InternetReachability reachability;
  final Duration probeTimeout;

  StreamSubscription<bool>? _subscription;
  int _checkGeneration = 0;
  Future<void>? _evaluating;

  ConnectivityBloc({
    required this.monitor,
    required this.reachability,
    this.probeTimeout = const Duration(seconds: 3),
  }) : super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityRetryRequested>(_onRetry);
    on<ConnectivityInterfaceChanged>(_onInterfaceChanged);
  }

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    _subscription ??= monitor.onChanged.listen(
      (hasInterface) => add(ConnectivityInterfaceChanged(hasInterface)),
      onError: (_) => add(const ConnectivityInterfaceChanged(false)),
    );
    await _evaluate(emit);
  }

  Future<void> _onRetry(
    ConnectivityRetryRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _evaluate(emit);
  }

  Future<void> _onInterfaceChanged(
    ConnectivityInterfaceChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _evaluate(emit, hasInterface: event.hasInterface);
  }

  Future<void> _evaluate(
    Emitter<ConnectivityState> emit, {
    bool? hasInterface,
  }) async {
    final generation = ++_checkGeneration;
    final run = _runEvaluate(emit, generation, hasInterface: hasInterface);
    _evaluating = run;
    try {
      await run;
    } finally {
      if (identical(_evaluating, run)) {
        _evaluating = null;
      }
    }
  }

  Future<void> _runEvaluate(
    Emitter<ConnectivityState> emit,
    int generation, {
    bool? hasInterface,
  }) async {
    final previous = state.status;
    emit(ConnectivityState(status: NetworkStatus.checking, previous: previous));

    final interface = hasInterface ?? await monitor.hasInterface;
    if (generation != _checkGeneration) return;

    if (!interface) {
      emit(
        ConnectivityState(status: NetworkStatus.offline, previous: previous),
      );
      return;
    }

    final reachable = await reachability.check(timeout: probeTimeout);
    if (generation != _checkGeneration) return;

    emit(
      ConnectivityState(
        status: reachable ? NetworkStatus.online : NetworkStatus.unreachable,
        previous: previous,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    // Invalidate emitters, then wait so reachability's client stays alive for
    // any probe that already started.
    _checkGeneration++;
    await _evaluating;
    await reachability.dispose();
    await monitor.dispose();
    return super.close();
  }
}
