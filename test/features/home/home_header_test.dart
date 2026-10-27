import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/home/domain/greeting.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('the avatar opens profile and the bell opens notifications', (
    tester,
  ) async {
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-header')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-notifications')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-page')), findsOneWidget);
    expect(find.byKey(const Key('pending-count')), findsNothing);
  });

  testWidgets('the bell dot follows unread notifications, not approvals', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);

    await _finalize(tester, 'DSB-2025-0441', 'approval-approve');
    await _finalize(tester, 'TRF-2025-0123', 'approval-approve');
    await _finalize(tester, 'RE-2026-1041', 'approval-confirm');
    expect(find.byKey(const Key('nav-approvals-dot')), findsNothing);
    expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);

    final notifications = tester
        .element(find.byKey(const Key('home-notifications')))
        .read<NotificationRepository>();
    for (final item in await notifications.getNotifications('DR-001')) {
      await notifications.markRead(driverId: 'DR-001', id: item.id);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-notification-dot')), findsNothing);
    expect(find.byKey(const Key('home-notifications')), findsOneWidget);
  });

  testWidgets('the bell dot stays hidden when nothing is pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(now: () => DateTime(2026, 10, 20, 9), seedApprovals: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-notification-dot')), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsWidgets);
  });

  testWidgets('action labels stay complete and the buttons stay equal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();

    _expectEqualActionButtons(tester, 'Send Cash', 'Record Expense');

    await tester.pumpWidget(
      _app(locale: const Locale('ar'), now: () => DateTime(2026, 10, 20, 9)),
    );
    await tester.pumpAndSettle();
    _expectEqualActionButtons(tester, 'إرسال نقد', 'تسجيل مصروف');
    expect(tester.takeException(), isNull);
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

void _expectEqualActionButtons(
  WidgetTester tester,
  String sendLabel,
  String expenseLabel,
) {
  final send = tester.getSize(find.byKey(const Key('send-cash')));
  final expense = tester.getSize(find.byKey(const Key('record-expense')));
  expect(send.width, expense.width);
  expect(find.text(sendLabel), findsOneWidget);
  expect(find.text(expenseLabel), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _finalize(WidgetTester tester, String id, String actionKey) async {
  await tester.ensureVisible(find.byKey(Key('approval-action-$id')));
  await tester.tap(find.byKey(Key('approval-action-$id')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.ensureVisible(find.byKey(Key(actionKey)));
  await tester.tap(find.byKey(Key(actionKey)));
  await tester.pumpAndSettle();
}

Widget _app({
  Locale? locale,
  required DateTime Function() now,
  bool seedApprovals = true,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeScope(now: now, seedApprovals: seedApprovals),
  );
}
