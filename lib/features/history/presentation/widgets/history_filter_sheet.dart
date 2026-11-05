import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/domain/entities/assigned_trip.dart';
import '../../../finance/domain/repositories/expense_repository.dart';
import '../../domain/entities/history_entry.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import 'history_trip_picker.dart';

Future<void> showHistoryFilterSheet(BuildContext context) async {
  final bloc = context.read<HistoryBloc>();
  final expenses = context.read<ExpenseRepository>();
  final trips = await expenses.getAssignedTrips(bloc.driverId);
  if (!context.mounted) return;

  final height = MediaQuery.sizeOf(context).height;
  final applied = await showModalBottomSheet<HistoryFilterDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).surface,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.85),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HistoryFilterSheet(
      initial: HistoryFilterDraft.fromState(bloc.state),
      trips: trips,
    ),
  );
  if (applied == null || !context.mounted) return;
  bloc.add(HistoryFiltersApplied(applied));
}

String? _validate(AppLocalizations l10n, HistoryFilterDraft draft) {
  if (draft.dateMode == HistoryDateMode.day && draft.startDate == null) {
    return l10n.selectDate;
  }
  if (draft.dateMode == HistoryDateMode.range) {
    final start = draft.startDate;
    final end = draft.endDate;
    if (start == null || end == null) return l10n.selectDate;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (startDay.isAfter(endDay)) return l10n.invalidDateRange;
  }
  return null;
}

class _HistoryFilterSheet extends StatefulWidget {
  final HistoryFilterDraft initial;
  final List<AssignedTrip> trips;

  const _HistoryFilterSheet({required this.initial, required this.trips});

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late HistoryFilterDraft _draft = widget.initial;
  String? _error;

  void _change(HistoryFilterDraft draft) {
    setState(() {
      _draft = draft;
      _error = null;
    });
  }

  void _apply(AppLocalizations l10n) {
    final error = _validate(l10n, _draft);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _draft);
  }

  Future<void> _pickTrips() async {
    final picked = await showHistoryTripPicker(
      context,
      trips: widget.trips,
      selected: _draft.tripIds,
    );
    if (picked == null || !mounted) return;
    _change(_draft.copyWith(tripIds: Set<String>.unmodifiable(picked)));
  }

  void _removeTrip(String id) {
    final next = Set<String>.of(_draft.tripIds)..remove(id);
    _change(_draft.copyWith(tripIds: Set<String>.unmodifiable(next)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final buttonText = Theme.of(context).textTheme.labelLarge
        ?.merge(AppTextStyles.buttonLarge);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final draft = _draft;
    final showTrip = draft.filter == HistoryFilter.expenses;

    return Padding(
      key: const Key('filter-bottom-sheet'),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.filterTransactions,
                  style: AppTextStyles.title.copyWith(color: palette.title),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(l10n.filterTransactionType),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (filter, label, key) in [
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
                          _Choice(
                            choiceKey: Key(key),
                            label: label,
                            selected: draft.filter == filter,
                            onTap: () => _change(
                              draft.copyWith(
                                filter: filter,
                                tripIds: filter == HistoryFilter.expenses
                                    ? draft.tripIds
                                    : const {},
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (showTrip) ...[
                      _SectionLabel(l10n.filterTrip),
                      _TripField(
                        trips: widget.trips,
                        selected: draft.tripIds,
                        onTap: _pickTrips,
                        onClear: () =>
                            _change(draft.copyWith(tripIds: const <String>{})),
                      ),
                      if (draft.tripIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final trip in widget.trips)
                              if (draft.tripIds.contains(trip.id))
                                _TripTag(
                                  trip: trip,
                                  onRemove: () => _removeTrip(trip.id),
                                ),
                          ],
                        ),
                      ],
                    ],
                    _SectionLabel(l10n.filterDate),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (mode, label, key) in [
                          (
                            HistoryDateMode.all,
                            l10n.dateFilterAll,
                            'history-date-all',
                          ),
                          (
                            HistoryDateMode.day,
                            l10n.dateFilterDay,
                            'history-date-day',
                          ),
                          (
                            HistoryDateMode.range,
                            l10n.dateFilterRange,
                            'history-date-range',
                          ),
                        ])
                          _Choice(
                            choiceKey: Key(key),
                            label: label,
                            selected: draft.dateMode == mode,
                            onTap: () => _change(
                              draft.copyWith(
                                dateMode: mode,
                                startDate: mode == HistoryDateMode.all
                                    ? null
                                    : draft.startDate,
                                endDate: mode == HistoryDateMode.range
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
                        onPick: (date) => _change(
                          draft.copyWith(startDate: date, endDate: date),
                        ),
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
                        onPick: (date) =>
                            _change(draft.copyWith(startDate: date)),
                      ),
                      const SizedBox(height: 8),
                      _DateField(
                        fieldKey: const Key('history-date-end'),
                        caption: l10n.to,
                        emptyLabel: l10n.selectDate,
                        value: draft.endDate,
                        locale: locale,
                        onPick: (date) =>
                            _change(draft.copyWith(endDate: date)),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const Key('filter-sheet-error'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('history-filter-reset'),
                      onPressed: () => _change(HistoryFilterDraft.defaults),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.title,
                        backgroundColor: palette.surface,
                        side: BorderSide(color: palette.fieldBorder),
                        minimumSize: const Size.fromHeight(56),
                        shape: shape,
                        textStyle: buttonText,
                      ),
                      child: Text(
                        l10n.clearAll,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: const Key('history-filter-apply'),
                      onPressed: () => _apply(l10n),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.action,
                        foregroundColor: palette.onAction,
                        minimumSize: const Size.fromHeight(56),
                        shape: shape,
                        textStyle: buttonText,
                      ),
                      child: Text(
                        l10n.applyFilters,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppPalette.of(context).muted,
          ),
        ),
      ),
    );
  }
}

/// A single-choice pill: ink fill when selected, hairline outline at rest.
class _Choice extends StatelessWidget {
  final Key choiceKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.choiceKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? palette.action : palette.hairline),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.action : palette.surface,
        shape: shape,
        child: InkWell(
          key: choiceKey,
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: selected ? palette.onAction : palette.body,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Trip filter as one field: All trips, or how many are chosen. Opens the
/// searchable picker; the clear button returns to All trips.
class _TripField extends StatelessWidget {
  final List<AssignedTrip> trips;
  final Set<String> selected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _TripField({
    required this.trips,
    required this.selected,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: palette.fieldBorder),
    );
    final any = selected.isNotEmpty;
    return Material(
      color: palette.field,
      shape: shape,
      child: InkWell(
        key: const Key('history-trip-field'),
        onTap: onTap,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: palette.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    any
                        ? l10n.historyTripsSelected(selected.length)
                        : l10n.tripFilterAll,
                    key: any
                        ? const Key('history-trips-selected-summary')
                        : null,
                    style: AppTextStyles.input.copyWith(
                      color: palette.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (any)
                  IconButton(
                    key: const Key('history-trip-clear'),
                    tooltip: l10n.historyClearTrips,
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: palette.body),
                  ),
                Icon(chevron, color: palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripTag extends StatelessWidget {
  final AssignedTrip trip;
  final VoidCallback onRemove;

  const _TripTag({required this.trip, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: l10n.historyRemoveFilter(trip.code),
      excludeSemantics: true,
      child: Material(
        color: palette.ground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('history-trip-tag-${trip.id}'),
          onTap: onRemove,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trip.code,
                      style: AppTextStyles.label.copyWith(
                        color: palette.title,
                        fontFeatures: AppTextStyles.tabular,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded, size: 16, color: palette.body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    final palette = AppPalette.of(context);
    final value = this.value;
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: palette.fieldBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              caption!,
              style: AppTextStyles.label.copyWith(color: palette.label),
            ),
          ),
        Material(
          color: palette.field,
          shape: shape,
          child: InkWell(
            key: fieldKey,
            customBorder: shape,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: palette.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value == null
                            ? emptyLabel
                            : DateFormat('d MMM y', locale).format(value),
                        style: AppTextStyles.input.copyWith(
                          color: value == null ? palette.muted : palette.title,
                        ),
                      ),
                    ),
                    Icon(chevron, color: palette.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
