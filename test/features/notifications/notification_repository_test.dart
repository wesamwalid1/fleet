import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/finance_event.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:driver_portal_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:driver_portal_app/features/notifications/domain/entities/app_notification.dart';
import 'package:driver_portal_app/features/notifications/domain/notification_for_finance_event.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:driver_portal_app/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _driver = MockCashLedger.senderId;

NotificationRepositoryImpl _repository() => NotificationRepositoryImpl(
  SharedPreferencesNotificationDataSource(),
  seedFor: MockNotificationSeed.forDriver,
);

AppNotification _notification({
  String driverId = _driver,
  String entityId = 'TRF-2026-0500',
  NotificationType type = NotificationType.sentTransferApproved,
  DateTime? at,
}) {
  final eventAt = at ?? DateTime(2026, 10, 20, 12);
  final key = notificationDedupKey(
    driverId: driverId,
    type: type,
    entityId: entityId,
    eventAt: eventAt,
  );
  return AppNotification(
    id: key,
    driverId: driverId,
    type: type,
    entityType: NotificationEntityType.transfer,
    entityId: entityId,
    createdAt: eventAt,
    dedupKey: key,
    source: NotificationSource.event,
    amountEgp: 400,
    counterpartyName: const LocalizedString(
      en: 'Khaled Ramadan',
      ar: 'خالد رمضان',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the demo set is seeded once and survives reinitialization', () async {
    final first = _repository();
    final seeded = await first.getNotifications(_driver);
    expect(seeded, hasLength(4));
    expect(await first.getNotifications(_driver), hasLength(4));

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        SharedPreferencesNotificationDataSource.seededKey(_driver),
      ),
      isTrue,
    );

    for (final item in seeded) {
      await first.markRead(driverId: _driver, id: item.id);
    }
    final reopened = _repository();
    final again = await reopened.getNotifications(_driver);
    expect(again, hasLength(4));
    expect(again.every((item) => item.read), isTrue);
    expect(again.map((item) => item.source).toSet(), {NotificationSource.seed});
  });

  test('history records are not converted into notifications', () async {
    final ledger = MockCashLedger(senderBalanceEgp: 2200)
      ..seedDriverApprovals();
    final history = await HistoryRepositoryImpl(ledger).getHistory(_driver);
    final notifications = await _repository().getNotifications(_driver);

    expect(history.length, greaterThan(0));
    expect(notifications.map((item) => item.entityId).toSet(), {
      'RE-2026-1041',
      'DSB-2025-0441',
      'TRF-2025-0123',
      'DSB-2025-0301',
    });
    expect(
      notifications.where((item) => item.entityId == 'TRF-2025-0090'),
      isEmpty,
    );
  });

  test('the list is newest first and only three seeds start unread', () async {
    final items = await _repository().getNotifications(_driver);
    expect(items.first.entityId, 'RE-2026-1041');
    expect(items.last.entityId, 'DSB-2025-0301');
    expect(items.where((item) => !item.read), hasLength(3));
    expect(items.last.read, isTrue);
  });

  test('reading one notification persists and leaves the others', () async {
    final repository = _repository();
    final items = await repository.getNotifications(_driver);
    final target = items.firstWhere((item) => item.entityId == 'DSB-2025-0441');
    await repository.markRead(driverId: _driver, id: target.id);

    final reopened = await _repository().getNotifications(_driver);
    for (final item in reopened) {
      final shouldBeRead =
          item.entityId == 'DSB-2025-0441' || item.entityId == 'DSB-2025-0301';
      expect(item.read, shouldBeRead, reason: item.entityId);
    }
  });

  test('drivers never see or change each other\'s notifications', () async {
    final repository = _repository();
    await repository.add(_notification(driverId: 'DR-003'));

    final mine = await repository.getNotifications(_driver);
    final theirs = await repository.getNotifications('DR-003');
    expect(mine.where((item) => item.driverId != _driver), isEmpty);
    expect(theirs, hasLength(1));
    expect(theirs.single.driverId, 'DR-003');

    for (final item in mine) {
      await repository.markRead(driverId: _driver, id: item.id);
    }
    await repository.markRead(driverId: _driver, id: theirs.single.id);
    final theirsAfter = await _repository().getNotifications('DR-003');
    expect(theirsAfter.single.read, isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(
        SharedPreferencesNotificationDataSource.recordsKey('DR-003'),
      ),
      isNot(contains(_driver)),
    );
  });

  test('the same event key is stored once', () async {
    final repository = _repository();
    final notification = _notification();
    expect(await repository.add(notification), isTrue);
    expect(await repository.add(notification), isFalse);
    expect(await _repository().add(notification), isFalse);

    final items = await repository.getNotifications(_driver);
    expect(
      items.where((item) => item.dedupKey == notification.dedupKey),
      hasLength(1),
    );
  });

  test('a repeated finance event maps to the same key', () {
    final transfer = (MockCashLedger(
      senderBalanceEgp: 2200,
    )..seedDriverApprovals()).transfers.first;
    const ahmed = LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي');
    final first = notificationsForFinanceEvent(
      TransferApproved(transfer),
      nameOf: (_) => ahmed,
    );
    final second = notificationsForFinanceEvent(
      TransferApproved(transfer),
      nameOf: (_) => ahmed,
    );
    expect(first.single.dedupKey, second.single.dedupKey);
  });

  test('a repeated transfer event is stored once for each driver', () async {
    final transfer = MockCashLedger(senderBalanceEgp: 2200)
        .createPendingTransfer(
          senderId: _driver,
          recipientId: 'DR-004',
          amountEgp: 300,
          createdAt: DateTime(2026, 10, 20, 9),
        );
    final repository = _repository();
    for (var i = 0; i < 3; i++) {
      for (final item in notificationsForFinanceEvent(
        TransferCreated(transfer),
        nameOf: (id) => id == 'DR-004'
            ? const LocalizedString(en: 'Sami Hassan', ar: 'سامي حسن')
            : const LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي'),
      )) {
        await repository.add(item);
      }
    }

    final mine = await repository.getNotifications(_driver);
    final theirs = await repository.getNotifications('DR-004');
    expect(
      mine.where((item) => item.type == NotificationType.transferSent),
      hasLength(1),
    );
    expect(theirs, hasLength(1));
    expect(theirs.single.type, NotificationType.incomingTransferPending);
  });

  test(
    'the development reset restores the demo set and keeps the rest',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('app_locale', 'ar');
      final repository = _repository();
      final seeded = await repository.getNotifications(_driver);
      for (final item in seeded) {
        await repository.markRead(driverId: _driver, id: item.id);
      }
      final event = _notification();
      await repository.add(event);
      await repository.markRead(driverId: _driver, id: event.id);
      final other = _notification(driverId: 'DR-003');
      await repository.add(other);
      await repository.markRead(driverId: 'DR-003', id: other.id);

      final expected = [
        for (final seed in MockNotificationSeed.forDriver(_driver))
          seed.copyWith(read: false),
      ];
      for (var reset = 0; reset < 2; reset++) {
        await repository.resetSeedFixtures(_driver);

        final after = await _repository().getNotifications(_driver);
        final seeds = [
          for (final item in after)
            if (item.source == NotificationSource.seed) item,
        ];
        expect(seeds, unorderedEquals(expected));
        expect(seeds.every((item) => !item.read), isTrue);
        final kept = after.singleWhere((item) => item.id == event.id);
        expect(kept.read, isTrue);
        expect(after, hasLength(5));
        expect(after.map((item) => item.dedupKey).toSet(), hasLength(5));

        final first = seeds.first;
        await repository.markRead(driverId: _driver, id: first.id);
      }

      final theirs = await _repository().getNotifications('DR-003');
      expect(theirs.single.read, isTrue);
      expect(preferences.getString('app_locale'), 'ar');
      expect(
        preferences.getBool(
          SharedPreferencesNotificationDataSource.seededKey(_driver),
        ),
        isTrue,
      );
    },
  );

  test('the development reset tells the bloc to reload', () async {
    final repository = _repository();
    final bloc = NotificationsBloc(driverId: _driver, repository: repository)
      ..add(const NotificationsStarted());
    Future<void> until(bool Function(NotificationsState state) test) async {
      if (test(bloc.state)) return;
      await bloc.stream.firstWhere(test);
    }

    await until((state) => !state.loading);
    for (final item in bloc.state.items) {
      await repository.markRead(driverId: _driver, id: item.id);
    }
    await until((state) => state.unreadCount == 0);

    await repository.resetSeedFixtures(_driver);
    await until((state) => state.unreadCount == 4);
    expect(bloc.state.items, hasLength(4));
    expect(bloc.state.hasUnread, isTrue);

    bloc.add(const NotificationsFilterSelected(NotificationFilter.unread));
    await until((state) => state.filter == NotificationFilter.unread);
    expect(bloc.state.visible, hasLength(4));
    await bloc.close();
  });

  test(
    'search and filter selections are held without dropping items',
    () async {
      final repository = _repository();
      final bloc = NotificationsBloc(driverId: _driver, repository: repository)
        ..add(const NotificationsStarted());
      await bloc.stream.firstWhere((state) => !state.loading);

      bloc
        ..add(const NotificationsFilterSelected(NotificationFilter.unread))
        ..add(const NotificationsSearchChanged('vault'));
      await bloc.stream.firstWhere((state) => state.query == 'vault');
      expect(bloc.state.filter, NotificationFilter.unread);
      expect(bloc.state.visible, hasLength(3));
      expect(bloc.state.items, hasLength(4));

      bloc.add(const NotificationsSearchChanged(''));
      await bloc.stream.firstWhere((state) => state.query.isEmpty);
      expect(bloc.state.filter, NotificationFilter.unread);
      await bloc.close();
    },
  );

  test('the bloc updates when a notification is created', () async {
    final repository = _repository();
    final bloc = NotificationsBloc(driverId: _driver, repository: repository)
      ..add(const NotificationsStarted());
    await bloc.stream.firstWhere((state) => !state.loading);
    expect(bloc.state.unreadCount, 3);

    await repository.add(_notification());
    await bloc.stream.firstWhere((state) => state.unreadCount == 4);
    expect(bloc.state.items.first.entityId, 'TRF-2026-0500');

    await repository.add(_notification(driverId: 'DR-003'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.unreadCount, 4);
    await bloc.close();
  });

  test('loading and reloading never create notifications', () async {
    final repository = _repository();
    final bloc = NotificationsBloc(driverId: _driver, repository: repository);
    for (var i = 0; i < 3; i++) {
      bloc.add(const NotificationsStarted());
      bloc.add(const NotificationsRefreshed());
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await repository.getNotifications(_driver), hasLength(4));
    await bloc.close();
  });
}
