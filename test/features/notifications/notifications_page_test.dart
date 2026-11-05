import 'dart:async';

import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/custody_receipt.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_ledger_row.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:driver_portal_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/domain/entities/app_notification.dart';
import 'package:driver_portal_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

const _me = MockCashLedger.senderId;

String _seedId(NotificationType type, String entityId) =>
    '$_me|${type.name}|$entityId|seed';

final _vaultPending = _seedId(
  NotificationType.vaultReceiptPending,
  'DSB-2025-0441',
);
final _vaultHandled = _seedId(
  NotificationType.vaultReceiptPending,
  'DSB-2025-0301',
);
final _roadPending = _seedId(
  NotificationType.roadExpensePending,
  'RE-2026-1041',
);
final _incomingPending = _seedId(
  NotificationType.incomingTransferPending,
  'TRF-2025-0123',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opening the center lists newest first and reads nothing', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);

    await _openCenter(tester);
    expect(find.byKey(const Key('notifications-title')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(Key('notification-$_roadPending'))).top,
      lessThan(
        tester.getRect(find.byKey(Key('notification-$_vaultPending'))).top,
      ),
    );
    expect(_unreadDots(), findsNWidgets(3));
    expect(find.byKey(Key('notification-unread-$_vaultHandled')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);
    await _openCenter(tester);
    expect(_unreadDots(), findsNWidgets(3));
  });

  testWidgets('all unread and read filter chips work', (tester) async {
    await _pump(tester);
    await _openCenter(tester);

    expect(find.byKey(const Key('notifications-filter-all')), findsOneWidget);
    expect(
      find.byKey(const Key('notifications-filter-unread')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('notifications-filter-read')), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.byKey(const Key('notifications-mark-all')), findsNothing);
    expect(find.text('Mark all as read'), findsNothing);

    await _selectFilter(tester, const Key('notifications-filter-unread'));
    expect(_tiles(), findsNWidgets(3));
    expect(find.byKey(Key('notification-$_vaultHandled')), findsNothing);

    await _selectFilter(tester, const Key('notifications-filter-read'));
    expect(_tiles(), findsOneWidget);
    expect(find.byKey(Key('notification-$_vaultHandled')), findsOneWidget);

    await _selectFilter(tester, const Key('notifications-filter-all'));
    expect(_tiles(), findsNWidgets(4));
  });

  testWidgets('selecting all chip restores the full list', (tester) async {
    await _pump(tester);
    await _openCenter(tester);

    await _selectFilter(tester, const Key('notifications-filter-unread'));
    expect(_tiles(), findsNWidgets(3));

    await _selectFilter(tester, const Key('notifications-filter-all'));
    expect(_tiles(), findsNWidgets(4));
  });

  testWidgets('search matches titles and bodies with the selected filter', (
    tester,
  ) async {
    await _pump(tester);
    await _openCenter(tester);

    expect(find.text('Search notifications'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('notifications-search')),
        matching: find.byIcon(Icons.search_rounded),
      ),
      findsOneWidget,
    );

    await _search(tester, 'VAULT CASH');
    expect(_tiles(), findsNWidgets(2));
    expect(find.byKey(Key('notification-$_vaultPending')), findsOneWidget);
    expect(find.byKey(Key('notification-$_vaultHandled')), findsOneWidget);

    await _selectFilter(tester, const Key('notifications-filter-unread'));
    expect(_tiles(), findsOneWidget);
    expect(find.byKey(Key('notification-$_vaultPending')), findsOneWidget);

    await _search(tester, 'trf-2025-0123');
    expect(_tiles(), findsOneWidget);
    expect(find.byKey(Key('notification-$_incomingPending')), findsOneWidget);

    await _search(tester, 'no such words');
    expect(find.byKey(const Key('notifications-no-results')), findsOneWidget);
    expect(find.text('No matching notifications'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notifications-search-clear')));
    await tester.pumpAndSettle();
    expect(_tiles(), findsNWidgets(3));
    expect(find.byKey(const Key('notifications-search-clear')), findsNothing);

    await _selectFilter(tester, const Key('notifications-filter-all'));
    expect(_tiles(), findsNWidgets(4));
  });

  testWidgets('a pending request opens for action after being marked read', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);
    await _openCenter(tester);

    await tester.tap(find.byKey(Key('notification-$_vaultPending')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications-page')), findsNothing);
    expect(find.byKey(const Key('approval-approve')), findsOneWidget);
    final stored = await _stored(tester);
    expect(stored.firstWhere((item) => item.id == _vaultPending).read, isTrue);
    expect(
      ledger.custodyReceipts
          .firstWhere((receipt) => receipt.id == 'DSB-2025-0441')
          .status,
      CustodyReceiptStatus.pending,
    );
  });

  testWidgets('incoming transfer and road expense open their own sheets', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);

    await _openCenter(tester);
    await tester.tap(find.byKey(Key('notification-$_incomingPending')));
    await tester.pumpAndSettle();
    expect(find.text('Khaled Ramadan (DR-003)'), findsOneWidget);
    expect(find.byKey(const Key('approval-approve')), findsOneWidget);
    await _dismissSheet(tester);
    expect(find.text('Action Required'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _openCenter(tester);
    await tester.tap(find.byKey(Key('notification-$_roadPending')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approval-confirm')), findsOneWidget);
    expect(find.text('RE-2026-1041'), findsWidgets);
    await _dismissSheet(tester);
    expect(find.text('Action Required'), findsOneWidget);

    expect(
      ledger.transfers
          .firstWhere((transfer) => transfer.id == 'TRF-2025-0123')
          .status,
      TransferStatus.pending,
    );
  });

  testWidgets('a request finalized after its notice opens History instead', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);
    ledger.approveVaultReceipt('DSB-2025-0441');
    await _openCenter(tester);

    await tester.tap(find.byKey(Key('notification-$_vaultPending')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approval-approve')), findsNothing);
    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(
      find.byKey(const Key('history-highlight-DSB-2025-0441')),
      findsOneWidget,
    );
    expect(
      find.text(
        'This request was already handled. Showing its current status.',
      ),
      findsOneWidget,
    );
    await tester.pump(historyHighlightDuration);
  });

  testWidgets('a handled request leads to its current status in History', (
    tester,
  ) async {
    await _pump(tester);
    await _openCenter(tester);

    await tester.tap(find.byKey(Key('notification-$_vaultHandled')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(
      find.byKey(const Key('history-highlight-DSB-2025-0301')),
      findsOneWidget,
    );
    expect(
      find.text(
        'This request was already handled. Showing its current status.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('approval-approve')), findsNothing);
    await tester.pump(historyHighlightDuration);
  });

  testWidgets('a record that no longer exists falls back safely', (
    tester,
  ) async {
    final missing = AppNotification(
      id: 'missing',
      driverId: _me,
      type: NotificationType.sentTransferApproved,
      entityType: NotificationEntityType.transfer,
      entityId: 'TRF-2026-9999',
      createdAt: DateTime(2026, 10, 21),
      dedupKey: 'missing',
      source: NotificationSource.event,
      amountEgp: 250,
      counterpartyName: const LocalizedString(
        en: 'Sami Hassan',
        ar: 'سامي حسن',
      ),
    );
    await tester.runAsync(() => _repository().add(missing));
    await _pump(tester);
    await _openCenter(tester);

    await tester.tap(find.byKey(const Key('notification-missing')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.text('This item is no longer available.'), findsOneWidget);
    expect(
      find.byKey(const Key('history-highlight-TRF-2026-9999')),
      findsNothing,
    );
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('a recorded expense appears live and opens its History row', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);
    await _openCenter(tester);
    expect(_tiles(), findsNWidgets(4));

    final expense = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 30, 9),
    );
    await tester.pumpAndSettle();
    expect(_tiles(), findsNWidgets(5));
    expect(find.text('Expense recorded'), findsOneWidget);
    expect(_unreadDots(), findsNWidgets(4));
    final balance = ledger.balanceOf(_me);

    await tester.tap(
      find.byKey(
        Key(
          'notification-${_key(NotificationType.expenseRecorded, expense.id, expense.createdAt)}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('history-highlight-${expense.id}')), findsOneWidget);
    expect(_highlights(), findsOneWidget);
    expect(ledger.balanceOf(_me), balance);
    expect(ledger.expenses.single.status, ExpenseStatus.recorded);
    await tester.pump(historyHighlightDuration);
    expect(_highlights(), findsNothing);
  });

  testWidgets('a far History row is scrolled into view when highlighted', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(
      tester,
      size: const Size(400, 640),
      configureLedger: (value) => ledger = value,
    );
    final early = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 50,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2024, 1, 2, 9),
    );
    for (var day = 1; day <= 8; day++) {
      ledger.createRecordedExpense(
        driverId: _me,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 10,
        notes: null,
        attachments: const [],
        createdAt: DateTime(2026, 10, day, 9),
      );
    }
    await tester.pumpAndSettle();
    await _openCenter(tester);
    await _search(tester, early.id);

    await tester.tap(
      find.byKey(
        Key(
          'notification-${_key(NotificationType.expenseRecorded, early.id, early.createdAt)}',
        ),
      ),
    );
    // Avoid pumpAndSettle: it advances wall time past the highlight timer while
    // History pages down to a far lazy ListView child.
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.byKey(Key('history-highlight-${early.id}'));
    expect(row, findsOneWidget);
    final rect = tester.getRect(row);
    expect(rect.top, greaterThanOrEqualTo(-1));
    expect(rect.bottom, lessThanOrEqualTo(641));
    await tester.pump(historyHighlightDuration);
  });

  testWidgets('a sent transfer and its outcomes open the same History row', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);
    final confirmed = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 300,
      createdAt: DateTime(2026, 10, 30, 10),
    );
    final declined = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-002',
      amountEgp: 200,
      createdAt: DateTime(2026, 10, 30, 11),
    );
    await tester.pumpAndSettle();
    await _openCenter(tester);

    expect(find.text('You sent 300 EGP to Sami Hassan'), findsOneWidget);
    expect(
      find.text('Waiting for confirmation · ${confirmed.id}'),
      findsOneWidget,
    );
    expect(find.textContaining('confirmed your transfer'), findsNothing);

    await tester.tap(
      find.byKey(
        Key(
          'notification-${_key(NotificationType.transferSent, confirmed.id, confirmed.createdAt)}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(Key('history-entry-${confirmed.id}'));
    expect(
      find.byKey(Key('history-highlight-${confirmed.id}')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: _historyLine('DR-004', 'Pending confirm'),
      ),
      findsOneWidget,
    );
    await tester.pump(historyHighlightDuration);

    // The recipient's decision has no screen in this single-driver mock, so
    // the ledger is finalized directly, as the recipient's app would do.
    ledger.approve(confirmed.id);
    ledger.reject(declined.id);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _openCenter(tester);
    expect(
      find.text('Sami Hassan confirmed your transfer of 300 EGP'),
      findsOneWidget,
    );
    expect(
      find.text('Mohamed Said rejected your transfer of 200 EGP'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        Key(
          'notification-${_key(NotificationType.sentTransferApproved, confirmed.id, confirmed.createdAt)}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('history-highlight-${confirmed.id}')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('Pending')),
      findsNothing,
    );
    await tester.pump(historyHighlightDuration);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _openCenter(tester);
    await tester.tap(
      find.byKey(
        Key(
          'notification-${_key(NotificationType.sentTransferRejected, declined.id, declined.createdAt)}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(Key('history-highlight-${declined.id}')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(Key('history-entry-${declined.id}')),
        matching: _historyLine('DR-002', 'Rejected'),
      ),
      findsOneWidget,
    );
    await tester.pump(historyHighlightDuration);
  });

  testWidgets('notification taps return to the shell, not the route below', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pumpAboveLauncher(
      tester,
      configureLedger: (value) => ledger = value,
    );
    final expense = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 120,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 30, 9),
    );
    await tester.pumpAndSettle();

    await _openCenter(tester);
    await tester.tap(
      find.byKey(
        Key(
          'notification-${_key(NotificationType.expenseRecorded, expense.id, expense.createdAt)}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('launcher'), findsNothing);
    expect(find.byKey(Key('history-highlight-${expense.id}')), findsOneWidget);
    await tester.pump(historyHighlightDuration);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _openCenter(tester);
    await tester.tap(find.byKey(Key('notification-$_vaultPending')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approval-approve')), findsOneWidget);
    await _dismissSheet(tester);
    expect(find.text('launcher'), findsNothing);
    expect(find.text('Action Required'), findsOneWidget);
  });

  testWidgets('in the app, a dismissed approval sheet leaves Approvals open', (
    tester,
  ) async {
    _setView(tester);
    await tester.pumpWidget(testPortalApp());
    await tester.pumpAndSettle();
    await _login(tester);

    await _openCenter(tester);
    await tester.tap(find.byKey(Key('notification-$_vaultPending')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approval-approve')), findsOneWidget);
    await _dismissSheet(tester);

    expect(find.text('Action Required'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsOneWidget,
    );
    expect(find.text('Page not found'), findsNothing);
    final popped = await tester
        .state<NavigatorState>(find.byType(Navigator))
        .maybePop();
    await tester.pumpAndSettle();
    expect(popped, isFalse);
    expect(find.text('Page not found'), findsNothing);
    expect(find.text('Action Required'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _openCenter(tester);
    await tester.tap(find.byKey(Key('notification-$_vaultHandled')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.text('Page not found'), findsNothing);
    await tester.pump(historyHighlightDuration);
  });

  testWidgets('screens and reloads never add notifications', (tester) async {
    await _pump(tester);
    for (final tab in ['nav-approvals', 'nav-history', 'nav-profile']) {
      await tester.tap(find.byKey(Key(tab)));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _openCenter(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openCenter(tester);

    expect(_tiles(), findsNWidgets(4));
    expect(await _stored(tester), hasLength(4));
  });

  testWidgets('a session resets the demo once; rebuilds, tabs, reopening, and '
      'hot reload do not', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
    final other = AppNotification(
      id: 'other-driver',
      driverId: 'DR-003',
      type: NotificationType.sentTransferApproved,
      entityType: NotificationEntityType.transfer,
      entityId: 'TRF-2025-0123',
      createdAt: DateTime(2026, 10, 21),
      dedupKey: 'other-driver',
      source: NotificationSource.event,
      read: true,
    );
    await tester.runAsync(() => _repository().add(other));

    MockCashLedger? captured;
    void capture(MockCashLedger value) => captured ??= value;
    await _pump(tester, configureLedger: capture, resetDemo: true);
    final ledger = captured!;
    expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);
    await _openCenter(tester);
    expect(_unreadDots(), findsNWidgets(4));
    expect(
      find.byKey(Key('notification-unread-$_vaultHandled')),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    final expense = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 30, 9),
    );
    await tester.pumpAndSettle();
    final expenseKey = _key(
      NotificationType.expenseRecorded,
      expense.id,
      expense.createdAt,
    );
    final balance = ledger.balanceOf(_me);
    final demo = [_roadPending, _vaultPending, _incomingPending, _vaultHandled];

    await _markRead(tester, [...demo, expenseKey]);
    expect(find.byKey(const Key('home-notification-dot')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await _pump(tester, configureLedger: capture, resetDemo: true);
    expect(find.byKey(const Key('home-notification-dot')), findsNothing);
    for (var reopen = 0; reopen < 2; reopen++) {
      await _openCenter(tester);
      await _selectFilter(tester, const Key('notifications-filter-unread'));
      expect(_tiles(), findsNothing);
      await _selectFilter(tester, const Key('notifications-filter-all'));
      expect(_unreadDots(), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-notification-dot')), findsNothing);

    final stored = await _stored(tester);
    expect(stored, hasLength(demo.length + 1));
    expect(stored.map((item) => item.id).toSet(), hasLength(stored.length));
    expect(stored.every((item) => item.read), isTrue);

    expect(ledger.balanceOf(_me), balance);
    expect(ledger.expenses.single.status, ExpenseStatus.recorded);
    expect(
      ledger.custodyReceipts
          .firstWhere((receipt) => receipt.id == 'DSB-2025-0441')
          .status,
      CustodyReceiptStatus.pending,
    );
    final saved = await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString('app_locale');
    });
    expect(saved, 'ar');
    final theirs = await tester.runAsync(
      () => _repository().getNotifications('DR-003'),
    );
    expect(theirs!.single.read, isTrue);
  });

  testWidgets('arabic notification center is right to left', (tester) async {
    await _pump(tester, locale: const Locale('ar'));
    await _openCenter(tester);

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('ابحث في الإشعارات'), findsOneWidget);
    expect(find.text('تحديد الكل كمقروء'), findsNothing);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('غير المقروءة'), findsOneWidget);
    expect(find.text('مقروء'), findsOneWidget);
    expect(find.text('نقدية من الخزينة بانتظار موافقتك'), findsWidgets);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('notifications-title'))),
      ),
      TextDirection.rtl,
    );
    final tile = tester.getRect(find.byKey(Key('notification-$_vaultPending')));
    final dot = tester.getRect(
      find.byKey(Key('notification-unread-$_vaultPending')),
    );
    expect(dot.center.dx, lessThan(tile.center.dx));

    await _search(tester, 'الخزينة');
    expect(_tiles(), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow screen with large text keeps the toolbar readable', (
    tester,
  ) async {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await _pump(
        tester,
        locale: locale,
        size: const Size(320, 640),
        textScale: 1.6,
      );
      await _openCenter(tester);
      expect(
        tester.getSize(find.byKey(const Key('notifications-filter-all'))).width,
        greaterThan(10),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('notifications-filter-unread')))
            .width,
        greaterThan(10),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('each debug login resets the demo set to unread, nothing else', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
    final event = AppNotification(
      id: 'my-event',
      driverId: _me,
      type: NotificationType.expenseRecorded,
      entityType: NotificationEntityType.expense,
      entityId: 'EXP-400001',
      createdAt: DateTime(2026, 10, 21),
      dedupKey: 'my-event',
      source: NotificationSource.event,
      amountEgp: 90,
      read: true,
    );
    final other = AppNotification(
      id: 'other-driver',
      driverId: 'DR-003',
      type: NotificationType.sentTransferApproved,
      entityType: NotificationEntityType.transfer,
      entityId: 'TRF-2025-0123',
      createdAt: DateTime(2026, 10, 21),
      dedupKey: 'other-driver',
      source: NotificationSource.event,
      read: true,
    );
    await tester.runAsync(() async {
      final repository = _repository();
      await repository.add(event);
      await repository.add(other);
    });
    final demo = [_roadPending, _vaultPending, _incomingPending, _vaultHandled];

    _setView(tester);
    await tester.pumpWidget(testPortalApp());
    await tester.pumpAndSettle();
    String? firstBalance;
    for (var login = 0; login < 2; login++) {
      await _login(tester);

      expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);
      final balance = _balanceText(tester);
      firstBalance ??= balance;
      expect(balance, firstBalance);
      expect(find.byKey(const Key('nav-approvals-dot')), findsOneWidget);

      await _openCenter(tester);
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('notifications-title'))),
        ),
        TextDirection.rtl,
      );
      await _selectFilter(tester, const Key('notifications-filter-unread'));
      expect(_tiles(), findsNWidgets(demo.length));
      for (final id in demo) {
        expect(
          find.byKey(Key('notification-unread-$id')),
          findsOneWidget,
          reason: id,
        );
      }
      expect(find.byKey(const Key('notification-my-event')), findsNothing);
      await _selectFilter(tester, const Key('notifications-filter-all'));
      expect(_tiles(), findsNWidgets(demo.length + 1));
      // pageBack() looks for the English "Back" tooltip; this run is Arabic.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await _markRead(tester, demo);
      expect(find.byKey(const Key('home-notification-dot')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-history')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-notification-dot')), findsNothing);

      await tester.tap(find.byKey(const Key('nav-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await tester.pumpAndSettle();
    }

    final stored = await _stored(tester);
    expect(stored, hasLength(demo.length + 1));
    expect(stored.map((item) => item.id).toSet(), hasLength(stored.length));
    expect(stored.singleWhere((item) => item.id == 'my-event').read, isTrue);
    final theirs = await tester.runAsync(
      () => _repository().getNotifications('DR-003'),
    );
    expect(theirs!.single.read, isTrue);
    final saved = await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString('app_locale');
    });
    expect(saved, 'ar');
  });

  testWidgets('no notifications shows the empty state', (tester) async {
    await _pump(tester, seedApprovals: false);
    expect(find.byKey(const Key('home-notification-dot')), findsNothing);
    await _openCenter(tester);

    expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byKey(const Key('notifications-mark-all')), findsNothing);
  });
}

NotificationRepositoryImpl _repository() => NotificationRepositoryImpl(
  SharedPreferencesNotificationDataSource(),
  seedFor: MockNotificationSeed.forDriver,
);

String _key(NotificationType type, String entityId, DateTime eventAt) {
  return notificationDedupKey(
    driverId: _me,
    type: type,
    entityId: entityId,
    eventAt: eventAt,
  );
}

Future<List<AppNotification>> _stored(WidgetTester tester) async {
  return (await tester.runAsync(() => _repository().getNotifications(_me)))!;
}

Finder _tiles() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('notification-') &&
      !(widget.key! as ValueKey<String>).value.startsWith(
        'notification-unread-',
      ) &&
      widget is InkWell,
);

Finder _unreadDots() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'notification-unread-',
      ),
);

Finder _highlights() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('history-highlight-'),
);

String _balanceText(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const Key('home-balance')));
  return text.data ?? text.textSpan!.toPlainText();
}

/// Marks [ids] read through the app's own repository, as tapping would.
Future<void> _markRead(WidgetTester tester, List<String> ids) async {
  final repository = tester
      .element(find.byKey(const Key('home-notifications')))
      .read<NotificationRepository>();
  for (final id in ids) {
    await repository.markRead(driverId: _me, id: id);
  }
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(const Key('notifications-search')), query);
  await tester.pumpAndSettle();
}

Future<void> _selectFilter(WidgetTester tester, Key optionKey) async {
  await tester.ensureVisible(find.byKey(optionKey));
  await tester.tap(find.byKey(optionKey));
  await tester.pumpAndSettle();
}

/// Taps the modal barrier above an open bottom sheet.
Future<void> _dismissSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(200, 20));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('approval-approve')), findsNothing);
  expect(find.byKey(const Key('approval-confirm')), findsNothing);
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    MockAuthDataSource.email,
  );
  await tester.enterText(
    find.byKey(const Key('login-password')),
    MockAuthDataSource.password,
  );
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pump();
  await tester.pump(MockAuthDataSource.delay);
  await tester.pumpAndSettle();
}

Future<void> _openCenter(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-notifications')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('notifications-page')), findsOneWidget);
}

void _setView(WidgetTester tester, [Size size = const Size(400, 1400)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  Widget home, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(400, 1400),
  double textScale = 1,
  bool seedApprovals = true,
  bool resetDemo = false,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  _setView(tester, size);
  await tester.pumpWidget(
    _app(
      HomeScope(
        key: ValueKey(locale),
        now: () => DateTime(2026, 10, 30, 12),
        seedApprovals: seedApprovals,
        configureLedger: configureLedger,
        resetDemoNotifications: resetDemo,
      ),
      locale: locale,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

/// The shell pushed above another route, as after sign-in.
Future<void> _pumpAboveLauncher(
  WidgetTester tester, {
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  _setView(tester);
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('launcher-open'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HomeScope(
                    now: () => DateTime(2026, 10, 30, 12),
                    configureLedger: configureLedger,
                  ),
                ),
              ),
              child: const Text('launcher'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('launcher-open')));
  await tester.pumpAndSettle();
}

/// A History row line showing [reference] and a status starting with [status].
Finder _historyLine(String reference, String status) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is HistoryReferenceLine &&
        widget.reference == reference &&
        widget.status.startsWith(status),
  );
}
