import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/home/domain/greeting.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('greetingFor', () {
    test('uses morning before noon', () {
      expect(greetingFor(DateTime(2026, 10, 20, 0)), GreetingPeriod.morning);
      expect(
        greetingFor(DateTime(2026, 10, 20, 11, 59)),
        GreetingPeriod.morning,
      );
    });

    test('uses afternoon from noon until 17:00', () {
      expect(greetingFor(DateTime(2026, 10, 20, 12)), GreetingPeriod.afternoon);
      expect(
        greetingFor(DateTime(2026, 10, 20, 16, 59)),
        GreetingPeriod.afternoon,
      );
    });

    test('uses evening from 17:00', () {
      expect(greetingFor(DateTime(2026, 10, 20, 17)), GreetingPeriod.evening);
      expect(
        greetingFor(DateTime(2026, 10, 20, 23, 59)),
        GreetingPeriod.evening,
      );
    });
  });

  group('Driver.initials', () {
    test('uses the first and last name', () {
      expect(const Driver(fullName: 'Ahmed Ali').initials, 'AA');
    });

    test('ignores extra spaces', () {
      expect(const Driver(fullName: '  Ahmed   Ali  ').initials, 'AA');
    });

    test('uses one letter for a single name', () {
      expect(const Driver(fullName: 'Ahmed').initials, 'A');
    });
  });

  testWidgets('header shows the morning greeting, name, and initials', (
    tester,
  ) async {
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();

    expect(find.text('Good morning 👋'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('AA'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('header follows the afternoon and evening', (tester) async {
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 14)));
    await tester.pumpAndSettle();
    expect(find.text('Good afternoon 👋'), findsOneWidget);

    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 19)));
    await tester.pumpAndSettle();
    expect(find.text('Good evening 👋'), findsOneWidget);
  });

  testWidgets('arabic header is right to left', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('ar'), now: () => DateTime(2026, 10, 20, 9)),
    );
    await tester.pumpAndSettle();

    expect(find.text('صباح الخير 👋'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Ahmed Ali'))),
      TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.text('AA')).dx,
      lessThan(tester.getCenter(find.text('Ahmed Ali')).dx),
    );
  });

  testWidgets('english header keeps the avatar on the right', (tester) async {
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.text('AA')).dx,
      greaterThan(tester.getCenter(find.text('Ahmed Ali')).dx),
    );
  });
}

Widget _app({Locale? locale, required DateTime Function() now}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeScope(now: now),
  );
}
