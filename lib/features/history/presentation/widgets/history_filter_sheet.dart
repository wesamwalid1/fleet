import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/domain/entities/assigned_trip.dart';
import '../../../finance/domain/repositories/expense_repository.dart';
import '../../domain/entities/history_entry.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';

Future<void> showHistoryFilterSheet(BuildContext context) async {
  final bloc = context.read<HistoryBloc>();
  final expenses = context.read<ExpenseRepository>();
  final l10n = AppLocalizations.of(context);
  final trips = await expenses.getAssignedTrips(bloc.driverId);
  if (!context.mounted) return;

  final applied = await showFilterBottomSheet<HistoryFilterDraft>(
    context: context,
    title: l10n.filterTransactions,
    initial: HistoryFilterDraft.fromState(bloc.state),
    defaults: HistoryFilterDraft.defaults,
    resetKey: const Key('history-filter-reset'),
    applyKey: const Key('history-filter-apply'),
    resetLabel: l10n.clearAll,
    applyLabel: l10n.applyFilters,
    validate: (draft) {
      if (draft.dateMode == HistoryDateMode.day && draft.startDate == null) {
        return l10n.selectDate;
      }
      if (draft.dateMode == HistoryDateMode.range) {
        if (draft.startDate == null || draft.endDate == null) {
          return l10n.selectDate;
        }
        final start = DateTime(
          draft.startDate!.year,
          draft.startDate!.month,
          draft.startDate!.day,
        );
        final end = DateTime(
          draft.endDate!.year,
          draft.endDate!.month,
          draft.endDate!.day,
        );
        if (start.isAfter(end)) return l10n.invalidDateRange;
      }
      return null;
    },
    bodyBuilder: (context, draft, onChanged) {
      return _HistoryFilterBody(
        draft: draft,
        onChanged: onChanged,
        trips: trips,
      );
    },
  );
  if (applied == null || !context.mounted) return;
  bloc.add(HistoryFiltersApplied(applied));
}

class _HistoryFilterBody extends StatelessWidget {
  final HistoryFilterDraft draft;
  final ValueChanged<HistoryFilterDraft> onChanged;
  final List<AssignedTrip> trips;

  const _HistoryFilterBody({
    required this.draft,
    required this.onChanged,
    required this.trips,
  });

  void _toggleTrip(String tripId) {
    final next = Set<String>.from(draft.tripIds);
    if (!next.add(tripId)) {
      next.remove(tripId);
    }
    onChanged(draft.copyWith(tripIds: Set<String>.unmodifiable(next)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    final locale = Localizations.localeOf(context).toString();
    final showTrip = draft.filter == HistoryFilter.expenses;
    final selectedTrips = draft.tripIds;

    Widget section(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 8),
        child: Text(
          title,
          style: TextStyle(
            color: surfaces.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(l10n.filterTransactionType),
        FilterChipWrap(
          children: [
            for (final entry in [
              (
                HistoryFilter.all,
                l10n.filterAllTransactions,
                'history-filter-all',
              ),
              (
                HistoryFilter.expenses,
                l10n.filterExpenses,
                'history-filter-expenses',
              ),
              (
                HistoryFilter.cashTransfers,
                l10n.filterCashTransfers,
                'history-filter-cash',
              ),
              (
                HistoryFilter.vault,
                l10n.filterVaultTransactions,
                'history-filter-vault',
              ),
            ])
              AppFilterChip(
                key: Key(entry.$3),
                label: entry.$2,
                selected: draft.filter == entry.$1,
                onSelected: () => onChanged(
                  draft.copyWith(
                    filter: entry.$1,
                    tripIds: entry.$1 == HistoryFilter.expenses
                        ? draft.tripIds
                        : const {},
                  ),
                ),
              ),
          ],
        ),
        if (showTrip) ...[
          section(l10n.filterTrip),
          FilterChipWrap(
            children: [
              AppFilterChip(
                key: const Key('history-trip-all'),
                label: l10n.tripFilterAll,
                selected: selectedTrips.isEmpty,
                onSelected: () => onChanged(draft.copyWith(tripIds: const {})),
              ),
              for (final trip in trips)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: AppFilterChip(
                    key: Key('history-trip-${trip.id}'),
                    label: '${trip.code} · ${trip.route(locale)}',
                    selected: selectedTrips.contains(trip.id),
                    multiSelect: true,
                    onSelected: () => _toggleTrip(trip.id),
                  ),
                ),
            ],
          ),
          if (selectedTrips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.historyTripsSelected(selectedTrips.length),
                key: const Key('history-trips-selected-summary'),
                style: TextStyle(color: surfaces.body, fontSize: 13.5),
              ),
            ),
          if (trips.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.selectTrip,
                style: TextStyle(color: surfaces.body, fontSize: 13.5),
              ),
            ),
        ],
        section(l10n.filterDate),
        FilterChipWrap(
          children: [
            for (final entry in [
              (HistoryDateMode.all, l10n.dateFilterAll, 'history-date-all'),
              (HistoryDateMode.day, l10n.dateFilterDay, 'history-date-day'),
              (
                HistoryDateMode.range,
                l10n.dateFilterRange,
                'history-date-range',
              ),
            ])
              AppFilterChip(
                key: Key(entry.$3),
                label: entry.$2,
                selected: draft.dateMode == entry.$1,
                onSelected: () => onChanged(
                  draft.copyWith(
                    dateMode: entry.$1,
                    startDate: entry.$1 == HistoryDateMode.all
                        ? null
                        : draft.startDate,
                    endDate: entry.$1 == HistoryDateMode.range
                        ? draft.endDate
                        : null,
                  ),
                ),
              ),
          ],
        ),
        if (draft.dateMode == HistoryDateMode.day) ...[
          const SizedBox(height: 12),
          _DateField(
            fieldKey: const Key('history-date-day-value'),
            emptyLabel: l10n.selectDate,
            value: draft.startDate,
            locale: locale,
            onPick: (date) =>
                onChanged(draft.copyWith(startDate: date, endDate: date)),
          ),
        ],
        if (draft.dateMode == HistoryDateMode.range) ...[
          const SizedBox(height: 12),
          _DateField(
            fieldKey: const Key('history-date-start'),
            caption: l10n.from,
            emptyLabel: l10n.selectDate,
            value: draft.startDate,
            locale: locale,
            onPick: (date) => onChanged(draft.copyWith(startDate: date)),
          ),
          const SizedBox(height: 8),
          _DateField(
            fieldKey: const Key('history-date-end'),
            caption: l10n.to,
            emptyLabel: l10n.selectDate,
            value: draft.endDate,
            locale: locale,
            onPick: (date) => onChanged(draft.copyWith(endDate: date)),
          ),
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final Key fieldKey;
  final String? caption;
  final String emptyLabel;
  final DateTime? value;
  final String locale;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.fieldKey,
    this.caption,
    required this.emptyLabel,
    required this.value,
    required this.locale,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final text = value == null
        ? emptyLabel
        : DateFormat('d MMM y', locale).format(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              caption!,
              style: TextStyle(
                color: surfaces.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        Material(
          color: surfaces.field,
          borderRadius: BorderRadius.circular(AppRadii.field),
          child: InkWell(
            key: fieldKey,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
              );
              if (picked != null) onPick(picked);
            },
            borderRadius: BorderRadius.circular(AppRadii.field),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: surfaces.border),
              ),
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: surfaces.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: value == null ? surfaces.muted : surfaces.title,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: surfaces.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
