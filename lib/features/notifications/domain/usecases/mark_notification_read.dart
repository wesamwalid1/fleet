import '../repositories/notification_repository.dart';

class MarkNotificationRead {
  final NotificationRepository _repository;

  const MarkNotificationRead(this._repository);

  Future<void> call({required String driverId, required String id}) {
    return _repository.markRead(driverId: driverId, id: id);
  }
}
