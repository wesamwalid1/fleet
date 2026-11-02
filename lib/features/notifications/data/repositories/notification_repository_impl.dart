import 'dart:async';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource _local;

  /// Demo records for a driver's first initialization.
  final List<AppNotification> Function(String driverId) seedFor;
  final StreamController<String> _changes = StreamController.broadcast();

  /// Read-modify-write steps run one at a time so concurrent events cannot
  /// overwrite each other.
  Future<void> _queue = Future.value();

  NotificationRepositoryImpl(this._local, {required this.seedFor});

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<List<AppNotification>> getNotifications(String driverId) {
    return _serial(() async {
      await _ensureSeeded(driverId);
      return sortNewestFirst(await _local.read(driverId));
    });
  }

  @override
  Future<bool> add(AppNotification notification) async {
    final added = await _serial(() async {
      final driverId = notification.driverId;
      await _ensureSeeded(driverId);
      final current = await _local.read(driverId);
      if (current.any((item) => item.dedupKey == notification.dedupKey)) {
        return false;
      }
      await _local.write(driverId, [...current, notification]);
      return true;
    });
    if (added) _notify(notification.driverId);
    return added;
  }

  @override
  Future<void> update(AppNotification notification) async {
    await _serial(() async {
      final driverId = notification.driverId;
      await _ensureSeeded(driverId);
      final current = await _local.read(driverId);
      final index = current.indexWhere(
        (item) => item.dedupKey == notification.dedupKey,
      );
      if (index < 0) {
        await _local.write(driverId, [
          ...current,
          notification.copyWith(read: false),
        ]);
        return;
      }
      final existing = current[index];
      final next = [...current];
      next[index] = AppNotification(
        id: existing.id,
        driverId: notification.driverId,
        type: notification.type,
        entityType: notification.entityType,
        entityId: notification.entityId,
        createdAt: existing.createdAt,
        dedupKey: existing.dedupKey,
        source: existing.source,
        read: false,
        amountEgp: notification.amountEgp,
        counterpartyName: notification.counterpartyName,
      );
      await _local.write(driverId, next);
    });
    _notify(notification.driverId);
  }

  @override
  Future<void> markRead({required String driverId, required String id}) async {
    final changed = await _serial(() async {
      final current = await _local.read(driverId);
      final index = current.indexWhere((item) => item.id == id);
      if (index < 0 || current[index].read) return false;
      final next = [...current];
      next[index] = current[index].copyWith(read: true);
      await _local.write(driverId, next);
      return true;
    });
    if (changed) _notify(driverId);
  }

  /// Development only: puts [driverId]'s demo records back to their initial
  /// content, all unread, so notification scenarios can be repeated. Records
  /// created by business events are kept as they are.
  Future<void> resetSeedFixtures(String driverId) async {
    await _serial(() async {
      final current = await _local.read(driverId);
      await _local.write(driverId, [
        for (final item in current)
          if (item.source != NotificationSource.seed) item,
        for (final seed in seedFor(driverId)) seed.copyWith(read: false),
      ]);
      await _local.markSeeded(driverId);
    });
    _notify(driverId);
  }

  void dispose() => _changes.close();

  /// Writes the demo set once per driver; the marker keeps later launches and
  /// logins from recreating it, even after the driver reads or clears it.
  Future<void> _ensureSeeded(String driverId) async {
    if (await _local.isSeeded(driverId)) return;
    final current = await _local.read(driverId);
    final keys = {for (final item in current) item.dedupKey};
    final seeds = [
      for (final seed in seedFor(driverId))
        if (!keys.contains(seed.dedupKey)) seed,
    ];
    if (seeds.isNotEmpty) await _local.write(driverId, [...current, ...seeds]);
    await _local.markSeeded(driverId);
  }

  Future<T> _serial<T>(Future<T> Function() task) {
    final run = _queue.then((_) => task());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  void _notify(String driverId) {
    if (!_changes.isClosed) _changes.add(driverId);
  }
}
