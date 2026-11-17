import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_event.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/connectivity/presentation/widgets/offline_unavailable.dart';
import '../../../../core/haptics/haptics_helper.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/loading/minimum_loading_window.dart';
import '../../../../core/widgets/fleet_refresh_indicator.dart';
import '../../../../core/widgets/fleet_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../notification_text.dart';

/// Notification Center. Opening it never marks anything read; only tapping a
/// notification does.
class NotificationsPage extends StatefulWidget {
  final DateTime Function() now;

  /// Marks [AppNotification] read, then navigates to its destination.
  final Future<void> Function(AppNotification notification) onOpen;

  /// Clock for a manual pull's minimum loading window. Defaults to wall time.
  final DateTime Function()? loadingNow;

  const NotificationsPage({
    super.key,
    required this.now,
    required this.onOpen,
    this.loadingNow,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _search = TextEditingController();
  Future<void>? _pullInFlight;
  var _pulling = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<NotificationsBloc>();
    if (bloc.state.query.isNotEmpty) {
      bloc.add(const NotificationsSearchChanged(''));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<NotificationsBloc>().add(NotificationsSearchChanged(value));
  }

  void _clearSearch() {
    _search.clear();
    _onSearchChanged('');
  }

  void _selectFilter(NotificationFilter filter) {
    context.read<NotificationsBloc>().add(NotificationsFilterSelected(filter));
  }

  Future<void> _onPullToRefresh() {
    final connectivity = context.read<ConnectivityBloc>().state;
    if (connectivity.blocksOnlineWork) {
      _showOfflineActionNotice(context);
      return Future<void>.value();
    }
    return _pullInFlight ??= _performPull().whenComplete(() {
      _pullInFlight = null;
    });
  }

  Future<void> _performPull() async {
    if (mounted) setState(() => _pulling = true);
    final window = MinimumLoadingWindow(
      participants: 1,
      now: widget.loadingNow,
    );
    final done = Completer<void>();
    try {
      context.read<NotificationsBloc>().add(
        NotificationsRefreshed(done: done, window: window),
      );
      await done.future;
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Scaffold(
      key: const Key('notifications-page'),
      backgroundColor: palette.ground,
      appBar: AppBar(
        backgroundColor: palette.ground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.title,
        titleSpacing: 4,
        title: Text(
          l10n.notifications,
          key: const Key('notifications-title'),
          style: AppTextStyles.title.copyWith(color: palette.title),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
          buildWhen: (previous, current) =>
              previous.isUnavailable != current.isUnavailable,
          builder: (context, connectivity) {
            if (connectivity.isUnavailable) {
              return Center(
                child: OfflineUnavailable(
                  title: l10n.offlineUnavailableTitle,
                  hint: l10n.offlineUnavailableHint,
                  retryLabel: l10n.offlineRetry,
                  onRetry: () => context.read<ConnectivityBloc>().add(
                    const ConnectivityRetryRequested(),
                  ),
                ),
              );
            }
            return BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: _NotificationsSearchField(
                        controller: _search,
                        hintText: l10n.notificationsSearchHint,
                        clearTooltip: l10n.notificationsClearSearch,
                        onChanged: _onSearchChanged,
                        onClear: _clearSearch,
                        showClear: state.query.isNotEmpty,
                      ),
                    ),
                    _FilterRow(filter: state.filter, onSelected: _selectFilter),
                    Expanded(
                      child: _Body(
                        state: state,
                        now: widget.now,
                        pulling: _pulling,
                        onOpen: widget.onOpen,
                        onRefresh: _onPullToRefresh,
                        onRetry: () => context.read<NotificationsBloc>().add(
                          const NotificationsStarted(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _loadingScroll(Future<void> Function() onRefresh) {
  return FleetRefreshIndicator(
    onRefresh: onRefresh,
    child: const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverToBoxAdapter(
            child: FleetRowSkeleton(key: Key('notifications-loading')),
          ),
        ),
      ],
    ),
  );
}

class _Body extends StatelessWidget {
  final NotificationsState state;
  final DateTime Function() now;
  final bool pulling;
  final Future<void> Function(AppNotification notification) onOpen;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  const _Body({
    required this.state,
    required this.now,
    required this.pulling,
    required this.onOpen,
    required this.onRefresh,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (state.loading && state.items.isEmpty && !pulling) {
      return Center(
        child: CircularProgressIndicator(
          color: palette.action,
          strokeWidth: 2.2,
        ),
      );
    }
    if (state.loading && state.items.isNotEmpty) {
      // Keep the same Column > indicator slot the ready list uses, so the
      // pull indicator is not recreated when the rows become skeletons.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _loadingScroll(onRefresh)),
        ],
      );
    }
    if (state.loading && pulling) {
      return _loadingScroll(onRefresh);
    }
    if (state.failed && state.items.isEmpty) {
      return _LoadError(onRetry: onRetry);
    }
    final filtered = state.visible;
    final visible = [
      for (final item in filtered)
        if (notificationMatches(l10n, item, locale, state.query)) item,
    ];
    if (visible.isEmpty) {
      final empty = filtered.isNotEmpty
          ? _MessageState(
              key: const Key('notifications-no-results'),
              icon: Icons.search_off_rounded,
              title: l10n.notificationsNoResults,
              hint: l10n.notificationsNoResultsHint,
            )
          : switch (state.filter) {
              NotificationFilter.unread => _MessageState(
                key: const Key('notifications-empty-unread'),
                icon: Icons.mark_email_read_outlined,
                title: l10n.notificationsNoUnread,
                hint: l10n.notificationsNoUnreadHint,
              ),
              NotificationFilter.read => _MessageState(
                key: const Key('notifications-empty-read'),
                icon: Icons.mark_email_unread_outlined,
                title: l10n.notificationsNoRead,
                hint: l10n.notificationsNoReadHint,
              ),
              NotificationFilter.all => _MessageState(
                key: const Key('notifications-empty'),
                icon: Icons.notifications_none_rounded,
                title: l10n.notificationsEmpty,
                hint: l10n.notificationsEmptyHint,
              ),
            };
      return FleetRefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(hasScrollBody: false, child: empty),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.failed) _RefreshFailedBanner(onRetry: onRetry),
        Expanded(
          child: FleetRefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              key: const Key('notifications-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: visible.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, thickness: 1, color: palette.hairline),
              itemBuilder: (context, index) => _NotificationTile(
                notification: visible[index],
                now: now,
                onOpen: onOpen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Center(
      key: const Key('notifications-error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.notificationsLoadError,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: palette.body),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('notifications-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: palette.action,
                minimumSize: const Size(48, 48),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.merge(AppTextStyles.buttonLarge),
              ),
              child: Text(l10n.notificationsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshFailedBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _RefreshFailedBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.errorSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                key: const Key('notifications-refresh-failed'),
                l10n.notificationsLoadError,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.title),
              ),
            ),
            TextButton(
              key: const Key('notifications-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: palette.action,
                minimumSize: const Size(48, 48),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.merge(AppTextStyles.buttonLarge),
              ),
              child: Text(l10n.notificationsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;

  const _MessageState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: palette.muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: palette.title,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Matches Approvals/History search: AppPalette field fill, fieldBorder, focus.
class _NotificationsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _NotificationsSearchField({
    required this.controller,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

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
      key: const Key('notifications-search'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: palette.focus,
      style: AppTextStyles.input.copyWith(color: palette.title),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.input.copyWith(color: palette.muted),
        prefixIcon: Icon(Icons.search_rounded, color: palette.muted, size: 20),
        suffixIcon: showClear
            ? IconButton(
                key: const Key('notifications-search-clear'),
                tooltip: clearTooltip,
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, color: palette.body),
              )
            : null,
        filled: true,
        fillColor: palette.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: border(palette.fieldBorder),
        focusedBorder: border(palette.focus, 1.6),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final NotificationFilter filter;
  final ValueChanged<NotificationFilter> onSelected;

  const _FilterRow({required this.filter, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <(Key, String, NotificationFilter)>[
      (
        const Key('notifications-filter-all'),
        l10n.filterAll,
        NotificationFilter.all,
      ),
      (
        const Key('notifications-filter-unread'),
        l10n.notificationsFilterUnread,
        NotificationFilter.unread,
      ),
      (
        const Key('notifications-filter-read'),
        l10n.notificationsFilterRead,
        NotificationFilter.read,
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _FilterChip(
              chipKey: chips[i].$1,
              label: chips[i].$2,
              selected: filter == chips[i].$3,
              onSelected: () => onSelected(chips[i].$3),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onSelected,
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
          key: chipKey,
          onTap: onSelected,
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
                  maxLines: 1,
                  softWrap: false,
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

void _showOfflineActionNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  HapticsHelper.error();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('offline-action-notice'),
      content: Text(l10n.offlineActionRequiresInternet),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final DateTime Function() now;
  final Future<void> Function(AppNotification notification) onOpen;

  const _NotificationTile({
    required this.notification,
    required this.now,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final unread = !notification.read;
    final mark = notificationMark(notification.type);
    final palette = AppPalette.of(context);
    return Semantics(
      label: unread ? l10n.notificationUnread : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('notification-${notification.id}'),
          onTap: () => onOpen(notification),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: unread ? mark.tint : palette.field,
                    shape: BoxShape.circle,
                  ),
                  child: Opacity(
                    opacity: unread ? 1 : 0.65,
                    child: Image.asset(
                      mark.asset,
                      width: 20,
                      height: 20,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificationTitle(l10n, notification, locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: unread ? palette.title : palette.body,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notificationBody(l10n, notification, locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificationWhen(
                          l10n,
                          notification.createdAt,
                          now(),
                          locale,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.helper.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 6),
                    child: Container(
                      key: Key('notification-unread-${notification.id}'),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: palette.action,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
