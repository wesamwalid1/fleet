import 'package:flutter_test/flutter_test.dart';

import 'support/fake_connectivity.dart';

void main() {
  testWidgets('login screen is the app entry point', (tester) async {
    await tester.pumpWidget(testPortalApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Sign in to your driver account'), findsOneWidget);
  });
}
