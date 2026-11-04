import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/locale/presentation/bloc/locale_bloc.dart';
import '../../../core/locale/presentation/bloc/locale_event.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

Future<void> showLanguageSheet(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).surface,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: height * 0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final selected = Localizations.localeOf(context).languageCode;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.chooseLanguage,
                style: AppTextStyles.title.copyWith(color: palette.title),
              ),
            ),
            const SizedBox(height: 16),
            _Option(
              optionKey: const Key('language-option-en'),
              label: l10n.languageEnglish,
              selected: selected == 'en',
              onTap: () => _select(context, const Locale('en')),
            ),
            const SizedBox(height: 8),
            _Option(
              optionKey: const Key('language-option-ar'),
              label: l10n.languageArabic,
              selected: selected == 'ar',
              onTap: () => _select(context, const Locale('ar')),
            ),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, Locale locale) {
    context.read<LocaleBloc>().add(LocaleSelected(locale));
    Navigator.pop(context);
  }
}

/// A language choice: a hairline-outlined 12dp box at rest; selected, it sinks
/// to the field fill with a focus outline and a check.
class _Option extends StatelessWidget {
  final Key optionKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.optionKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected ? palette.focus : palette.hairline,
        width: selected ? 1.6 : 1,
      ),
    );
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? palette.field : palette.surface,
        shape: shape,
        child: InkWell(
          key: optionKey,
          onTap: onTap,
          customBorder: shape,
          highlightColor: palette.title.withValues(alpha: 0.06),
          splashColor: palette.title.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: palette.title,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, color: palette.focus, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
