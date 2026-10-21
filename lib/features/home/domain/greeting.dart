enum GreetingPeriod { morning, afternoon, evening }

/// Local-time greeting period.
///
/// Morning is 00:00–11:59, afternoon is 12:00–16:59, and evening is 17:00–23:59.
/// The screenshot only shows morning, so these hour boundaries are an assumption.
GreetingPeriod greetingFor(DateTime localTime) {
  final hour = localTime.hour;
  if (hour < 12) return GreetingPeriod.morning;
  if (hour < 17) return GreetingPeriod.afternoon;
  return GreetingPeriod.evening;
}
