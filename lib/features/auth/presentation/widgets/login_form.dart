import 'package:driver_portal_app/core/theme/app_surfaces.dart';
import 'package:driver_portal_app/core/theme/app_text_styles.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

/// The ticket's body: welcome, credentials, and the sign-in action.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isLoading = state is LoginLoading;
        final failure = state is LoginFailure ? state : null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.welcomeBack,
                  style: AppTextStyles.display.copyWith(color: palette.title),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signInSubtitle,
                  style: AppTextStyles.bodyLarge.copyWith(color: palette.body),
                ),
                const SizedBox(height: 24),
                _LoginField(
                  key: const Key('login-email'),
                  label: l10n.emailHint,
                  controller: _emailController,
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  errorText: _emailErrorText(l10n, failure?.emailError),
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  key: const Key('login-password'),
                  label: l10n.passwordHint,
                  controller: _passwordController,
                  errorText: _passwordErrorText(l10n, failure?.passwordError),
                  onSubmitted: isLoading ? null : (_) => _submit(),
                ),
                if (failure?.authError case final authError?) ...[
                  const SizedBox(height: 16),
                  _AuthNotice(
                    error: authError,
                    message: _authErrorText(l10n, authError),
                  ),
                ],
                const SizedBox(height: 24),
                _SubmitButton(
                  isLoading: isLoading,
                  label: l10n.signIn,
                  loadingLabel: l10n.signingIn,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  String? _emailErrorText(AppLocalizations l10n, EmailError? error) {
    return switch (error) {
      null => null,
      EmailError.empty => l10n.emptyEmail,
      EmailError.invalidFormat => l10n.invalidEmail,
    };
  }

  String? _passwordErrorText(AppLocalizations l10n, PasswordError? error) {
    return switch (error) {
      null => null,
      PasswordError.empty => l10n.emptyPassword,
    };
  }

  String _authErrorText(AppLocalizations l10n, AuthError error) {
    return switch (error) {
      AuthError.invalidCredentials => l10n.invalidCredentials,
      AuthError.unexpected => l10n.unexpectedError,
      AuthError.offline => l10n.loginRequiresInternet,
    };
  }
}

/// A labelled field; the label above is merged into the field's semantics.
class _LoginField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _LoginField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.errorText,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: palette.label),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onSubmitted: onSubmitted,
            cursorColor: palette.focus,
            style: AppTextStyles.input.copyWith(color: palette.title),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: palette.muted),
              suffixIcon: suffix,
              filled: true,
              fillColor: palette.field,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: _border(palette.fieldBorder),
              focusedBorder: _border(palette.focus, 1.6),
              errorBorder: _border(palette.error),
              focusedErrorBorder: _border(palette.error, 1.6),
              errorText: errorText,
              errorMaxLines: 2,
              errorStyle: AppTextStyles.helper.copyWith(color: palette.error),
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Keeps the show/hide state local so toggling rebuilds only this field.
class _PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.onSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return _LoginField(
      label: widget.label,
      controller: widget.controller,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      errorText: widget.errorText,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: palette.muted,
        ),
      ),
    );
  }
}

/// Credential, offline, and unexpected failures, announced when they appear.
class _AuthNotice extends StatelessWidget {
  final AuthError error;
  final String message;

  const _AuthNotice({required this.error, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final offline = error == AuthError.offline;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.errorSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 20,
                color: palette.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  key: offline ? const Key('login-offline-notice') : null,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final String loadingLabel;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      height: 56,
      child: FilledButton(
        key: const Key('login-submit'),
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.action,
          foregroundColor: palette.onAction,
          disabledBackgroundColor: palette.action,
          disabledForegroundColor: palette.onAction,
          textStyle: Theme.of(context).textTheme.labelLarge
              ?.merge(AppTextStyles.buttonLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? SizedBox.square(
                  key: const ValueKey('login-loading'),
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: palette.onAction,
                    semanticsLabel: loadingLabel,
                  ),
                )
              : Row(
                  key: const ValueKey('login-idle'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
