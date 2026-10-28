import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_surfaces.dart';
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
    title: l10n.filter,
    initial: HistoryFilterDraft.fromState(bloc.state),
    defaults: HistoryFilterDraft.defaults,
    resetKey: const Key('history-filter-reset'),
    applyKey: const Key('history-filter-apply'),
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
      if (draft.filter == HistoryFilter.expenses &&
          draft.tripMode == HistoryTripMode.specific &&
          (draft.tripId == null || draft.tripId!.isEmpty)) {
        return l10n.tripRequired;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    final locale = Localizations.localeOf(context).toString();
    final showTrip = draft.filter == HistoryFilter.expenses;

    Widget section(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
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
        for (final entry in [
          (HistoryFilter.all, l10n.filterAllTransactions, 'history-filter-all'),
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
        ]) ...[
          FilterOptionTile(
            optionKey: Key(entry.$3),
            label: entry.$2,
            selected: draft.filter == entry.$1,
            onTap: () => onChanged(
              draft.copyWith(
                filter: entry.$1,
                tripMode: entry.$1 == HistoryFilter.expenses
                    ? draft.tripMode
                    : HistoryTripMode.all,
                tripId: entry.$1 == HistoryFilter.expenses
                    ? draft.tripId
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        section(l10n.filterDate),
        for (final entry in [
          (HistoryDateMode.all, l10n.dateFilterAll, 'history-date-all'),
          (HistoryDateMode.day, l10n.dateFilterDay, 'history-date-day'),
          (HistoryDateMode.range, l10n.dateFilterRange, 'history-date-range'),
        ]) ...[
          FilterOptionTile(
            optionKey: Key(entry.$3),
            label: entry.$2,
            selected: draft.dateMode == entry.$1,
            onTap: () => onChanged(
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
          const SizedBox(height: 8),
        ],
        if (draft.dateMode == HistoryDateMode.day)
          _DateField(
            fieldKey: const Key('history-date-day-value'),
            label: l10n.selectDate,
            value: draft.startDate,
            locale: locale,
            onPick: (date) =>
                onChanged(draft.copyWith(startDate: date, endDate: date)),
          ),
        if (draft.dateMode == HistoryDateMode.range) ...[
          _DateField(
            fieldKey: const Key('history-date-start'),
            label: l10n.startDate,
            value: draft.startDate,
            locale: locale,
            onPick: (date) => onChanged(draft.copyWith(startDate: date)),
          ),
          const SizedBox(height: 8),
          _DateField(
            fieldKey: const Key('history-date-end'),
            label: l10n.endDate,
            value: draft.endDate,
            locale: locale,
            onPick: (date) => onChanged(draft.copyWith(endDate: date)),
          ),
        ],
        if (showTrip) ...[
          section(l10n.filterTrip),
          FilterOptionTile(
            optionKey: const Key('history-trip-all'),
            label: l10n.tripFilterAll,
            selected: draft.tripMode == HistoryTripMode.all,
            onTap: () => onChanged(
              draft.copyWith(tripMode: HistoryTripMode.all, tripId: null),
            ),
          ),
          const SizedBox(height: 8),
          FilterOptionTile(
            optionKey: const Key('history-trip-specific'),
            label: l10n.tripFilterSpecific,
            selected: draft.tripMode == HistoryTripMode.specific,
            onTap: () =>
                onChanged(draft.copyWith(tripMode: HistoryTripMode.specific)),
          ),
          if (draft.tripMode == HistoryTripMode.specific) ...[
            const SizedBox(height: 10),
            for (final trip in trips) ...[
              FilterOptionTile(
                optionKey: Key('history-trip-${trip.id}'),
                label: '${trip.code} · ${trip.origin} → ${trip.destination}',
                selected: draft.tripId == trip.id,
                onTap: () => onChanged(draft.copyWith(tripId: trip.id)),
              ),
              const SizedBox(height: 8),
            ],
            if (trips.isEmpty)
              Text(
                l10n.selectTrip,
                style: TextStyle(color: surfaces.body, fontSize: 13.5),
              ),
          ],
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final DateTime? value;
  final String locale;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.locale,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    final text = value == null
        ? label
        : DateFormat('d MMM y', locale).format(value!);
    return OutlinedButton(
      key: fieldKey,
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
        );
        if (picked != null) onPick(picked);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: surfaces.title,
        side: BorderSide(color: surfaces.border),
        alignment: AlignmentDirectional.centerStart,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Text(text),
    );
  }
}
