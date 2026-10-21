enum ApprovalRecency { justNow, minutesAgo }

class ApprovalTiming {
  final ApprovalRecency recency;
  final int minutes;

  const ApprovalTiming.justNow()
    : recency = ApprovalRecency.justNow,
      minutes = 0;

  const ApprovalTiming.minutesAgo(this.minutes)
    : recency = ApprovalRecency.minutesAgo;
}
