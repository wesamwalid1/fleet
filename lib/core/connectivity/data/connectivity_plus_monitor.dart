import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/network_interface_monitor.dart';

/// [NetworkInterfaceMonitor] backed by `connectivity_plus`.
class ConnectivityPlusMonitor implements NetworkInterfaceMonitor {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  StreamController<bool>? _controller;
  bool? _last;

  ConnectivityPlusMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  static bool _usable(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );
  }

  @override
  Future<bool> get hasInterface async {
    try {
      return _usable(await _connectivity.checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onChanged {
    final existing = _controller;
    if (existing != null) return existing.stream;

    late final StreamController<bool> controller;
    controller = StreamController<bool>.broadcast(
      onListen: () async {
        _subscription ??= _connectivity.onConnectivityChanged.listen(
          (results) {
            final value = _usable(results);
            if (_last == value) return;
            _last = value;
            _controller?.add(value);
          },
          onError: (_) {
            if (_last == false) return;
            _last = false;
            _controller?.add(false);
          },
        );
        try {
          final value = _usable(await _connectivity.checkConnectivity());
          _last = value;
          if (!controller.isClosed) controller.add(value);
        } catch (_) {
          _last = false;
          if (!controller.isClosed) controller.add(false);
        }
      },
      onCancel: () async {
        if (controller.hasListener) return;
        await _subscription?.cancel();
        _subscription = null;
      },
    );
    _controller = controller;
    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
    _last = null;
  }
}
