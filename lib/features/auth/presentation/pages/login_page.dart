import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/core/theme/app_colors.dart';
import 'package:driver_portal_app/core/theme/app_surfaces.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

/// A dark blue brand band with the sign-in card overlapping its lower edge,
/// on the light app background.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          current is LoginSuccess && previous is! LoginSuccess,
      listener: (context, state) {
        Navigator.of(context).pushReplacementNamed(AppRoute.home);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppSurfaces.of(context).scaffold,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final headerHeight = constraints.maxHeight < 700
                    ? 250.0
                    : constraints.maxHeight * 0.38;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: headerHeight,
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.title, AppColors.inkLift],
                              ),
                            ),
                            child: LoginHeader(title: l10n.driverPortal),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -78),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: LoginForm(),
                          ),
                        ),
                      ],
                    ),
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
