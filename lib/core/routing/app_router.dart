import 'package:driver_portal_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';



abstract final class AppRoute {
  static const String login = '/login';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        );

      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Placeholder(),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}