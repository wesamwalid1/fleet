import 'dart:async';

import '../../finance/data/datasources/mock_cash_ledger.dart';
import '../../finance/domain/entities/finance_event.dart';
import '../domain/notification_for_finance_event.dart';
import '../domain/repositories/notification_repository.dart';

/// Turns completed ledger outcomes into stored notifications. With a real
/// backend this job moves server-side and this bridge goes away; the
/// repository then reads what the server produced.
class LedgerNotificationBridge {
  final MockCashLedger _ledger;
  final NotificationRepository _repository;
  final Set<Future<void>> _pending = {};

  LedgerNotificationBridge(this._ledger, this._repository);

  void attach() => _ledger.addListener(_onEvent);

  void detach() => _ledger.removeListener(_onEvent);

  /// Completes when every notification started so far has been stored.
  Future<void> get idle => Future.wait(List.of(_pending));

  void _onEvent(FinanceEvent event) {
    final notifications = notificationsForFinanceEvent(
      event,
      nameOf: _ledger.nameOf,
    );
    for (final notification in notifications) {
      late final Future<void> write;
      write = _repository
          .add(notification)
          .then<void>((_) {}, onError: (_) {})
          .whenComplete(() => _pending.remove(write));
      _pending.add(write);
    }
  }
}
