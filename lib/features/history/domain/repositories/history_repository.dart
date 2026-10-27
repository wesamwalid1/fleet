import '../entities/history_entry.dart';

abstract class HistoryRepository {
  Future<List<HistoryEntry>> getHistory(String driverId);

  /// Fires whenever the data behind [getHistory] may have changed.
  Stream<void> get changes;
}
