import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/domain/entities/assigned_trip.dart';

/// Full-height, searchable trip choice for the History filter. Returns the
/// chosen trip ids, an empty set for All trips, or null when dismissed.
Future<Set<String>?> showHistoryTripPicker(
  BuildContext context, {
  required List<AssignedTrip> trips,
  required Set<String> selected,
}) {
  final height = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.of(context).surface,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HistoryTripPicker(trips: trips, initial: selected),
  );
}

class _HistoryTripPicker extends StatefulWidget {
  final List<AssignedTrip> trips;
  final Set<String> initial;

  const _HistoryTripPicker({required this.trips, required this.initial});

  @override
  State<_HistoryTripPicker> createState() => _HistoryTripPickerState();
}

class _HistoryTripPickerState extends State<_HistoryTripPicker> {
  late final Set<String> _selected = {...widget.initial};
  String _query = '';

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final chosen = [
      for (final trip in widget.trips)
        if (_selected.contains(trip.id)) trip,
    ];
    final matching = [
      for (final trip in widget.trips)
        if (!_selected.contains(trip.id) && trip.matchesQuery(_query)) trip,
    ];
    final buttonText = Theme.of(context).textTheme.labelLarge
        ?.merge(AppTextStyles.buttonLarge);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      key: const Key('history-trip-picker'),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.historySelectTrips,
                      style: AppTextStyles.title.copyWith(color: palette.title),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('history-trip-picker-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: palette.muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _SearchField(
              hint: l10n.searchTrips,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (chosen.isNotEmpty) ...[
                  _SectionHeader(
                    label: l10n.historyTripsSelectedSection(chosen.length),
                    action: TextButton(
                      key: const Key('history-trip-clear-selection'),
                      onPressed: () => setState(_selected.clear),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.action,
                        minimumSize: const Size(48, 48),
                        textStyle: buttonText?.copyWith(fontSize: 14),
                      ),
                      child: Text(l10n.historyClearTrips),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: chosen.length,
                    itemBuilder: (context, index) => _TripOption(
                      trip: chosen[index],
                      selected: true,
                      onTap: () => _toggle(chosen[index].id),
                    ),
                  ),
                ],
                _SectionHeader(
                  label: l10n.historyTripsListSection(matching.length),
                ),
                if (matching.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      key: const Key('history-trip-no-results'),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Text(
                        l10n.noTripResults,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: matching.length,
                    itemBuilder: (context, index) => _TripOption(
                      trip: matching[index],
                      selected: false,
                      onTap: () => _toggle(matching[index].id),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('history-trip-picker-all'),
                        onPressed: () => Navigator.pop(context, <String>{}),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.title,
                          backgroundColor: palette.surface,
                          side: BorderSide(color: palette.fieldBorder),
                          minimumSize: const Size.fromHeight(56),
                          shape: shape,
                          textStyle: buttonText,
                        ),
                        child: Text(
                          l10n.tripFilterAll,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('history-trip-done'),
                        onPressed: () =>
                            Navigator.pop(context, Set<String>.of(_selected)),
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.action,
                          foregroundColor: palette.onAction,
                          minimumSize: const Size.fromHeight(56),
                          shape: shape,
                          textStyle: buttonText,
                        ),
                        child: Text(
                          l10n.historyTripsDone(_selected.length),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      key: const Key('history-trip-search'),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: palette.focus,
      style: AppTextStyles.input.copyWith(color: palette.title),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.input.copyWith(color: palette.muted),
        prefixIcon: Icon(Icons.search_rounded, color: palette.muted, size: 20),
        filled: true,
        fillColor: palette.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: border(palette.fieldBorder),
        focusedBorder: border(palette.focus, 1.6),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? action;

  const _SectionHeader({required this.label, this.action});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          20,
          16,
          action == null ? 20 : 8,
          4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(color: palette.muted),
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// One trip with a check box: code, route, date and vehicle, and its status.
class _TripOption extends StatelessWidget {
  final AssignedTrip trip;
  final bool selected;
  final VoidCallback onTap;

  const _TripOption({
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final active = trip.status == TripStatus.active;
    return Semantics(
      checked: selected,
      child: InkWell(
        key: Key('history-trip-${trip.id}'),
        onTap: onTap,
        highlightColor: palette.title.withValues(alpha: 0.06),
        splashColor: palette.title.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: _CheckBox(selected: selected),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A trip code must never break across lines; at large
                        // text sizes it scales down instead.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            trip.code,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: palette.title,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              fontFeatures: AppTextStyles.tabular,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.route(locale),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: palette.body,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${DateFormat('d MMM y', locale).format(trip.date)}'
                          ' · ${trip.vehicle}',
                          style: AppTextStyles.helper.copyWith(
                            color: palette.muted,
                            fontFeatures: AppTextStyles.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.hairline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        active ? l10n.tripActive : l10n.tripCompleted,
                        style: AppTextStyles.helper.copyWith(
                          color: palette.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool selected;

  const _CheckBox({required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: selected ? palette.action : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? palette.action : palette.fieldBorder,
            width: 2,
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 16, color: palette.onAction)
            : null,
      ),
    );
  }
}
