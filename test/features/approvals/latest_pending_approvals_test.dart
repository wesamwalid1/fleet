import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/domain/latest_pending_approvals.dart';
import 'package:driver_portal_app/features/finance/domain/entities/approval_timing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newest pending requests come first and completed ones are omitted', () {
    final items = [
      _item('old', DateTime(2026, 1, 1)),
      _item('mid', DateTime(2026, 6, 1)),
      _item('done', DateTime(2026, 12, 1), outcome: ApprovalOutcome.approved),
      _item('new', DateTime(2026, 9, 1)),
      _item('older-minutes', DateTime(2025, 1, 1), minutes: 30),
      _item('newer-minutes', DateTime(2025, 1, 1), minutes: 5),
      _item('just-now', DateTime(2024, 1, 1), justNow: true),
    ];

    final latest = latestPendingApprovals(items);

    expect(latest.map((item) => item.id), [
      'just-now',
      'newer-minutes',
      'older-minutes',
    ]);
    expect(latest.map((item) => item.id), isNot(contains('done')));
  });

  test('dated requests are newest first and only three are kept', () {
    final items = [
      _item('jan', DateTime(2026, 1, 1)),
      _item('apr', DateTime(2026, 4, 1)),
      _item('feb', DateTime(2026, 2, 1)),
      _item('mar', DateTime(2026, 3, 1)),
      _item(
        'recorded-history',
        DateTime(2026, 8, 1),
        outcome: ApprovalOutcome.rejected,
      ),
    ];

    expect(latestPendingApprovals(items).map((item) => item.id), [
      'apr',
      'mar',
      'feb',
    ]);
  });

  test('an empty pending list stays empty', () {
    expect(
      latestPendingApprovals([
        _item('done', DateTime(2026, 5, 1), outcome: ApprovalOutcome.approved),
      ]),
      isEmpty,
    );
    expect(latestPendingApprovals(const []), isEmpty);
  });
}

ApprovalItem _item(
  String id,
  DateTime occurredAt, {
  ApprovalOutcome outcome = ApprovalOutcome.pending,
  int? minutes,
  bool justNow = false,
}) {
  return ApprovalItem(
    id: id,
    kind: ApprovalKind.vault,
    outcome: outcome,
    amountEgp: 100,
    occurredAt: occurredAt,
    reference: id,
    recency: justNow
        ? ApprovalRecency.justNow
        : minutes == null
        ? null
        : ApprovalRecency.minutesAgo,
    minutes: minutes ?? 0,
  );
}
