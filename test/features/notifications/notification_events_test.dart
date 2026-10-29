import 'package:driver_portal_app/features/approvals/data/repositories/approval_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/approval_exception.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:driver_portal_app/features/notifications/data/ledger_notification_bridge.dart';
import 'package:driver_portal_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _me = MockCashLedger.senderId;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCashLedger ledger;
  late NotificationRepositoryImpl repository;
  late LedgerNotificationBridge bridge;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ledger = MockCashLedger(senderBalanceEgp: 2200)..seedDriverApprovals();
    repository = NotificationRepositoryImpl(
      SharedPreferencesNotificationDataSource(),
      seedFor: MockNotificationSeed.forDriver,
    );
    bridge = LedgerNotificationBridge(ledger, repository)..attach();
  });

  tearDown(() => bridge.detach());

  Future<List<AppNotification>> eventsFor(String driverId) async {
    await bridge.idle;
    final items = await repository.getNotifications(driverId);
    return [
      for (final item in items)
        if (item.source == NotificationSource.event) item,
    ];
  }

  test('sending cash notifies the recipient and the sender', () async {
    final transfer = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-003',
      amountEgp: 500,
      createdAt: DateTime(2026, 10, 20, 12),
    );

    final theirs = await eventsFor('DR-003');
    expect(theirs, hasLength(1));
    expect(theirs.single.type, NotificationType.incomingTransferPending);
    expect(theirs.single.entityId, transfer.id);
    expect(theirs.single.counterpartyName.en, 'Ahmed Ali');
    expect(theirs.single.counterpartyName.ar, 'أحمد علي');
    expect(theirs.single.amountEgp, 500);

    final mine = await eventsFor(_me);
    expect(mine, hasLength(1));
    expect(mine.single.type, NotificationType.transferSent);
    expect(mine.single.entityType, NotificationEntityType.transfer);
    expect(mine.single.entityId, transfer.id);
    expect(mine.single.counterpartyName.en, 'Khaled Ramadan');
    expect(mine.single.counterpartyName.ar, 'خالد رمضان');
    expect(mine.single.amountEgp, 500);
  });

  test('a sent transfer has no outcome notice until it is finalized', () async {
    final transfer = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 300,
      createdAt: DateTime(2026, 10, 20, 12),
    );
    expect((await eventsFor(_me)).map((item) => item.type), [
      NotificationType.transferSent,
    ]);
    final recipientBefore = ledger.balanceOf('DR-004');

    ledger.approve(transfer.id, finalizedAt: DateTime(2026, 10, 20, 13));
    expect(
      () => ledger.approve(transfer.id),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );
    expect(
      () => ledger.reject(transfer.id),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );

    final mine = await eventsFor(_me);
    expect(mine.map((item) => (item.type, item.entityId)).toSet(), {
      (NotificationType.transferSent, transfer.id),
      (NotificationType.sentTransferApproved, transfer.id),
    });
    expect(ledger.balanceOf('DR-004'), recipientBefore + 300);
  });

  test('a rejected transfer refunds the sender once', () async {
    final before = ledger.balanceOf(_me);
    final transfer = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 300,
      createdAt: DateTime(2026, 10, 20, 12),
    );
    expect(ledger.balanceOf(_me), before - 300);
    final recipientBefore = ledger.balanceOf('DR-004');

    ledger.reject(transfer.id);
    expect(
      () => ledger.reject(transfer.id),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );

    expect(ledger.balanceOf(_me), before);
    expect(ledger.balanceOf('DR-004'), recipientBefore);
    final rejected = (await eventsFor(_me))
        .where((item) => item.type == NotificationType.sentTransferRejected);
    expect(rejected.single.entityId, transfer.id);
  });

  test('approving an incoming transfer notifies its sender', () async {
    ledger.approve('TRF-2025-0123', finalizedAt: DateTime(2026, 10, 20, 13));

    final sender = await eventsFor('DR-003');
    expect(sender.single.type, NotificationType.sentTransferApproved);
    expect(sender.single.entityId, 'TRF-2025-0123');
    expect(sender.single.counterpartyName.en, 'Ahmed Ali');
    expect(sender.single.counterpartyName.ar, 'أحمد علي');
    expect(await eventsFor(_me), isEmpty);
  });

  test('declining an incoming transfer notifies its sender', () async {
    ledger.reject('TRF-2025-0123', finalizedAt: DateTime(2026, 10, 20, 13));

    final sender = await eventsFor('DR-003');
    expect(sender.single.type, NotificationType.sentTransferRejected);
  });

  test('my sent transfer being approved or rejected notifies me', () async {
    final approved = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-002',
      amountEgp: 100,
      createdAt: DateTime(2026, 10, 20, 9),
    );
    final rejected = ledger.createPendingTransfer(
      senderId: _me,
      recipientId: 'DR-004',
      amountEgp: 200,
      createdAt: DateTime(2026, 10, 20, 10),
    );
    ledger.approve(approved.id);
    ledger.reject(rejected.id);

    final mine = await eventsFor(_me);
    expect(mine.map((item) => (item.type, item.entityId)).toSet(), {
      (NotificationType.transferSent, approved.id),
      (NotificationType.transferSent, rejected.id),
      (NotificationType.sentTransferApproved, approved.id),
      (NotificationType.sentTransferRejected, rejected.id),
    });
  });

  test('recording an expense notifies the driver once', () async {
    final expense = ledger.createRecordedExpense(
      driverId: _me,
      tripId: 'trip-2026-0927',
      settlementType: SettlementType.fuel,
      amountEgp: 300,
      notes: null,
      attachments: const [],
      createdAt: DateTime(2026, 10, 20, 14),
    );

    final mine = await eventsFor(_me);
    expect(mine.single.type, NotificationType.expenseRecorded);
    expect(mine.single.entityId, expense.id);
    expect(mine.single.amountEgp, 300);
  });

  test('a new vault receipt asks for approval', () async {
    ledger.addPendingVaultReceipt(
      id: 'DSB-2026-0500',
      amountEgp: 1500,
      createdAt: DateTime(2026, 10, 20, 15),
    );

    final mine = await eventsFor(_me);
    expect(mine.single.type, NotificationType.vaultReceiptPending);
    expect(mine.single.entityId, 'DSB-2026-0500');
  });

  test('failed or own actions create nothing', () async {
    expect(
      () => ledger.createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-003',
        amountEgp: 999999,
        createdAt: DateTime(2026, 10, 20),
      ),
      throwsA(isA<InsufficientBalanceException>()),
    );
    ledger.approveVaultReceipt('DSB-2025-0441');
    ledger.confirmRoadExpense('RE-2026-1041');
    expect(
      () => ledger.approveVaultReceipt('DSB-2025-0441'),
      throwsA(isA<ApprovalAlreadyFinalizedException>()),
    );

    expect(await eventsFor(_me), isEmpty);
    expect(await eventsFor('DR-003'), isEmpty);
  });

  test('retrying a finished approval cannot add a second notice', () async {
    ledger.approve('TRF-2025-0123');
    expect(
      () => ledger.approve('TRF-2025-0123'),
      throwsA(isA<TransferAlreadyFinalizedException>()),
    );
    expect(await eventsFor('DR-003'), hasLength(1));
  });

  test('reading approvals and history creates nothing', () async {
    final approvals = ApprovalRepositoryImpl(ledger);
    final history = HistoryRepositoryImpl(ledger);
    for (var i = 0; i < 3; i++) {
      await approvals.getApprovals(_me);
      await history.getHistory(_me);
    }

    expect(await eventsFor(_me), isEmpty);
    expect(await repository.getNotifications(_me), hasLength(4));
  });
}
