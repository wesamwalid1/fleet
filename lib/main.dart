import 'package:driver_portal_app/core/locale/data/locale_repository_impl.dart';
import 'package:driver_portal_app/core/locale/domain/locale_repository.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_event.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_state.dart';
import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/core/theme/app_theme.dart';
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

  const DriverPortalApp({
    super.key,
    this.locale,
    this.authRepository,
    this.localeRepository,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<LocaleRepository>(
      create: (_) => localeRepository ?? const LocaleRepositoryImpl(),
      child: RepositoryProvider<AuthRepository>(
        create: (_) =>
            authRepository ?? AuthRepositoryImpl(const MockAuthDataSource()),
        child: Builder(
          builder: (context) {
            return BlocProvider(
              create: (context) =>
                  LocaleBloc(context.read<LocaleRepository>())
                    ..add(const LocaleStarted()),
              child: RepositoryProvider<LoginUseCase>(
                create: (_) => LoginUseCase(context.read<AuthRepository>()),
                child: _DriverMaterialApp(locale: locale),
              ),
            );
          },
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
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Driver Portal',
          locale: state.locale ?? locale,
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
        );
      },
    );
  }
}
