import 'package:flutter/material.dart';

import '../../features/approvals/presentation/pages/approvals_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../theme/app_colors.dart';
import 'widgets/portal_bottom_nav.dart';

class PortalShell extends StatefulWidget {
  final DateTime Function() now;

  const PortalShell({super.key, required this.now});

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  int _index = 0;

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (_index) {
        1 => const ApprovalsPage(),
        2 => HistoryPage(now: widget.now),
        3 => ProfilePage(
          onOpenHome: () => _select(0),
          onOpenApprovals: () => _select(1),
          onOpenHistory: () => _select(2),
        ),
        _ => HomePage(
          now: widget.now,
          onOpenApprovals: () => _select(1),
          onOpenHistory: () => _select(2),
        ),
      },
      bottomNavigationBar: PortalBottomNav(index: _index, onSelected: _select),
    );
  }
}
