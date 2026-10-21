sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeFinanceRetried extends HomeEvent {
  const HomeFinanceRetried();
}

final class HomeSummaryRefreshed extends HomeEvent {
  const HomeSummaryRefreshed();
}
