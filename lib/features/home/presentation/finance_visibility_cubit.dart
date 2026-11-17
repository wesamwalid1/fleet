import 'package:flutter_bloc/flutter_bloc.dart';

/// In-memory show/hide state for the two Home finance groups.
///
/// A new [HomeScope] creates a new cubit, so a new session starts hidden.
/// Nothing here is written to disk.
class FinanceVisibilityState {
  const FinanceVisibilityState({
    this.balanceVisible = false,
    this.limitVisible = false,
  });

  final bool balanceVisible;
  final bool limitVisible;

  @override
  bool operator ==(Object other) =>
      other is FinanceVisibilityState &&
      other.balanceVisible == balanceVisible &&
      other.limitVisible == limitVisible;

  @override
  int get hashCode => Object.hash(balanceVisible, limitVisible);
}

class FinanceVisibilityCubit extends Cubit<FinanceVisibilityState> {
  FinanceVisibilityCubit() : super(const FinanceVisibilityState());

  void toggleBalance() {
    emit(
      FinanceVisibilityState(
        balanceVisible: !state.balanceVisible,
        limitVisible: state.limitVisible,
      ),
    );
  }

  void toggleLimit() {
    emit(
      FinanceVisibilityState(
        balanceVisible: state.balanceVisible,
        limitVisible: !state.limitVisible,
      ),
    );
  }
}
