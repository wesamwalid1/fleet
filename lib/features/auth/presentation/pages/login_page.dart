import 'dart:math' as math;

import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/core/theme/app_surfaces.dart';
import 'package:driver_portal_app/core/theme/app_text_styles.dart';
import 'package:driver_portal_app/core/widgets/ticket_border.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

/// Sign-in as an issued ticket: a stub with the product name, a perforated
/// tear line, and the credentials below it, centred on a calm ground.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const _pagePadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          current is LoginSuccess && previous is! LoginSuccess,
      listener: (context, state) {
        Navigator.of(context).pushReplacementNamed(AppRoute.home);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: palette.systemBars,
        child: Scaffold(
          backgroundColor: palette.ground,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              // Rebuilds as the keyboard resizes the body; the content below
              // is const, so only this shell is rebuilt.
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: _pagePadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight - _pagePadding * 2,
                      ),
                    ),
                    child: const Center(child: _LoginContent()),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Rise(child: _Ticket()),
          const SizedBox(height: 20),
          Text(
            l10n.contactVaultManager,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final issued = DateFormat(
      'd MMM y',
      l10n.localeName,
    ).format(DateTime.now());

    return TextSelectionTheme(
      data: TextSelectionThemeData(
        cursorColor: palette.focus,
        selectionColor: palette.focus.withValues(alpha: 0.22),
        selectionHandleColor: palette.focus,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inline = LoginHeader.fitsInline(
            context,
            width: constraints.maxWidth,
            title: l10n.driverPortal,
            issued: issued,
          );
          final tearY = LoginHeader.heightFor(
            MediaQuery.textScalerOf(context),
            inline: inline,
          );
          return DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.surface,
              shadows: palette.raisedShadow,
              shape: TicketBorder(tearY: tearY, borderColor: palette.hairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoginHeader(
                  title: l10n.driverPortal,
                  issued: issued,
                  height: tearY,
                  inline: inline,
                ),
                const LoginForm(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The one entrance moment: on a cold start the ticket rises into place once,
/// already visible, so nothing is hidden while it settles. When a route
/// transition brings the page in, or the system asks for reduced motion, the
/// ticket simply appears; the decision is made once so a later rebuild never
/// starts it late.
class _Rise extends StatefulWidget {
  final Widget child;

  const _Rise({required this.child});

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> {
  static const _distance = 18.0;

  bool? _animate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate ??=
        !MediaQuery.disableAnimationsOf(context) &&
        (ModalRoute.of(context)?.animation?.isCompleted ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final boundary = RepaintBoundary(child: widget.child);
    if (_animate != true) return boundary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutExpo,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, _distance * t),
          child: child,
        );
      },
      child: boundary,
    );
  }
}
