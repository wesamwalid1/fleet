import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('notifications-page'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.title,
        titleSpacing: 4,
        title: Text(
          l10n.notifications,
          key: const Key('notifications-title'),
          style: const TextStyle(
            color: AppColors.title,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(
                  state: state,
                  controller: _search,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
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
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final NotificationsState state;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _Toolbar({
    required this.state,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<NotificationsBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('notifications-search'),
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: AppColors.title, fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.notificationsSearchHint,
              hintStyle: const TextStyle(color: AppColors.hint),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.hint,
              ),
              suffixIcon: state.query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('notifications-search-clear'),
                      tooltip: l10n.notificationsClearSearch,
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.muted,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primary, 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppFilterChip(
                key: const Key('notifications-filter-all'),
                label: l10n.filterAll,
                selected: state.filter == NotificationFilter.all,
                onSelected: () => bloc.add(
                  const NotificationsFilterSelected(NotificationFilter.all),
                ),
              ),
              AppFilterChip(
                key: const Key('notifications-filter-unread'),
                label: l10n.notificationsFilterUnread,
                selected: state.filter == NotificationFilter.unread,
                onSelected: () => bloc.add(
                  const NotificationsFilterSelected(NotificationFilter.unread),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
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
      return state.filter == NotificationFilter.unread
          ? EmptyState(
              key: const Key('notifications-empty-unread'),
              icon: Icons.mark_email_read_outlined,
              title: l10n.notificationsNoUnread,
              hint: l10n.notificationsNoUnreadHint,
            )
          : EmptyState(
              key: const Key('notifications-empty'),
              icon: Icons.notifications_none_rounded,
              title: l10n.notificationsEmpty,
              hint: l10n.notificationsEmptyHint,
            );
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
    return Semantics(
      label: unread ? l10n.notificationUnread : null,
      child: Material(
        color: unread ? Colors.white : Colors.transparent,
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
                color: unread ? AppColors.primaryBorder : AppColors.border,
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
                    color: unread ? mark.tint : AppColors.neutralBackground,
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
                          color: unread ? AppColors.title : AppColors.muted,
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
                        style: const TextStyle(
                          color: AppColors.muted,
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
                          color: unread ? AppColors.primary : AppColors.hint,
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
