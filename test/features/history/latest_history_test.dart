import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/history/domain/latest_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latest rows are the three newest timestamps, each once', () {
    final older = _entry('A', DateTime(2026, 5, 1));
    final tiedLow = _entry('B', DateTime(2026, 5, 13));
    final tiedHigh = _entry('M', DateTime(2026, 5, 13));
    final newest = _entry('Z', DateTime(2026, 6, 1, 9));
    final middle = _entry('C', DateTime(2026, 5, 20));

    final latest = latestHistoryEntries([
      older,
      tiedLow,
      middle,
      newest,
      tiedHigh,
    ]);

    expect(latest.map((entry) => entry.id), ['Z', 'C', 'M']);
    expect(latest.map((entry) => entry.id), isNot(contains('A')));
    expect(latest.map((entry) => entry.id), isNot(contains('B')));
  });

  test('fewer than three rows are returned as they are', () {
    final only = _entry('EXP-1', DateTime(2026, 10, 21), HistoryKind.expense);
    expect(latestHistoryEntries([only]).single.id, 'EXP-1');
    expect(latestHistoryEntries(const []), isEmpty);
  });
}

HistoryEntry _entry(
  String id,
  DateTime occurredAt, [
  HistoryKind kind = HistoryKind.vault,
]) {
  return HistoryEntry(
    id: id,
    kind: kind,
    amountEgp: 10,
    credit:
        kind != HistoryKind.expense &&
        kind != HistoryKind.roadExpense &&
        kind != HistoryKind.outgoing,
    occurredAt: occurredAt,
    status: HistoryDisplayStatus.approved,
  );
}
