import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_transfer_repository_impl.dart';
import 'package:driver_portal_app/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/failures/cash_request_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/expense_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/approve_cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/approve_cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/reject_cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/reject_cash_transfer.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/request_cash.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/send_cash.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/withdraw_cash.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/domain/entities/history_entry.dart';
import 'package:driver_portal_app/features/home/domain/entities/money_transaction.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:driver_portal_app/features/notifications/data/ledger_notification_bridge.dart';
import 'package:driver_portal_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const driverId = MockCashLedger.senderId;
  final createdAt = DateTime(2026, 11, 2, 10);

  MockCashLedger ledger([int balance = 2200]) =>
      MockCashLedger(senderBalanceEgp: balance, maxLimitEgp: 5000);

  group('Request Cash', () {
    test('valid request creates one pending CashRequest', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final result = await RequestCash(repository)(
        driverId: driverId,
        amountEgp: 500,
        createdAt: createdAt,
        note: 'fuel float',
      );

      expect(result.request.status, CashRequestStatus.pending);
      expect(result.request.type, CashRequestType.requestCash);
      expect(result.request.requestNumber, 'RC-001');
      expect(result.request.id, 'RC-001');
      expect(result.request.amountEgp, 500);
      expect(result.request.note, 'fuel float');
      expect(cashLedger.cashRequests, hasLength(1));
    });

    test(
      'submitting does not change Current Balance or create a Transaction',
      () async {
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        await RequestCash(repository)(
          driverId: driverId,
          amountEgp: 500,
          createdAt: createdAt,
        );

        expect(cashLedger.currentBalance(driverId), 2200);
        expect(cashLedger.transactions, isEmpty);
      },
    );

    test('multiple pending requests reserve capacity cumulatively', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final requestCash = RequestCash(repository);

      await requestCash(
        driverId: driverId,
        amountEgp: 1000,
        createdAt: createdAt,
      );
      await requestCash(
        driverId: driverId,
        amountEgp: 800,
        createdAt: createdAt.add(const Duration(minutes: 1)),
      );

      // Capacity = 5000 - 2200 - 1800 = 1000
      expect(cashLedger.pendingRequestCash(driverId), 1800);
      expect(cashLedger.availableRequestCapacity(driverId), 1000);
      expect(cashLedger.cashRequests.map((r) => r.requestNumber), [
        'RC-001',
        'RC-002',
      ]);
    });

    test('amount exceeding Available Request Capacity is rejected', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);

      expect(
        () => RequestCash(repository)(
          driverId: driverId,
          amountEgp: 2801,
          createdAt: createdAt,
        ),
        throwsA(isA<InsufficientRequestCapacityException>()),
      );
      expect(cashLedger.cashRequests, isEmpty);
      expect(cashLedger.currentBalance(driverId), 2200);
    });

    test(
      'approval increases balance once and creates one positive Transaction',
      () async {
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final created = await RequestCash(repository)(
          driverId: driverId,
          amountEgp: 500,
          createdAt: createdAt,
        );

        final approved = await ApproveCashRequest(repository)(
          created.request.id,
          processedAt: createdAt.add(const Duration(hours: 1)),
        );

        expect(approved.status, CashRequestStatus.approved);
        expect(approved.processedAt, isNotNull);
        expect(cashLedger.currentBalance(driverId), 2700);
        expect(cashLedger.transactions, hasLength(1));
        final txn = cashLedger.transactions.single;
        expect(txn.type, MoneyTransactionType.cashReceived);
        expect(txn.amountEgp, 500);
        expect(txn.cashRequestId, created.request.id);
        expect(cashLedger.availableRequestCapacity(driverId), 2300);
      },
    );

    test('rejection does not change balance or create a Transaction', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final created = await RequestCash(repository)(
        driverId: driverId,
        amountEgp: 500,
        createdAt: createdAt,
      );

      final rejected = await RejectCashRequest(repository)(created.request.id);

      expect(rejected.status, CashRequestStatus.rejected);
      expect(cashLedger.currentBalance(driverId), 2200);
      expect(cashLedger.transactions, isEmpty);
      expect(cashLedger.availableRequestCapacity(driverId), 2800);
    });

    test('duplicate approval or rejection is prevented', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final created = await RequestCash(repository)(
        driverId: driverId,
        amountEgp: 400,
        createdAt: createdAt,
      );
      await ApproveCashRequest(repository)(created.request.id);

      expect(
        () => ApproveCashRequest(repository)(created.request.id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(
        () => RejectCashRequest(repository)(created.request.id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(cashLedger.transactions, hasLength(1));
      expect(cashLedger.currentBalance(driverId), 2600);
    });

    test(
      'documents: approve after vault credit can exceed Max Limit',
      () async {
        // Capacity is enforced only at submit. Approval credits Current Balance
        // with no max-limit re-check (see MockCashLedger.approveCashRequest).
        // Written approve rules do not re-validate capacity — treat as an open
        // business decision before company-side approval integration.
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final created = await RequestCash(repository)(
          driverId: driverId,
          amountEgp: 2800,
          createdAt: createdAt,
        );
        expect(cashLedger.currentBalance(driverId), 2200);
        expect(cashLedger.availableRequestCapacity(driverId), 0);
        expect(cashLedger.maxLimitEgp, 5000);

        cashLedger.addPendingVaultReceipt(
          id: 'DSB-capacity-test',
          amountEgp: 500,
          createdAt: createdAt.add(const Duration(minutes: 1)),
        );
        cashLedger.approveVaultReceipt(
          'DSB-capacity-test',
          finalizedAt: createdAt.add(const Duration(minutes: 2)),
        );
        expect(cashLedger.currentBalance(driverId), 2700);
        // Capacity is now negative while the request remains pending.
        expect(cashLedger.availableRequestCapacity(driverId), -500);

        final approved = await ApproveCashRequest(repository)(
          created.request.id,
        );
        expect(approved.status, CashRequestStatus.approved);
        // Current exceeds Max Limit; approval still succeeds today.
        expect(cashLedger.currentBalance(driverId), 5500);
        expect(
          cashLedger.currentBalance(driverId),
          greaterThan(cashLedger.maxLimitEgp),
        );
        expect(cashLedger.transactions, hasLength(1));
      },
    );
  });

  group('Withdraw', () {
    test('valid request creates one pending CashRequest', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final result = await WithdrawCash(repository)(
        driverId: driverId,
        amountEgp: 300,
        createdAt: createdAt,
      );

      expect(result.request.status, CashRequestStatus.pending);
      expect(result.request.type, CashRequestType.withdraw);
      expect(result.request.requestNumber, 'WD-001');
      expect(cashLedger.cashRequests, hasLength(1));
    });

    test(
      'submitting does not change Current Balance or create a Transaction',
      () async {
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        await WithdrawCash(repository)(
          driverId: driverId,
          amountEgp: 300,
          createdAt: createdAt,
        );

        expect(cashLedger.currentBalance(driverId), 2200);
        expect(cashLedger.transactions, isEmpty);
        expect(cashLedger.availableBalance(driverId), 1900);
      },
    );

    test(
      'multiple pending Withdraw requests reserve balance cumulatively',
      () async {
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final withdraw = WithdrawCash(repository);

        await withdraw(
          driverId: driverId,
          amountEgp: 500,
          createdAt: createdAt,
        );
        await withdraw(
          driverId: driverId,
          amountEgp: 700,
          createdAt: createdAt.add(const Duration(minutes: 1)),
        );

        expect(cashLedger.reservedWithdraw(driverId), 1200);
        expect(cashLedger.availableBalance(driverId), 1000);
        expect(cashLedger.cashRequests.map((r) => r.requestNumber), [
          'WD-001',
          'WD-002',
        ]);
      },
    );

    test('amount exceeding Available Balance is rejected', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      await WithdrawCash(repository)(
        driverId: driverId,
        amountEgp: 1500,
        createdAt: createdAt,
      );

      expect(
        () => WithdrawCash(repository)(
          driverId: driverId,
          amountEgp: 701,
          createdAt: createdAt.add(const Duration(minutes: 1)),
        ),
        throwsA(isA<InsufficientWithdrawBalanceException>()),
      );
      expect(cashLedger.cashRequests, hasLength(1));
      expect(cashLedger.currentBalance(driverId), 2200);
    });

    test(
      'approval decreases balance once and creates one negative Transaction',
      () async {
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final created = await WithdrawCash(repository)(
          driverId: driverId,
          amountEgp: 400,
          createdAt: createdAt,
        );

        final approved = await ApproveCashRequest(repository)(
          created.request.id,
        );

        expect(approved.status, CashRequestStatus.approved);
        expect(cashLedger.currentBalance(driverId), 1800);
        expect(cashLedger.transactions, hasLength(1));
        final txn = cashLedger.transactions.single;
        expect(txn.type, MoneyTransactionType.expense);
        expect(txn.amountEgp, 400);
        expect(txn.cashRequestId, created.request.id);
        expect(cashLedger.availableBalance(driverId), 1800);
      },
    );

    test('rejection does not change balance or create a Transaction', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final created = await WithdrawCash(repository)(
        driverId: driverId,
        amountEgp: 400,
        createdAt: createdAt,
      );

      await RejectCashRequest(repository)(created.request.id);

      expect(cashLedger.currentBalance(driverId), 2200);
      expect(cashLedger.transactions, isEmpty);
      expect(cashLedger.availableBalance(driverId), 2200);
    });

    test('duplicate approval or rejection is prevented', () async {
      final cashLedger = ledger();
      final repository = CashRequestRepositoryImpl(cashLedger);
      final created = await WithdrawCash(repository)(
        driverId: driverId,
        amountEgp: 200,
        createdAt: createdAt,
      );
      await RejectCashRequest(repository)(created.request.id);

      expect(
        () => ApproveCashRequest(repository)(created.request.id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(
        () => RejectCashRequest(repository)(created.request.id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(cashLedger.transactions, isEmpty);
      expect(cashLedger.currentBalance(driverId), 2200);
    });
  });

  group('Existing operations with Available Balance', () {
    test('Send Cash cannot spend a pending Withdraw reservation', () async {
      final cashLedger = ledger();
      final requests = CashRequestRepositoryImpl(cashLedger);
      final transfers = CashTransferRepositoryImpl(cashLedger);
      await WithdrawCash(requests)(
        driverId: driverId,
        amountEgp: 2000,
        createdAt: createdAt,
      );

      expect(cashLedger.availableBalance(driverId), 200);
      expect(
        () => SendCash(transfers)(
          senderId: driverId,
          recipientId: 'DR-003',
          amountEgp: 201,
          createdAt: createdAt,
        ),
        throwsA(isA<InsufficientBalanceException>()),
      );
      expect(cashLedger.currentBalance(driverId), 2200);
      expect(cashLedger.transfers, isEmpty);
    });

    test(
      'Record Expense cannot spend a pending Withdraw reservation',
      () async {
        final cashLedger = ledger();
        final requests = CashRequestRepositoryImpl(cashLedger);
        final expenses = ExpenseRepositoryImpl(cashLedger);
        await WithdrawCash(requests)(
          driverId: driverId,
          amountEgp: 2000,
          createdAt: createdAt,
        );

        expect(
          () => expenses.createRecordedExpense(
            driverId: driverId,
            tripId: 'trip-2026-0881',
            settlementType: SettlementType.fuel,
            amountEgp: 201,
            notes: null,
            attachments: const [],
            createdAt: createdAt,
            tripScope: ExpenseTripScope.anyTrip,
          ),
          throwsA(isA<InsufficientExpenseBalanceException>()),
        );
        expect(cashLedger.expenses, isEmpty);
        expect(cashLedger.currentBalance(driverId), 2200);
      },
    );

    test(
      'Send Cash approval and rejection behavior remains unchanged',
      () async {
        final cashLedger = ledger();
        final transfers = CashTransferRepositoryImpl(cashLedger);
        final sent = await SendCash(transfers)(
          senderId: driverId,
          recipientId: 'DR-003',
          amountEgp: 500,
          createdAt: createdAt,
        );
        expect(cashLedger.currentBalance(driverId), 1700);

        final approved = await ApproveCashTransfer(transfers)(sent.transfer.id);
        expect(approved.status, TransferStatus.approved);
        expect(cashLedger.balanceOf('DR-003'), 1600);

        final second = await SendCash(transfers)(
          senderId: driverId,
          recipientId: 'DR-003',
          amountEgp: 200,
          createdAt: createdAt.add(const Duration(minutes: 1)),
        );
        await RejectCashTransfer(transfers)(second.transfer.id);
        expect(cashLedger.currentBalance(driverId), 1700);
      },
    );

    test('Record Expense remains immediately deducted and recorded', () async {
      final cashLedger = ledger();
      final expenses = ExpenseRepositoryImpl(cashLedger);
      final expense = await expenses.createRecordedExpense(
        driverId: driverId,
        tripId: 'trip-2026-0881',
        settlementType: SettlementType.fuel,
        amountEgp: 150,
        notes: null,
        attachments: const [],
        createdAt: createdAt,
        tripScope: ExpenseTripScope.anyTrip,
      );

      expect(expense.status, ExpenseStatus.recorded);
      expect(cashLedger.currentBalance(driverId), 2050);
    });
  });

  group('History and Notifications', () {
    test(
      'pending request appears once and status updates the same item',
      () async {
        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final history = HistoryRepositoryImpl(cashLedger);
        final created = await RequestCash(repository)(
          driverId: driverId,
          amountEgp: 500,
          createdAt: createdAt,
        );

        var entries = await history.getHistory(driverId);
        final pending = entries
            .where((e) => e.id == created.request.id)
            .toList();
        expect(pending, hasLength(1));
        expect(pending.single.kind, HistoryKind.requestCash);
        expect(pending.single.status, HistoryDisplayStatus.pendingConfirm);
        expect(pending.single.credit, isTrue);

        await ApproveCashRequest(repository)(created.request.id);
        entries = await history.getHistory(driverId);
        final approved = entries
            .where((e) => e.id == created.request.id)
            .toList();
        expect(approved, hasLength(1));
        expect(approved.single.status, HistoryDisplayStatus.approved);
      },
    );

    test(
      'notification is created once and updated unread on processing',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});

        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final notifications = NotificationRepositoryImpl(
          SharedPreferencesNotificationDataSource(),
          seedFor: MockNotificationSeed.none,
        );
        final bridge = LedgerNotificationBridge(cashLedger, notifications)
          ..attach();

        final created = await RequestCash(repository)(
          driverId: driverId,
          amountEgp: 500,
          createdAt: createdAt,
        );
        await bridge.idle;

        var items = await notifications.getNotifications(driverId);
        final submitted = items
            .where((item) => item.entityId == created.request.id)
            .toList();
        expect(submitted, hasLength(1));
        expect(submitted.single.type, NotificationType.requestCashPending);
        expect(submitted.single.read, isFalse);

        await notifications.markRead(
          driverId: driverId,
          id: submitted.single.id,
        );
        items = await notifications.getNotifications(driverId);
        expect(
          items.singleWhere((item) => item.entityId == created.request.id).read,
          isTrue,
        );

        await ApproveCashRequest(repository)(created.request.id);
        await bridge.idle;

        items = await notifications.getNotifications(driverId);
        final updated = items
            .where((item) => item.entityId == created.request.id)
            .toList();
        expect(updated, hasLength(1));
        expect(updated.single.type, NotificationType.requestCashApproved);
        expect(updated.single.read, isFalse);
        expect(updated.single.id, submitted.single.id);

        bridge.detach();
        notifications.dispose();
      },
    );

    test(
      'withdraw notification updates the same unread row on rejection',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});

        final cashLedger = ledger();
        final repository = CashRequestRepositoryImpl(cashLedger);
        final notifications = NotificationRepositoryImpl(
          SharedPreferencesNotificationDataSource(),
          seedFor: MockNotificationSeed.none,
        );
        final bridge = LedgerNotificationBridge(cashLedger, notifications)
          ..attach();

        final created = await WithdrawCash(repository)(
          driverId: driverId,
          amountEgp: 250,
          createdAt: createdAt,
        );
        await bridge.idle;
        final first = (await notifications.getNotifications(driverId))
            .singleWhere((item) => item.entityId == created.request.id);
        await notifications.markRead(driverId: driverId, id: first.id);

        await RejectCashRequest(repository)(created.request.id);
        await bridge.idle;

        final after = await notifications.getNotifications(driverId);
        final updated = after
            .where((item) => item.entityId == created.request.id)
            .toList();
        expect(updated, hasLength(1));
        expect(updated.single.type, NotificationType.withdrawRejected);
        expect(updated.single.read, isFalse);
        expect(updated.single.dedupKey, first.dedupKey);

        bridge.detach();
        notifications.dispose();
      },
    );
  });
}
