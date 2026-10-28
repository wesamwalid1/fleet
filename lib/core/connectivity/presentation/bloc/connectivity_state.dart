import 'package:equatable/equatable.dart';

import '../../domain/network_status.dart';

class ConnectivityState extends Equatable {
  final NetworkStatus status;

  /// Previous status before the latest transition; used for reconnect hooks.
  final NetworkStatus? previous;

  const ConnectivityState({
    this.status = NetworkStatus.checking,
    this.previous,
  });

  bool get isOnline => status.isOnline;
  bool get isUnavailable => status.isUnavailable;
  bool get blocksOnlineWork => status.blocksOnlineWork;

  ConnectivityState copyWith({NetworkStatus? status, NetworkStatus? previous}) {
    return ConnectivityState(
      status: status ?? this.status,
      previous: previous ?? this.previous,
    );
  }

  @override
  List<Object?> get props => [status, previous];
}
