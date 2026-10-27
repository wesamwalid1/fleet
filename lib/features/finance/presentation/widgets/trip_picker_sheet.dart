import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/assigned_trip.dart';
import '../bloc/record_expense_bloc.dart';
import '../bloc/record_expense_event.dart';
import '../bloc/record_expense_state.dart';

String tripRoute(AssignedTrip trip) => '${trip.origin} → ${trip.destination}';

String formatTripDate(DateTime date, String locale) {
  return DateFormat('d MMM y', locale).format(date);
}

Future<void> showTripPicker(BuildContext context) {
  final bloc = context.read<RecordExpenseBloc>();
  bloc.add(const RecordExpenseTripQueryChanged(''));
  final height = MediaQuery.sizeOf(context).height;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return BlocProvider.value(value: bloc, child: const TripPickerSheet());
    },
  );
}

class TripPickerSheet extends StatelessWidget {
  const TripPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);

    return SizedBox(
      height: media.size.height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const _Handle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        l10n.selectTripTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.title,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('expense-trip-close'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              BlocBuilder<RecordExpenseBloc, RecordExpenseState>(
                buildWhen: (previous, current) =>
                    previous.trips.length != current.trips.length,
                builder: (context, state) {
                  return Text(
                    l10n.tripsAssigned(state.trips.length),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: TextField(
                  key: const Key('expense-trip-search'),
                  onChanged: (value) => context.read<RecordExpenseBloc>().add(
                    RecordExpenseTripQueryChanged(value),
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.searchTrips,
                    hintStyle: const TextStyle(color: AppColors.hint),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.hint,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<RecordExpenseBloc, RecordExpenseState>(
                  builder: (context, state) {
                    final trips = state.visibleTrips;
                    final scope = context.read<RecordExpenseBloc>().tripScope;
                    if (trips.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noTripResults,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      itemCount: trips.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        final selectable = scope.allows(trip);
                        return _TripCard(
                          trip: trip,
                          selectable: selectable,
                          onTap: selectable
                              ? () {
                                  context.read<RecordExpenseBloc>().add(
                                    RecordExpenseTripSelected(trip.id),
                                  );
                                  Navigator.pop(context);
                                }
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final AssignedTrip trip;
  final bool selectable;
  final VoidCallback? onTap;

  const _TripCard({
    required this.trip,
    required this.selectable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final active = trip.status == TripStatus.active;
    final titleColor = selectable ? AppColors.title : AppColors.muted;
    final detailColor = selectable ? AppColors.muted : AppColors.hint;

    return Material(
      color: selectable ? Colors.white : AppColors.neutralBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('expense-trip-${trip.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectable ? AppColors.border : AppColors.hint,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(
                icon: Icons.local_shipping_outlined,
                color: selectable ? AppColors.muted : AppColors.hint,
                background: selectable
                    ? AppColors.neutralBackground
                    : Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.code,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          active ? l10n.tripActive : l10n.tripCompleted,
                          style: TextStyle(
                            color: active ? AppColors.success : AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tripRoute(trip),
                      style: TextStyle(color: detailColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTripDate(trip.date, locale)} · ${trip.vehicle}',
                      style: const TextStyle(
                        color: AppColors.hint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, top: 2),
                child: selectable
                    ? const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.hint,
                        size: 18,
                      )
                    : Icon(
                        Icons.lock_outline,
                        key: Key('expense-trip-locked-${trip.id}'),
                        color: AppColors.muted,
                        size: 18,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
