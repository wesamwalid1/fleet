import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/settlement_type.dart';

class SettlementVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const SettlementVisual(this.icon, this.color, this.background);
}

SettlementVisual settlementVisual(SettlementType type) {
  return switch (type) {
    SettlementType.roadFeesClient ||
    SettlementType.roadFeesVendors => SettlementVisual(
      Icons.local_shipping_outlined,
      AppColors.primary,
      AppColors.primary.withValues(alpha: 0.12),
    ),
    SettlementType.crossBorder => const SettlementVisual(
      Icons.public,
      AppColors.info,
      AppColors.infoBackground,
    ),
    SettlementType.fuel => const SettlementVisual(
      Icons.local_gas_station_outlined,
      AppColors.warningText,
      AppColors.warningBackground,
    ),
    SettlementType.licensing => const SettlementVisual(
      Icons.description_outlined,
      AppColors.success,
      AppColors.successBackground,
    ),
    SettlementType.permits => const SettlementVisual(
      Icons.assignment_outlined,
      AppColors.info,
      AppColors.infoBackground,
    ),
    SettlementType.transportFees => const SettlementVisual(
      Icons.inventory_2_outlined,
      AppColors.pink,
      AppColors.pinkBackground,
    ),
    SettlementType.maintenance => const SettlementVisual(
      Icons.build_outlined,
      AppColors.muted,
      AppColors.neutralBackground,
    ),
  };
}

String settlementName(AppLocalizations l10n, SettlementType type) {
  return switch (type) {
    SettlementType.roadFeesClient => l10n.settlementRoadFeesClient,
    SettlementType.roadFeesVendors => l10n.settlementRoadFeesVendors,
    SettlementType.crossBorder => l10n.settlementCrossBorder,
    SettlementType.fuel => l10n.settlementFuel,
    SettlementType.licensing => l10n.settlementLicensing,
    SettlementType.permits => l10n.settlementPermits,
    SettlementType.transportFees => l10n.settlementTransportFees,
    SettlementType.maintenance => l10n.settlementMaintenance,
  };
}

String settlementTitle(AppLocalizations l10n, SettlementType type) {
  return settlementName(l10n, type);
}
