import 'package:equatable/equatable.dart';

sealed class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

final class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

final class ConnectivityRetryRequested extends ConnectivityEvent {
  const ConnectivityRetryRequested();
}

final class ConnectivityInterfaceChanged extends ConnectivityEvent {
  final bool hasInterface;

  const ConnectivityInterfaceChanged(this.hasInterface);

  @override
  List<Object?> get props => [hasInterface];
}
