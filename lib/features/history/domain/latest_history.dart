import 'entities/history_entry.dart';

const latestHistoryLimit = 3;

/// Newest ledger rows for Home. Sorting uses latest activity ([updatedAt]).
List<HistoryEntry> latestHistoryEntries(
  Iterable<HistoryEntry> entries, {
  int limit = latestHistoryLimit,
}) {
  final sorted = [...entries]
    ..sort((a, b) {
      final byTime = b.updatedAt.compareTo(a.updatedAt);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
  if (limit <= 0 || sorted.isEmpty) return const [];
  if (sorted.length <= limit) return List.unmodifiable(sorted);
  return List.unmodifiable(sorted.take(limit));
}
