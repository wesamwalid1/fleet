import 'package:driver_portal_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen is the app entry point', (tester) async {
    await tester.pumpWidget(const DriverPortalApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Sign in to your driver account'), findsOneWidget);
  });
}
