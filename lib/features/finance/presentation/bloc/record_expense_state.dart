import 'package:equatable/equatable.dart';

import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/expense_attachment.dart';
import '../../domain/entities/record_expense_result.dart';
import '../../domain/entities/settlement_type.dart';

enum RecordExpenseStage { form, confirm, recorded }

enum RecordExpenseError {
  selectTrip,
  selectSettlement,
  invalidAmount,
  insufficientBalance,
  ineligibleTrip,
  attachmentFailed,
  unexpected,
}

class RecordExpenseState extends Equatable {
  final bool loading;
  final List<AssignedTrip> trips;
  final String tripQuery;
  final String? tripId;
  final SettlementType? settlementType;
  final int amountEgp;
  final String notes;
  final List<ExpenseAttachment> attachments;
  final int balanceEgp;
  final bool submitting;
  final RecordExpenseStage stage;
  final RecordExpenseError? error;
  final RecordExpenseResult? result;

  const RecordExpenseState({
    this.loading = true,
    this.trips = const [],
    this.tripQuery = '',
    this.tripId,
    this.settlementType,
    this.amountEgp = 0,
    this.notes = '',
    this.attachments = const [],
    this.balanceEgp = 0,
    this.submitting = false,
    this.stage = RecordExpenseStage.form,
    this.error,
    this.result,
  });

  AssignedTrip? get selectedTrip {
    for (final trip in trips) {
      if (trip.id == tripId) return trip;
    }
    return null;
  }

  List<AssignedTrip> get visibleTrips {
    final query = tripQuery.trim().toLowerCase();
    if (query.isEmpty) return trips;
    return [
      for (final trip in trips)
        if (trip.code.toLowerCase().contains(query) ||
            trip.origin.toLowerCase().contains(query) ||
            trip.destination.toLowerCase().contains(query))
          trip,
    ];
  }

  int? get balanceAfterEgp {
    if (amountEgp <= 0) return null;
    return balanceEgp - amountEgp;
  }

  bool get canReview =>
      !loading &&
      !submitting &&
      result == null &&
      tripId != null &&
      settlementType != null &&
      amountEgp > 0 &&
      amountEgp <= balanceEgp;

  RecordExpenseState copyWith({
    bool? loading,
    List<AssignedTrip>? trips,
    String? tripQuery,
    String? tripId,
    SettlementType? settlementType,
    int? amountEgp,
    String? notes,
    List<ExpenseAttachment>? attachments,
    int? balanceEgp,
    bool? submitting,
    RecordExpenseStage? stage,
    RecordExpenseError? error,
    bool clearError = false,
    RecordExpenseResult? result,
  }) {
    return RecordExpenseState(
      loading: loading ?? this.loading,
      trips: trips ?? this.trips,
      tripQuery: tripQuery ?? this.tripQuery,
      tripId: tripId ?? this.tripId,
      settlementType: settlementType ?? this.settlementType,
      amountEgp: amountEgp ?? this.amountEgp,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      balanceEgp: balanceEgp ?? this.balanceEgp,
      submitting: submitting ?? this.submitting,
      stage: stage ?? this.stage,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    trips,
    tripQuery,
    tripId,
    settlementType,
    amountEgp,
    notes,
    attachments,
    balanceEgp,
    submitting,
    stage,
    error,
    result,
  ];
}
