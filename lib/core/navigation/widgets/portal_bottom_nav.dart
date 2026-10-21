import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/approvals/presentation/bloc/approvals_bloc.dart';
import '../../../features/approvals/presentation/bloc/approvals_state.dart';

class PortalBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const PortalBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _Item(
                itemKey: const Key('nav-home'),
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: l10n.navHome,
                selected: index == 0,
                onTap: () => onSelected(0),
              ),
              _Item(
                itemKey: const Key('nav-approvals'),
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications_rounded,
                label: l10n.approvals,
                selected: index == 1,
                showDot: true,
                onTap: () => onSelected(1),
              ),
              _Item(
                itemKey: const Key('nav-history'),
                icon: Icons.history,
                selectedIcon: Icons.history,
                label: l10n.navHistory,
                selected: index == 2,
                onTap: () => onSelected(2),
              ),
              _Item(
                itemKey: const Key('nav-profile'),
                icon: Icons.person_outline,
                selectedIcon: Icons.person_rounded,
                label: l10n.navProfile,
                selected: index == 3,
                onTap: () => onSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Key itemKey;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _Item({
    required this.itemKey,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.hint;
    return Expanded(
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: color,
                        size: 22,
                      ),
                      if (showDot)
                        BlocBuilder<ApprovalsBloc, ApprovalsState>(
                          buildWhen: (previous, current) =>
                              previous.pendingCount != current.pendingCount,
                          builder: (context, state) {
                            if (state.pendingCount == 0) {
                              return const SizedBox.shrink();
                            }
                            return const PositionedDirectional(
                              top: -2,
                              end: -3,
                              child: SizedBox(
                                width: 8,
                                height: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
