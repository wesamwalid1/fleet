import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:driver_portal_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/domain/entities/app_notification.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _me = MockCashLedger.senderId;

/// The Home tab must follow the shared session ledger on its own: these
/// tests change the ledger while Home stays on screen and never switch tabs.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a recorded expense updates recent rows and the balance', (
    tester,
  ) async {
    final ledger = await _pumpHome(tester);
    expect(_text(tester, 'home-balance'), '2,200 EGP');

    final expense = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 30, 11),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(_text(tester, 'home-balance'), '1,900 EGP');
    expect(find.byKey(Key('home-recent-${expense.id}')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(Key('home-recent-${expense.id}'))).top,
      lessThan(
        tester.getRect(find.byKey(const Key('home-recent-TRF-2025-0123'))).top,
      ),
    );
    expect(ledger.balanceOf(_me), 1900);
    expect(ledger.expenses.single.status, ExpenseStatus.recorded);
  });

  testWidgets('a sent transfer updates recent rows and the balance', (
    tester,
  ) async {
    final ledger = await _pumpHome(tester);

    final transfer = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 500,
      createdAt: DateTime(2026, 10, 30, 11),
    );
    await tester.pumpAndSettle();

    expect(_text(tester, 'home-balance'), '1,700 EGP');
    expect(find.byKey(Key('home-recent-${transfer.id}')), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
  });

  testWidgets('new pending approvals update Home, the count, and the badge', (
    tester,
  ) async {
    final ledger = await _pumpHome(tester);
    expect(find.text('3 pending'), findsOneWidget);
    expect(_navBadge(tester), '3');

    // Home lists two requests and ranks "just now" and "minutes ago" seeds
    // above dated ones; settling those two lets dated arrivals show.
    ledger.approveVaultReceipt('DSB-2025-0441');
    ledger.reject('TRF-2025-0123');
    await tester.pumpAndSettle();
    expect(find.text('1 pending'), findsOneWidget);
    expect(_navBadge(tester), '1');
    final balance = _text(tester, 'home-balance');

    final incoming = ledger.createPendingTransfer(
      senderId: 'DR-004',
      recipientId: _me,
      amountEgp: 250,
      createdAt: DateTime(2026, 10, 30, 11),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(find.text('2 pending'), findsOneWidget);
    expect(_navBadge(tester), '2');
    expect(find.byKey(Key('home-pending-${incoming.id}')), findsOneWidget);

    ledger.addPendingVaultReceipt(
      id: 'DSB-2026-0900',
      amountEgp: 700,
      createdAt: DateTime(2026, 10, 30, 12),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 pending'), findsOneWidget);
    expect(_navBadge(tester), '3');
    expect(find.byKey(const Key('home-pending-DSB-2026-0900')), findsOneWidget);
    expect(find.byKey(Key('home-pending-${incoming.id}')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('home-pending-DSB-2026-0900'))).top,
      lessThan(
        tester.getRect(find.byKey(Key('home-pending-${incoming.id}'))).top,
      ),
    );
    expect(_text(tester, 'home-balance'), balance);
  });

  testWidgets('approving or rejecting elsewhere updates Home once', (
    tester,
  ) async {
    final ledger = await _pumpHome(tester);
    final senderBefore = ledger.balanceOf('DR-003');

    ledger.approveVaultReceipt('DSB-2025-0441');
    await tester.pumpAndSettle();
    expect(find.text('2 pending'), findsOneWidget);
    expect(_navBadge(tester), '2');
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsNothing);
    expect(_text(tester, 'home-balance'), '4,200 EGP');
    expect(find.byKey(const Key('home-recent-DSB-2025-0441')), findsOneWidget);

    ledger.reject('TRF-2025-0123');
    await tester.pumpAndSettle();
    expect(find.text('1 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsNothing);
    expect(_text(tester, 'home-balance'), '4,200 EGP');
    expect(ledger.balanceOf('DR-003'), senderBefore + 500);

    ledger.confirmRoadExpense('RE-2026-1041');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-pending-count')), findsNothing);
    expect(find.byKey(const Key('home-all-caught-up')), findsOneWidget);
    expect(find.byKey(const Key('nav-approvals-dot')), findsNothing);
    expect(ledger.balanceOf(_me), 4200);
  });

  testWidgets('the next approval sheet shows the current balance', (
    tester,
  ) async {
    final ledger = await _pumpHome(tester);
    ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 500,
      createdAt: DateTime(2026, 10, 30, 11),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-card-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-card-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1,700 EGP'), findsOneWidget);
    expect(find.text('3,700 EGP'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsNothing);

    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();
    expect(ledger.balanceOf(_me), 3700);
  });

  testWidgets('ledger events still create one notification each', (
    tester,
  ) async {
    final ledger = await _pumpHome(tester);
    final transfer = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 300,
      createdAt: DateTime(2026, 10, 30, 11),
    );
    final expense = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 100,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 30, 12),
    );
    ledger.approveVaultReceipt('DSB-2025-0441');
    await tester.pumpAndSettle();

    final stored = (await tester.runAsync(
      () => NotificationRepositoryImpl(
        SharedPreferencesNotificationDataSource(),
        seedFor: MockNotificationSeed.forDriver,
      ).getNotifications(_me),
    ))!;
    final events = [
      for (final item in stored)
        if (item.source == NotificationSource.event) item,
    ];
    expect(events.map((item) => (item.type, item.entityId)).toSet(), {
      (NotificationType.transferSent, transfer.id),
      (NotificationType.expenseRecorded, expense.id),
    });
    expect(events, hasLength(2));
  });
}

Future<MockCashLedger> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  MockCashLedger? ledger;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScope(
        now: () => DateTime(2026, 10, 30, 12),
        configureLedger: (value) => ledger ??= value,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ledger!;
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

String _navBadge(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const Key('nav-approvals-dot')),
          matching: find.byType(Text),
        ),
      )
      .data!;
}
