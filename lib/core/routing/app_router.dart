import 'package:driver_portal_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:driver_portal_app/features/auth/presentation/bloc/login_bloc.dart';
import 'package:driver_portal_app/features/auth/presentation/pages/login_page.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class AppRoute {
  static const String login = '/login';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            return BlocProvider(
              create: (_) => LoginBloc(context.read<LoginUseCase>()),
              child: const LoginPage(),
            );
          },
        );

      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScope(),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: Text(AppLocalizations.of(context).pageNotFound),
            ),
          ),
        );
    }
  }
}
