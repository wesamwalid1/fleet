import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_event.dart';
import '../../../../core/connectivity/presentation/bloc/connectivity_state.dart';
import '../../../../core/connectivity/presentation/widgets/offline_unavailable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state.dart';
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

  const NotificationsPage({super.key, required this.now, required this.onOpen});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _search = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surfaces = AppSurfaces.of(context);
    return Scaffold(
      key: const Key('notifications-page'),
      backgroundColor: surfaces.scaffold,
      appBar: AppBar(
        backgroundColor: surfaces.scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: surfaces.title,
        titleSpacing: 4,
        title: Text(
          l10n.notifications,
          key: const Key('notifications-title'),
          style: TextStyle(
            color: surfaces.title,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSearchField(
                            controller: _search,
                            hintText: l10n.notificationsSearchHint,
                            clearTooltip: l10n.notificationsClearSearch,
                            onChanged: _onSearchChanged,
                            onClear: _clearSearch,
                            showClear: state.query.isNotEmpty,
                            fieldKey: const Key('notifications-search'),
                            clearKey: const Key('notifications-search-clear'),
                          ),
                          const SizedBox(height: 12),
                          FilterChipWrap(
                            children: [
                              AppFilterChip(
                                key: const Key('notifications-filter-all'),
                                label: l10n.filterAll,
                                selected:
                                    state.filter == NotificationFilter.all,
                                onSelected: () =>
                                    _selectFilter(NotificationFilter.all),
                              ),
                              AppFilterChip(
                                key: const Key('notifications-filter-unread'),
                                label: l10n.notificationsFilterUnread,
                                selected:
                                    state.filter == NotificationFilter.unread,
                                onSelected: () =>
                                    _selectFilter(NotificationFilter.unread),
                              ),
                              AppFilterChip(
                                key: const Key('notifications-filter-read'),
                                label: l10n.notificationsFilterRead,
                                selected:
                                    state.filter == NotificationFilter.read,
                                onSelected: () =>
                                    _selectFilter(NotificationFilter.read),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _Body(
                        state: state,
                        now: widget.now,
                        onOpen: widget.onOpen,
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

class _Body extends StatelessWidget {
  final NotificationsState state;
  final DateTime Function() now;
  final Future<void> Function(AppNotification notification) onOpen;

  const _Body({required this.state, required this.now, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.failed && state.items.isEmpty) {
      return EmptyState(
        key: const Key('notifications-error'),
        icon: Icons.error_outline_rounded,
        title: l10n.notificationsLoadError,
      );
    }
    final filtered = state.visible;
    final visible = [
      for (final item in filtered)
        if (notificationMatches(l10n, item, locale, state.query)) item,
    ];
    if (visible.isEmpty) {
      if (filtered.isNotEmpty) {
        return EmptyState(
          key: const Key('notifications-no-results'),
          icon: Icons.search_off_rounded,
          title: l10n.notificationsNoResults,
          hint: l10n.notificationsNoResultsHint,
        );
      }
      return switch (state.filter) {
        NotificationFilter.unread => EmptyState(
          key: const Key('notifications-empty-unread'),
          icon: Icons.mark_email_read_outlined,
          title: l10n.notificationsNoUnread,
          hint: l10n.notificationsNoUnreadHint,
        ),
        NotificationFilter.read => EmptyState(
          key: const Key('notifications-empty-read'),
          icon: Icons.mark_email_unread_outlined,
          title: l10n.notificationsNoRead,
          hint: l10n.notificationsNoReadHint,
        ),
        NotificationFilter.all => EmptyState(
          key: const Key('notifications-empty'),
          icon: Icons.notifications_none_rounded,
          title: l10n.notificationsEmpty,
          hint: l10n.notificationsEmptyHint,
        ),
      };
    }
    return ListView.separated(
      key: const Key('notifications-list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _NotificationTile(
        notification: visible[index],
        now: now,
        onOpen: onOpen,
      ),
    );
  }
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
    final surfaces = AppSurfaces.of(context);
    return Semantics(
      label: unread ? l10n.notificationUnread : null,
      child: Material(
        color: unread ? surfaces.card : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('notification-${notification.id}'),
          onTap: () => onOpen(notification),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: unread ? AppColors.primaryBorder : surfaces.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: unread ? mark.tint : surfaces.neutral,
                    shape: BoxShape.circle,
                  ),
                  child: Opacity(
                    opacity: unread ? 1 : 0.6,
                    child: Image.asset(
                      mark.asset,
                      width: 22,
                      height: 22,
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
                        style: TextStyle(
                          color: unread ? surfaces.title : surfaces.muted,
                          fontSize: 14.5,
                          height: 1.3,
                          fontWeight: unread
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notificationBody(l10n, notification, locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: surfaces.muted,
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notificationWhen(
                          l10n,
                          notification.createdAt,
                          now(),
                          locale,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread ? AppColors.primary : surfaces.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      key: Key('notification-unread-${notification.id}'),
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
