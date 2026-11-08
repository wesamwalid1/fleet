import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/fade_through_route.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/amount_format.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../data/device_expense_attachment_picker.dart';
import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/expense_attachment.dart';
import '../../domain/entities/expense_trip_scope.dart';
import '../../domain/entities/settlement_type.dart';
import '../../domain/expense_attachment_picker.dart';
import '../../domain/failures/expense_exception.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/record_expense.dart';
import '../bloc/record_expense_bloc.dart';
import '../bloc/record_expense_event.dart';
import '../bloc/record_expense_state.dart';
import '../settlement_style.dart';
import '../widgets/attachment_thumbnail.dart';
import '../widgets/record_expense_success.dart';
import '../widgets/trip_picker_sheet.dart';

const _recordExpenseQuickAmounts = [500, 1000, 1500, 2000];

enum RecordExpenseFlowStep {
  trip,
  settlement,
  amount,
  attachments,
  review,
  success,
}

/// Opens the dedicated full-screen Record Expense flow on one [RecordExpenseBloc].
Future<void> openRecordExpenseFlow(
  BuildContext context, {
  required String driverId,
  String? tripId,
  ExpenseTripScope tripScope = ExpenseTripScope.activeTrip,
  ExpenseAttachmentPicker? picker,
}) {
  final expenses = context.read<ExpenseRepository>();
  final homeBloc = context.read<HomeBloc>();
  final connectivity = context.read<ConnectivityBloc>();

  return Navigator.of(context).push<void>(
    FadeThroughRoute<void>(
      settings: const RouteSettings(name: AppRoute.recordExpense),
      ground: (context) => AppPalette.of(context).ground,
      builder: (routeContext) {
        return BlocProvider.value(
          value: connectivity,
          child: BlocProvider.value(
            value: homeBloc,
            child: RepositoryProvider.value(
              value: expenses,
              child: BlocProvider(
                create: (_) => RecordExpenseBloc(
                  driverId: driverId,
                  recordExpense: RecordExpense(expenses),
                  repository: expenses,
                  initialTripId: tripId,
                  tripScope: tripScope,
                )..add(const RecordExpenseStarted()),
                child: RecordExpenseFlowPage(
                  tripId: tripId,
                  picker: picker ?? DeviceExpenseAttachmentPicker(),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class RecordExpenseFlowPage extends StatefulWidget {
  final String? tripId;
  final ExpenseAttachmentPicker picker;

  const RecordExpenseFlowPage({super.key, required this.picker, this.tripId});

  @override
  State<RecordExpenseFlowPage> createState() => _RecordExpenseFlowPageState();
}

class _RecordExpenseFlowPageState extends State<RecordExpenseFlowPage> {
  late RecordExpenseFlowStep _step = widget.tripId != null
      ? RecordExpenseFlowStep.settlement
      : RecordExpenseFlowStep.trip;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _tripFixed => widget.tripId != null;

  int get _totalSteps => _tripFixed ? 4 : 5;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _goTo(RecordExpenseFlowStep step) {
    setState(() => _step = step);
  }

  RecordExpenseFlowStep get _firstStep => _tripFixed
      ? RecordExpenseFlowStep.settlement
      : RecordExpenseFlowStep.trip;

  void _onBack(RecordExpenseState state) {
    if (state.submitting) return;
    switch (_step) {
      case RecordExpenseFlowStep.trip:
        Navigator.of(context).pop();
      case RecordExpenseFlowStep.settlement:
        if (_tripFixed) {
          Navigator.of(context).pop();
        } else {
          _goTo(RecordExpenseFlowStep.trip);
        }
      case RecordExpenseFlowStep.amount:
        _goTo(RecordExpenseFlowStep.settlement);
      case RecordExpenseFlowStep.attachments:
        _goTo(RecordExpenseFlowStep.amount);
      case RecordExpenseFlowStep.review:
        context.read<RecordExpenseBloc>().add(
          const RecordExpenseReviewCancelled(),
        );
        _goTo(RecordExpenseFlowStep.attachments);
      case RecordExpenseFlowStep.success:
        Navigator.of(context).pop();
    }
  }

  void _onEdit(RecordExpenseState state) {
    if (state.submitting) return;
    context.read<RecordExpenseBloc>().add(const RecordExpenseReviewCancelled());
    _goTo(_firstStep);
  }

  void _syncAmountField(RecordExpenseState state) {
    final text = state.amountEgp == 0 ? '' : '${state.amountEgp}';
    if (_amountController.text == text) return;
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncNotesField(RecordExpenseState state) {
    if (_notesController.text == state.notes) return;
    _notesController.value = TextEditingValue(
      text: state.notes,
      selection: TextSelection.collapsed(offset: state.notes.length),
    );
  }

  Future<void> _pick(_AttachmentSource source) async {
    final bloc = context.read<RecordExpenseBloc>();
    try {
      final attachment = switch (source) {
        _AttachmentSource.camera => await widget.picker.pickCamera(),
        _AttachmentSource.gallery => await widget.picker.pickGallery(),
        _AttachmentSource.file => await widget.picker.pickFile(),
      };
      if (attachment == null || !mounted) return;
      bloc.add(RecordExpenseAttachmentAdded(attachment));
    } on ExpenseAttachmentFailedException {
      if (!mounted) return;
      bloc.add(const RecordExpenseAttachmentFailed());
    } catch (_) {
      if (!mounted) return;
      bloc.add(const RecordExpenseAttachmentFailed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<RecordExpenseBloc, RecordExpenseState>(
          listenWhen: (previous, current) =>
              previous.result == null && current.result != null,
          listener: (context, state) {
            context.read<HomeBloc>().add(const HomeSummaryRefreshed());
            _goTo(RecordExpenseFlowStep.success);
          },
        ),
        BlocListener<RecordExpenseBloc, RecordExpenseState>(
          listenWhen: (previous, current) =>
              previous.stage != RecordExpenseStage.confirm &&
              current.stage == RecordExpenseStage.confirm,
          listener: (context, state) => _goTo(RecordExpenseFlowStep.review),
        ),
        BlocListener<RecordExpenseBloc, RecordExpenseState>(
          listenWhen: (previous, current) =>
              previous.amountEgp != current.amountEgp,
          listener: (context, state) => _syncAmountField(state),
        ),
        BlocListener<RecordExpenseBloc, RecordExpenseState>(
          listenWhen: (previous, current) => previous.notes != current.notes,
          listener: (context, state) => _syncNotesField(state),
        ),
      ],
      child: BlocBuilder<RecordExpenseBloc, RecordExpenseState>(
        builder: (context, state) {
          if (_step == RecordExpenseFlowStep.success) {
            final result = state.result;
            if (result == null) {
              return Scaffold(
                backgroundColor: palette.ground,
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            return PopScope(
              canPop: true,
              child: ExpenseRecordedPage(
                result: result,
                tripCode: state.selectedTrip?.code,
                onDone: () => Navigator.of(context).pop(),
              ),
            );
          }

          final canLeave = !state.submitting && _step == _firstStep;
          return PopScope(
            canPop: canLeave,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || state.submitting) return;
              _onBack(state);
            },
            child: Scaffold(
              key: const Key('expense-flow'),
              backgroundColor: palette.ground,
              appBar: AppBar(
                backgroundColor: palette.ground,
                surfaceTintColor: Colors.transparent,
                foregroundColor: palette.title,
                leading: IconButton(
                  key: const Key('expense-back'),
                  tooltip: l10n.back,
                  onPressed: state.submitting ? null : () => _onBack(state),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                title: Text(
                  _title(l10n),
                  style: AppTextStyles.appBarTitle.copyWith(
                    color: palette.title,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _StepIndicator(
                      currentIndex: _progressIndex(_step),
                      total: _totalSteps,
                      label: l10n.recordExpenseStepProgress(
                        _stepNumber(_step),
                        _totalSteps,
                      ),
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      RecordExpenseFlowStep.trip => _TripStep(
                        state: state,
                        onContinue: () =>
                            _goTo(RecordExpenseFlowStep.settlement),
                      ),
                      RecordExpenseFlowStep.settlement => _SettlementStep(
                        state: state,
                        onContinue: () => _goTo(RecordExpenseFlowStep.amount),
                      ),
                      RecordExpenseFlowStep.amount => _AmountStep(
                        state: state,
                        amountController: _amountController,
                        onContinue: () =>
                            _goTo(RecordExpenseFlowStep.attachments),
                      ),
                      RecordExpenseFlowStep.attachments => _AttachmentsStep(
                        state: state,
                        notesController: _notesController,
                        onPick: _pick,
                        onContinue: () {
                          if (_blockIfOffline(context, l10n)) return;
                          context.read<RecordExpenseBloc>().add(
                            const RecordExpenseReviewRequested(),
                          );
                        },
                      ),
                      RecordExpenseFlowStep.review => _ReviewStep(
                        state: state,
                        onEdit: () => _onEdit(state),
                      ),
                      RecordExpenseFlowStep.success => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    return switch (_step) {
      RecordExpenseFlowStep.trip => l10n.recordExpenseStepTrip,
      RecordExpenseFlowStep.settlement => l10n.recordExpenseStepSettlement,
      RecordExpenseFlowStep.amount => l10n.recordExpenseStepAmount,
      RecordExpenseFlowStep.attachments => l10n.recordExpenseStepAttachments,
      RecordExpenseFlowStep.review => l10n.recordExpenseStepReview,
      RecordExpenseFlowStep.success => l10n.expenseRecorded,
    };
  }

  int _progressIndex(RecordExpenseFlowStep step) {
    final index = switch (step) {
      RecordExpenseFlowStep.trip => 0,
      RecordExpenseFlowStep.settlement => 1,
      RecordExpenseFlowStep.amount => 2,
      RecordExpenseFlowStep.attachments => 3,
      RecordExpenseFlowStep.review => 4,
      RecordExpenseFlowStep.success => 4,
    };
    return _tripFixed ? index - 1 : index;
  }

  int _stepNumber(RecordExpenseFlowStep step) => _progressIndex(step) + 1;
}

enum _AttachmentSource { camera, gallery, file }

class _StepIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final String label;

  const _StepIndicator({
    required this.currentIndex,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final current = currentIndex.clamp(0, total - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i <= current ? palette.action : palette.hairline,
                  ),
                ),
              _StepDot(index: i, current: current),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          key: const Key('expense-step-label'),
          label,
          style: AppTextStyles.helper.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;

  const _StepDot({required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final completed = index < current;
    final active = index == current;
    final color = completed || active ? palette.action : palette.hairline;
    return Container(
      key: Key('expense-step-dot-$index'),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed || active ? color : palette.surface,
        border: Border.all(color: color, width: 2),
      ),
      child: completed
          ? Icon(Icons.check_rounded, size: 14, color: palette.onAction)
          : Text(
              '${index + 1}',
              style: AppTextStyles.helper.copyWith(
                color: active ? palette.onAction : palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _TripStep extends StatefulWidget {
  final RecordExpenseState state;
  final VoidCallback onContinue;

  const _TripStep({required this.state, required this.onContinue});

  @override
  State<_TripStep> createState() => _TripStepState();
}

class _TripStepState extends State<_TripStep> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final scope = context.read<RecordExpenseBloc>().tripScope;
    final eligible = [
      for (final trip in widget.state.trips)
        if (scope.allows(trip)) trip,
    ];
    final filtered = _filterTrips(eligible, _query);
    final showSearch = !widget.state.loading && eligible.isNotEmpty;

    return Column(
      key: const Key('expense-trip'),
      children: [
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: TextField(
              key: const Key('expense-trip-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              style: AppTextStyles.bodyMedium.copyWith(color: palette.title),
              decoration: InputDecoration(
                hintText: l10n.searchTrips,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: palette.muted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: palette.muted,
                  size: 22,
                ),
                suffixIcon: _query.trim().isEmpty
                    ? null
                    : IconButton(
                        key: const Key('expense-trip-search-clear'),
                        tooltip: l10n.clearSearch,
                        onPressed: _clearQuery,
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.muted,
                          size: 20,
                        ),
                      ),
                filled: true,
                fillColor: palette.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: palette.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: palette.focus, width: 1.6),
                ),
              ),
            ),
          ),
        Expanded(
          child: widget.state.loading
              ? const Center(child: CircularProgressIndicator())
              : eligible.isEmpty
              ? Center(
                  child: Text(
                    l10n.noTripResults,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.muted,
                    ),
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    key: const Key('expense-trip-no-search-results'),
                    l10n.noTripResults,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.muted,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trip = filtered[index];
                    final selected = trip.id == widget.state.tripId;
                    return _TripTile(
                      trip: trip,
                      selected: selected,
                      locale: locale,
                      onTap: () => context.read<RecordExpenseBloc>().add(
                        RecordExpenseTripSelected(trip.id),
                      ),
                    );
                  },
                ),
        ),
        _BottomBar(
          child: FilledButton(
            key: const Key('expense-continue'),
            onPressed: widget.state.tripId == null ? null : widget.onContinue,
            style: _primaryStyle(palette),
            child: Text(l10n.recordExpenseContinue),
          ),
        ),
      ],
    );
  }
}

List<AssignedTrip> _filterTrips(List<AssignedTrip> trips, String rawQuery) {
  final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (query.isEmpty) return trips;
  return [
    for (final trip in trips)
      if (trip.matchesQuery(query)) trip,
  ];
}

class _TripTile extends StatelessWidget {
  final AssignedTrip trip;
  final bool selected;
  final String locale;
  final VoidCallback onTap;

  const _TripTile({
    required this.trip,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final active = trip.status == TripStatus.active;

    return Material(
      color: selected
          ? palette.action.withValues(alpha: 0.08)
          : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? palette.action : palette.hairline,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        key: Key('expense-trip-${trip.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: palette.action.withValues(alpha: 0.12),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: palette.action,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.rowTitle.copyWith(
                              color: palette.title,
                            ),
                          ),
                        ),
                        Text(
                          active ? l10n.tripActive : l10n.tripCompleted,
                          style: AppTextStyles.helper.copyWith(
                            color: active ? palette.action : palette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tripRoute(trip, locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTripDate(trip.date, locale)} · ${trip.vehicle}',
                      style: AppTextStyles.helper.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, top: 2),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: palette.action,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementStep extends StatelessWidget {
  final RecordExpenseState state;
  final VoidCallback onContinue;

  const _SettlementStep({required this.state, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return Column(
      key: const Key('expense-settlement'),
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: SettlementType.values.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final type = SettlementType.values[index];
              final selected = state.settlementType == type;
              final visual = settlementVisual(type);
              return Material(
                color: selected
                    ? palette.action.withValues(alpha: 0.08)
                    : palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selected ? palette.action : palette.hairline,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: InkWell(
                  key: Key('expense-settlement-${type.name}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.read<RecordExpenseBloc>().add(
                    RecordExpenseSettlementSelected(type),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: visual.background,
                          child: Icon(
                            visual.icon,
                            color: visual.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            settlementName(l10n, type),
                            style: AppTextStyles.rowTitle.copyWith(
                              color: palette.title,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: palette.action,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _BottomBar(
          child: FilledButton(
            key: const Key('expense-continue'),
            onPressed: state.settlementType == null ? null : onContinue,
            style: _primaryStyle(palette),
            child: Text(l10n.recordExpenseContinue),
          ),
        ),
      ],
    );
  }
}

class _AmountStep extends StatelessWidget {
  final RecordExpenseState state;
  final TextEditingController amountController;
  final VoidCallback onContinue;

  const _AmountStep({
    required this.state,
    required this.amountController,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final balanceAfter = state.balanceAfterEgp;
    final canContinue =
        state.amountEgp > 0 && state.amountEgp <= state.balanceEgp;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('expense-amount'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.display.copyWith(
                    color: palette.action,
                    fontFeatures: AppTextStyles.tabular,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTextStyles.display.copyWith(
                      color: palette.action.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: palette.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    enabledBorder: _amountBorder(palette),
                    focusedBorder: _amountBorder(palette, focused: true),
                  ),
                  onChanged: (value) {
                    context.read<RecordExpenseBloc>().add(
                      RecordExpenseAmountChanged(int.tryParse(value) ?? 0),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.yourBalance(_money(state.balanceEgp, locale, l10n.egp)),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (
                      var i = 0;
                      i < _recordExpenseQuickAmounts.length;
                      i++
                    ) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _AmountChip(
                          amount: _recordExpenseQuickAmounts[i],
                        ),
                      ),
                    ],
                  ],
                ),
                if (balanceAfter != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.balanceAfterPreview(
                      _money(balanceAfter, locale, l10n.egp),
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.helper.copyWith(
                      color: balanceAfter < 0 ? palette.error : palette.muted,
                    ),
                  ),
                ],
                if (state.amountEgp > state.balanceEgp) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: l10n.insufficientBalanceError),
                ],
              ],
            ),
          ),
        ),
        _BottomBar(
          child: FilledButton(
            key: const Key('expense-continue'),
            onPressed: canContinue ? onContinue : null,
            style: _primaryStyle(palette),
            child: Text(l10n.recordExpenseContinue),
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;

  const _AmountChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final selected = context.select<RecordExpenseBloc, bool>(
      (bloc) => bloc.state.amountEgp == amount,
    );
    return OutlinedButton(
      key: Key('expense-chip-$amount'),
      onPressed: () => context.read<RecordExpenseBloc>().add(
        RecordExpenseAmountChanged(amount),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? palette.action : palette.surface,
        foregroundColor: selected ? palette.onAction : palette.title,
        side: BorderSide(
          color: selected ? palette.action : palette.fieldBorder,
        ),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: const StadiumBorder(),
      ),
      child: FittedBox(child: Text('$amount')),
    );
  }
}

class _AttachmentsStep extends StatelessWidget {
  final RecordExpenseState state;
  final TextEditingController notesController;
  final Future<void> Function(_AttachmentSource source) onPick;
  final VoidCallback onContinue;

  const _AttachmentsStep({
    required this.state,
    required this.notesController,
    required this.onPick,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.recordExpenseAttachmentsNotesHint,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel(l10n.attachmentsOptional),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AttachmentSourceButton(
                        buttonKey: const Key('expense-camera'),
                        icon: Icons.photo_camera_outlined,
                        label: l10n.camera,
                        onPressed: () => onPick(_AttachmentSource.camera),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttachmentSourceButton(
                        buttonKey: const Key('expense-gallery'),
                        icon: Icons.image_outlined,
                        label: l10n.gallery,
                        onPressed: () => onPick(_AttachmentSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AttachmentSourceButton(
                        buttonKey: const Key('expense-file'),
                        icon: Icons.attach_file,
                        label: l10n.file,
                        onPressed: () => onPick(_AttachmentSource.file),
                      ),
                    ),
                  ],
                ),
                if (state.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final attachment in state.attachments)
                        _AttachmentTile(attachment: attachment),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _FieldLabel(l10n.notesOptional),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('expense-notes'),
                  controller: notesController,
                  minLines: 2,
                  maxLines: 3,
                  onChanged: (value) => context.read<RecordExpenseBloc>().add(
                    RecordExpenseNotesChanged(value),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.title,
                  ),
                  decoration: _fieldDecoration(palette, hint: l10n.notesHint),
                ),
                if (_message(state, l10n) case final message?) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: message),
                ],
              ],
            ),
          ),
        ),
        _BottomBar(
          child: FilledButton(
            key: const Key('expense-submit'),
            onPressed: state.canReview ? onContinue : null,
            style: _primaryStyle(palette),
            child: Text(l10n.recordExpenseContinue),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final RecordExpenseState state;
  final VoidCallback onEdit;

  const _ReviewStep({required this.state, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final trip = state.selectedTrip;
    final settlement = state.settlementType;
    final after = state.balanceEgp - state.amountEgp;
    final notes = state.notes.trim();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.recordExpenseReviewHeading,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: palette.title,
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.action.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      children: [
                        Text(
                          l10n.deduction,
                          style: AppTextStyles.caption.copyWith(
                            color: palette.action,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '−${_money(state.amountEgp, locale, l10n.egp)}',
                          style: AppTextStyles.display.copyWith(
                            color: palette.action,
                            fontFeatures: AppTextStyles.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        if (trip != null)
                          _ReviewRow(
                            label: l10n.trip,
                            value: trip.code,
                            detail: tripRoute(trip, locale),
                            stacked: true,
                          ),
                        if (settlement != null)
                          _ReviewRow(
                            key: const Key('expense-review-settlement'),
                            label: l10n.settlementType,
                            value: settlementTitle(l10n, settlement),
                            stacked: true,
                          ),
                        _ReviewRow(
                          label: l10n.currentBalance,
                          value: _money(state.balanceEgp, locale, l10n.egp),
                        ),
                        _ReviewRow(
                          label: l10n.balanceAfter,
                          value: _money(after, locale, l10n.egp),
                          valueColor: palette.action,
                        ),
                        if (notes.isNotEmpty)
                          _ReviewRow(
                            label: l10n.notesOptional,
                            value: notes,
                            stacked: true,
                          ),
                        if (state.attachments.isNotEmpty) ...[
                          _ReviewRow(
                            label: l10n.attachments,
                            value: l10n.attachmentCount(
                              state.attachments.length,
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final attachment in state.attachments)
                                    _ConfirmAttachment(attachment: attachment),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_message(state, l10n) case final message?) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: message),
                ],
              ],
            ),
          ),
        ),
        _BottomBar(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('expense-edit'),
                  onPressed: state.submitting ? null : onEdit,
                  style: _outlineStyle(palette),
                  child: Text(l10n.recordExpenseEdit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('expense-confirm'),
                  onPressed: state.submitting
                      ? null
                      : () {
                          if (_blockIfOffline(context, l10n)) return;
                          context.read<RecordExpenseBloc>().add(
                            const RecordExpenseSubmitted(),
                          );
                        },
                  style: _primaryStyle(palette),
                  child: state.submitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: palette.onAction,
                          ),
                        )
                      : Text(
                          l10n.confirmDeduction,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmAttachment extends StatelessWidget {
  final ExpenseAttachment attachment;

  const _ConfirmAttachment({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      key: Key('expense-confirm-attachment-${attachment.id}'),
      width: 88,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: palette.field,
              child: SizedBox(
                width: 56,
                height: 56,
                child: attachment.kind == ExpenseAttachmentKind.file
                    ? Icon(
                        Icons.insert_drive_file_outlined,
                        color: palette.muted,
                        size: 22,
                      )
                    : attachmentThumbnail(attachment),
              ),
            ),
          ),
          if (attachment.kind == ExpenseAttachmentKind.file) ...[
            const SizedBox(height: 4),
            Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper.copyWith(color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ExpenseAttachment attachment;

  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: palette.field,
                child: attachment.kind == ExpenseAttachmentKind.file
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              color: palette.muted,
                              size: 20,
                            ),
                            Text(
                              attachment.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.helper.copyWith(
                                color: palette.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      )
                    : attachmentThumbnail(attachment),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton(
              key: Key('expense-remove-${attachment.id}'),
              tooltip: l10n.removeAttachment,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              onPressed: () => context.read<RecordExpenseBloc>().add(
                RecordExpenseAttachmentRemoved(attachment.id),
              ),
              icon: Icon(Icons.close, size: 14, color: palette.title),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentSourceButton extends StatelessWidget {
  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AttachmentSourceButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.muted,
        side: BorderSide(color: palette.fieldBorder),
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.helper.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final Color? valueColor;
  final bool stacked;

  const _ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.valueColor,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final labelStyle = AppTextStyles.bodyMedium.copyWith(color: palette.muted);
    final valueStyle = AppTextStyles.bodyLarge.copyWith(
      color: valueColor ?? palette.title,
      fontWeight: FontWeight.w700,
    );
    final detailStyle = AppTextStyles.helper.copyWith(color: palette.muted);

    if (stacked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 4),
            Text(value, softWrap: true, style: valueStyle),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(detail!, softWrap: true, style: detailStyle),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: valueStyle,
                ),
                if (detail != null)
                  Text(
                    detail!,
                    textAlign: TextAlign.end,
                    softWrap: true,
                    style: detailStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      key: const Key('expense-error'),
      decoration: BoxDecoration(
        color: palette.errorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.error.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: palette.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.helper.copyWith(color: palette.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: palette.muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

bool _blockIfOffline(BuildContext context, AppLocalizations l10n) {
  final connectivity = context.read<ConnectivityBloc>().state;
  if (!connectivity.blocksOnlineWork) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
  return true;
}

String? _message(RecordExpenseState state, AppLocalizations l10n) {
  return switch (state.error) {
    RecordExpenseError.selectTrip => l10n.selectTripError,
    RecordExpenseError.selectSettlement => l10n.selectSettlementError,
    RecordExpenseError.invalidAmount => l10n.invalidAmountError,
    RecordExpenseError.insufficientBalance => l10n.insufficientBalanceError,
    RecordExpenseError.ineligibleTrip => l10n.ineligibleTripError,
    RecordExpenseError.attachmentFailed => l10n.attachmentFailed,
    RecordExpenseError.unexpected => l10n.expenseFailed,
    null => null,
  };
}

ButtonStyle _primaryStyle(AppPalette palette) {
  return FilledButton.styleFrom(
    backgroundColor: palette.action,
    foregroundColor: palette.onAction,
    disabledBackgroundColor: palette.action.withValues(alpha: 0.35),
    disabledForegroundColor: palette.onAction.withValues(alpha: 0.7),
    minimumSize: const Size.fromHeight(52),
    textStyle: AppTextStyles.buttonLarge,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ButtonStyle _outlineStyle(AppPalette palette) {
  return OutlinedButton.styleFrom(
    foregroundColor: palette.title,
    minimumSize: const Size.fromHeight(52),
    side: BorderSide(color: palette.fieldBorder),
    textStyle: AppTextStyles.buttonLarge,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

InputDecoration _fieldDecoration(AppPalette palette, {required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
    filled: true,
    fillColor: palette.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: palette.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: palette.focus, width: 1.6),
    ),
  );
}

OutlineInputBorder _amountBorder(AppPalette palette, {bool focused = false}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
      color: focused ? palette.focus : palette.fieldBorder,
      width: focused ? 1.6 : 1.2,
    ),
  );
}

String _money(int amount, String locale, String currency) {
  return formatHomeAmount(
    amount,
    locale: locale,
    withCurrency: true,
    currency: currency,
  );
}
