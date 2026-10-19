import 'package:driver_portal_app/core/routing/app_router.dart';
import 'package:driver_portal_app/features/auth/data/repositories/auth_repository.dart';
import 'package:driver_portal_app/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:driver_portal_app/features/auth/logic/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


void main() {
  runApp(
    RepositoryProvider<AuthRepository>(
      create: (_) => DemoAuthRepository(),
      child: BlocProvider(
        create: (context) => LoginCubit(
          context.read<AuthRepository>(),
        ),
        child: const DriverPortalApp(),
      ),
    ),
  );
}

class DriverPortalApp extends StatelessWidget {
  const DriverPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver Portal',
      initialRoute: AppRoute.login,
      onGenerateRoute: AppRoute.onGenerateRoute,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
    );
  }
}