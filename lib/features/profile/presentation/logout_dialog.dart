import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/usecases/logout_use_case.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final palette = AppPalette.of(context);
      final buttonText = Theme.of(context).textTheme.labelLarge
          ?.merge(AppTextStyles.buttonLarge);
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      );
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
                  l10n.logoutTitle,
                  style: AppTextStyles.title.copyWith(color: palette.title),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.logoutMessage,
                style: AppTextStyles.bodyLarge.copyWith(color: palette.body),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('logout-cancel'),
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.title,
                        backgroundColor: palette.surface,
                        side: BorderSide(color: palette.fieldBorder),
                        minimumSize: const Size.fromHeight(56),
                        shape: shape,
                        textStyle: buttonText,
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('logout-confirm'),
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.error,
                        foregroundColor: palette.onError,
                        minimumSize: const Size.fromHeight(56),
                        shape: shape,
                        textStyle: buttonText,
                      ),
                      child: Text(l10n.logout),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) return;
  final logout = context.read<LogoutUseCase>();
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final failedMessage = AppLocalizations.of(context).logoutFailed;
  // Clear the persisted session first so the next cold start opens Login.
  // If that cannot be confirmed, stay signed in rather than show Login while
  // a saved session may still reopen Home.
  try {
    await logout();
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(key: const Key('logout-failed'), content: Text(failedMessage)),
    );
    return;
  }
  navigator.pushNamedAndRemoveUntil(AppRoute.login, (route) => false);
}
