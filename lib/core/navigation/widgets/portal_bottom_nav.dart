import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/approvals/presentation/bloc/approvals_bloc.dart';
import '../../../features/approvals/presentation/bloc/approvals_state.dart';

/// Floating frosted bar shared by every tab: icon-only tabs in equal slots, a
/// compact tinted backdrop behind the active icon, and a pending-count badge
/// on Approvals. Tab names live in tooltips, which also label each tab for
/// screen readers. It sits in the Scaffold's bottom slot (not extended
/// behind the body), so it never covers content.
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 6, 28, 4),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.title.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: DecoratedBox(
                    key: const Key('portal-bottom-nav'),
                    decoration: BoxDecoration(
                      color: _NavColors.glass,
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(color: _NavColors.glassEdge),
                    ),
                    child: _tabs(l10n),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(5),
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
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check_rounded,
            label: l10n.approvals,
            selected: index == 1,
            showBadge: true,
            onTap: () => onSelected(1),
          ),
          _Item(
            itemKey: const Key('nav-history'),
            icon: Icons.history_rounded,
            selectedIcon: Icons.history_rounded,
            label: l10n.navHistory,
            selected: index == 2,
            onTap: () => onSelected(2),
          ),
          _Item(
            itemKey: const Key('nav-profile'),
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle,
            label: l10n.navProfile,
            selected: index == 3,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

const _radius = 28.0;

/// Shades of existing [AppColors] tokens for the bar.
abstract final class _NavColors {
  /// Frosted white: the page behind stays visible while icons keep 11:1.
  static final glass = Colors.white.withValues(alpha: 0.72);
  static final glassEdge = Colors.white.withValues(alpha: 0.85);

  static const active = AppColors.primary;

  /// Soft backdrop behind the active icon.
  static final activeFill = AppColors.primary.withValues(alpha: 0.12);

  /// Near-black for inactive icons: 13:1 on white.
  static final inactive = Color.lerp(AppColors.title, AppColors.muted, 0.2)!;
}

class _Item extends StatelessWidget {
  final Key itemKey;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  const _Item({
    required this.itemKey,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            key: itemKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(_radius),
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: SizedBox(
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: 52,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? _NavColors.activeFill
                        : _NavColors.activeFill.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: selected
                            ? _NavColors.active
                            : _NavColors.inactive,
                        size: 23,
                      ),
                      if (showBadge) const _PendingBadge(),
                    ],
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

/// Pending-approval count from [ApprovalsBloc], drawn over the icon's top
/// end. It is positioned outside the icon's layout and ignores text scaling,
/// so showing or hiding it never moves the tab.
class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalsBloc, ApprovalsState>(
      buildWhen: (previous, current) =>
          previous.pendingCount != current.pendingCount,
      builder: (context, state) {
        final count = state.pendingCount;
        if (count == 0) return const SizedBox.shrink();
        return PositionedDirectional(
          top: -6,
          end: -9,
          child: MediaQuery.withNoTextScaling(
            child: Container(
              key: const Key('nav-approvals-dot'),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
