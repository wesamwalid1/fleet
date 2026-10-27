import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/settlement_type.dart';
import '../bloc/record_expense_bloc.dart';
import '../bloc/record_expense_event.dart';
import '../settlement_style.dart';

Future<void> showSettlementPicker(BuildContext context) {
  final bloc = context.read<RecordExpenseBloc>();
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
      return BlocProvider.value(
        value: bloc,
        child: const SettlementPickerSheet(),
      );
    },
  );
}

class SettlementPickerSheet extends StatelessWidget {
  const SettlementPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: height * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      l10n.settlementTypeTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.title,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('expense-settlement-close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                itemCount: SettlementType.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final type = SettlementType.values[index];
                  final visual = settlementVisual(type);
                  return Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      key: Key('expense-settlement-${type.name}'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.read<RecordExpenseBloc>().add(
                          RecordExpenseSettlementSelected(type),
                        );
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: visual.background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                visual.icon,
                                color: visual.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settlementName(l10n, type),
                                    style: const TextStyle(
                                      color: AppColors.title,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
