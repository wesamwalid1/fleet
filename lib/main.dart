import 'package:driver_portal_app/core/connectivity/data/connectivity_plus_monitor.dart';
import 'package:driver_portal_app/core/connectivity/data/http_internet_reachability.dart';
import 'package:driver_portal_app/core/connectivity/domain/internet_reachability.dart';
import 'package:driver_portal_app/core/connectivity/domain/network_interface_monitor.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:driver_portal_app/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:driver_portal_app/core/locale/data/locale_repository_impl.dart';
import 'package:driver_portal_app/core/locale/domain/locale_repository.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_event.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_state.dart';
import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/core/theme/app_theme.dart';
import 'package:driver_portal_app/core/theme/data/theme_repository_impl.dart';
import 'package:driver_portal_app/core/theme/domain/theme_repository.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_bloc.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_event.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_state.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_portal_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_portal_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const DriverPortalApp());
}

class DriverPortalApp extends StatelessWidget {
  final Locale? locale;
  final AuthRepository? authRepository;
  final LocaleRepository? localeRepository;
  final ThemeRepository? themeRepository;
  final NetworkInterfaceMonitor? networkMonitor;
  final InternetReachability? internetReachability;

  const DriverPortalApp({
    super.key,
    this.locale,
    this.authRepository,
    this.localeRepository,
    this.themeRepository,
    this.networkMonitor,
    this.internetReachability,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<LocaleRepository>(
      create: (_) => localeRepository ?? const LocaleRepositoryImpl(),
      child: RepositoryProvider<ThemeRepository>(
        create: (_) => themeRepository ?? const ThemeRepositoryImpl(),
        child: RepositoryProvider<AuthRepository>(
          create: (_) =>
              authRepository ?? AuthRepositoryImpl(const MockAuthDataSource()),
          child: RepositoryProvider<NetworkInterfaceMonitor>(
            // Disposal is owned by [ConnectivityBloc.close], after in-flight
            // probes finish — do not dispose here (avoids double-dispose).
            create: (_) => networkMonitor ?? ConnectivityPlusMonitor(),
            child: RepositoryProvider<InternetReachability>(
              create: (_) => internetReachability ?? HttpInternetReachability(),
              child: Builder(
                builder: (context) {
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) =>
                            LocaleBloc(context.read<LocaleRepository>())
                              ..add(const LocaleStarted()),
                      ),
                      BlocProvider(
                        create: (context) =>
                            ThemeBloc(context.read<ThemeRepository>())
                              ..add(const ThemeStarted()),
                      ),
                      BlocProvider(
                        create: (context) => ConnectivityBloc(
                          monitor: context.read<NetworkInterfaceMonitor>(),
                          reachability: context.read<InternetReachability>(),
                        )..add(const ConnectivityStarted()),
                      ),
                    ],
                    child: RepositoryProvider<LoginUseCase>(
                      create: (_) =>
                          LoginUseCase(context.read<AuthRepository>()),
                      child: _DriverMaterialApp(locale: locale),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverMaterialApp extends StatelessWidget {
  final Locale? locale;

  const _DriverMaterialApp({required this.locale});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, localeState) {
        return BlocBuilder<ThemeBloc, ThemePreferenceState>(
          builder: (context, themeState) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Driver Portal',
              locale: localeState.locale ?? locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              initialRoute: AppRoute.login,
              // Without this, '/login' also builds a '/' route beneath it, which
              // is unknown and shows Page Not Found when navigated back to.
              onGenerateInitialRoutes: (initialRoute) => [
                AppRoute.onGenerateRoute(RouteSettings(name: initialRoute)),
              ],
              onGenerateRoute: AppRoute.onGenerateRoute,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeState.mode,
            );
          },
        );
      },
    );
  }
}
