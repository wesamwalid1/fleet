import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';

class BalanceCard extends StatelessWidget {
  final String balance;
  final String charge;
  final String maxLimit;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.charge,
    required this.maxLimit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      key: const Key('balance-card'),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.balance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                balance,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricPanel(value: charge, label: l10n.charge),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricPanel(value: maxLimit, label: l10n.maxLimit),
                ),
              ],
            ),
            //Divider(color: Colors.white.withValues(alpha: 0.16)),
          ],
        ),
      ),
    );
  }
}

class BalanceCardPlaceholder extends StatelessWidget {
  const BalanceCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loadingBalance,
      child: const DecoratedBox(
        key: Key('balance-loading'),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: SizedBox(height: 176, width: double.infinity),
      ),
    );
  }
}

class BalanceCardError extends StatelessWidget {
  const BalanceCardError({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const Key('balance-error'),
      children: [
        Text(
          l10n.balanceLoadError,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        TextButton(
          key: const Key('balance-retry'),
          onPressed: () =>
              context.read<HomeBloc>().add(const HomeFinanceRetried()),
          child: Text(l10n.tryAgain),
        ),
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final String value;
  final String label;

  const _MetricPanel({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
