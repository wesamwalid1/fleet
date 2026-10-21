import '../../finance/domain/entities/approval_timing.dart';
import 'entities/approval_item.dart';

const latestPendingApprovalLimit = 3;

/// Actionable requests for Home, newest first.
///
/// "Just now" is newer than "minutes ago", and both are newer than a request
/// that only has a calendar time. Calendar times are compared newest first.
List<ApprovalItem> latestPendingApprovals(
  Iterable<ApprovalItem> items, {
  int limit = latestPendingApprovalLimit,
}) {
  final pending = [
    for (final item in items)
      if (item.isPending) item,
  ];
  pending.sort((a, b) {
    final tier = _tier(b).compareTo(_tier(a));
    if (tier != 0) return tier;
    if (a.recency == ApprovalRecency.minutesAgo &&
        b.recency == ApprovalRecency.minutesAgo &&
        a.minutes != b.minutes) {
      return a.minutes.compareTo(b.minutes);
    }
    final byTime = b.occurredAt.compareTo(a.occurredAt);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  });
  if (limit <= 0 || pending.isEmpty) return const [];
  if (pending.length <= limit) return List.unmodifiable(pending);
  return List.unmodifiable(pending.take(limit));
}

int _tier(ApprovalItem item) {
  return switch (item.recency) {
    ApprovalRecency.justNow => 2,
    ApprovalRecency.minutesAgo => 1,
    null => 0,
  };
}
