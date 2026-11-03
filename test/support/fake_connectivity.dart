import 'dart:async';

import 'package:driver_portal_app/core/connectivity/domain/internet_reachability.dart';
import 'package:driver_portal_app/core/connectivity/domain/network_interface_monitor.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/core/theme/domain/theme_repository.dart';
import 'package:driver_portal_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_portal_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Controllable network interface for offline-mode tests.
class FakeNetworkInterfaceMonitor implements NetworkInterfaceMonitor {
  FakeNetworkInterfaceMonitor({bool hasInterface = true})
    : hasInterfaceValue = hasInterface;

  bool hasInterfaceValue;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get hasInterface async => hasInterfaceValue;

  @override
  Stream<bool> get onChanged => _controller.stream;

  void setHasInterface(bool value) {
    if (hasInterfaceValue == value) return;
    hasInterfaceValue = value;
    _controller.add(value);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

/// Controllable Internet probe for offline-mode tests.
class FakeInternetReachability implements InternetReachability {
  FakeInternetReachability({this.reachable = true});

  bool reachable;
  int checks = 0;
  bool disposed = false;

  @override
  Future<bool> check({Duration timeout = const Duration(seconds: 3)}) async {
    checks += 1;
    return reachable;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

/// Holds the probe open until [complete] so tests can observe `checking`.
class GateInternetReachability implements InternetReachability {
  final Completer<bool> _gate = Completer<bool>();
  int checks = 0;
  bool disposed = false;

  void complete({bool reachable = true}) {
    if (!_gate.isCompleted) _gate.complete(reachable);
  }

  @override
  Future<bool> check({Duration timeout = const Duration(seconds: 3)}) async {
    checks += 1;
    // Ignore [timeout] so widget tests can pumpAndSettle while still checking.
    return _gate.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

/// [DriverPortalApp] with injectable connectivity defaults for tests.
Widget testPortalApp({
  Locale? locale,
  ThemeRepository? themeRepository,
  FakeNetworkInterfaceMonitor? networkMonitor,
  FakeInternetReachability? internetReachability,
  bool online = true,
  AuthRepository? authRepository,
  String initialRoute = AppRoute.login,
}) {
  return DriverPortalApp(
    locale: locale,
    themeRepository: themeRepository,
    authRepository: authRepository,
    initialRoute: initialRoute,
    networkMonitor:
        networkMonitor ?? FakeNetworkInterfaceMonitor(hasInterface: online),
    internetReachability:
        internetReachability ?? FakeInternetReachability(reachable: online),
  );
}

/// Wraps [child] with a started [ConnectivityBloc] for HomeScope-only pumps.
Widget withConnectivity({
  required Widget child,
  FakeNetworkInterfaceMonitor? networkMonitor,
  InternetReachability? internetReachability,
  bool online = true,
}) {
  final monitor =
      networkMonitor ?? FakeNetworkInterfaceMonitor(hasInterface: online);
  final reachability =
      internetReachability ?? FakeInternetReachability(reachable: online);
  return BlocProvider(
    create: (_) =>
        ConnectivityBloc(monitor: monitor, reachability: reachability)
          ..add(const ConnectivityStarted()),
    child: child,
  );
}
