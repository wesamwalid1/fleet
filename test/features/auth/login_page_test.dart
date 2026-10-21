import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows validation messages and does not leave login', (
    tester,
  ) async {
    await tester.pumpWidget(const DriverPortalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-email')), 'DR-001');
    await tester.enterText(find.byKey(const Key('login-password')), '123456');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('shows invalid credentials for the wrong password', (
    tester,
  ) async {
    await tester.pumpWidget(const DriverPortalApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'driver@test.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(MockAuthDataSource.delay);
    await tester.pump();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('successful login opens the home route', (tester) async {
    await tester.pumpWidget(const DriverPortalApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      MockAuthDataSource.email,
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      MockAuthDataSource.password,
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(MockAuthDataSource.delay);
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Welcome back!'), findsNothing);
  });

  testWidgets('arabic login layout is right to left', (tester) async {
    await tester.pumpWidget(const DriverPortalApp(locale: Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بعودتك!'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('مرحباً بعودتك!'))),
      TextDirection.rtl,
    );
  });
}
