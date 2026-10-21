import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

final class HistoryFilterSelected extends HistoryEvent {
  final HistoryFilter filter;

  const HistoryFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
}
