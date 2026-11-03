import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:driver_portal_app/features/auth/domain/usecases/restore_session_use_case.dart';
import 'package:driver_portal_app/features/auth/presentation/bloc/login_bloc.dart';
import 'package:driver_portal_app/features/auth/presentation/pages/login_page.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class AppRoute {
  static const String login = '/login';
  static const String home = '/home';

  static const sessionRestoreTimeout = Duration(seconds: 3);

  /// Cold-start destination: Home for a valid persisted session, else Login.
  ///
  /// Never throws: any restore error, or no answer within [timeout], means
  /// Login. A restore that finishes after the timeout is ignored.
  static Future<String> initialRouteFor(
    RestoreSessionUseCase restore, {
    Duration timeout = sessionRestoreTimeout,
  }) async {
    try {
      final user = await restore().timeout(timeout);
      return user == null ? login : home;
    } catch (_) {
      return login;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final connectivity = context.read<ConnectivityBloc>();
            return BlocProvider(
              create: (_) => LoginBloc(
                context.read<LoginUseCase>(),
                isOnline: () => connectivity.state.isOnline,
              ),
              child: const LoginPage(),
            );
          },
        );

      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScope(resetDemoNotifications: kDebugMode),
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
