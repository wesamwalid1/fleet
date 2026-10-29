import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/home/domain/greeting.dart';
import 'package:driver_portal_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      expect(
        const Driver(fullName: LocalizedString(en: 'Ahmed Ali')).initials(),
        'AA',
      );
    });

    test('ignores extra spaces', () {
      expect(
        const Driver(fullName: LocalizedString(en: '  Ahmed   Ali  '))
            .initials(),
        'AA',
      );
    });

    test('uses one letter for a single name', () {
      expect(
        const Driver(fullName: LocalizedString(en: 'Ahmed')).initials(),
        'A',
      );
    });

    test('uses Arabic initials for the Arabic locale', () {
      expect(
        const Driver(
          fullName: LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي'),
        ).initials(const Locale('ar')),
        'أع',
      );
    });
  });

  testWidgets('header shows the welcome, name, and initials', (tester) async {
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await _finalize(tester, 'DSB-2025-0441', 'approval-approve');
    await _finalize(tester, 'TRF-2025-0123', 'approval-approve');
    await _finalize(tester, 'RE-2026-1041', 'approval-confirm');
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
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

    _expectEqualActionButtons(
      tester,
      const Key('send-cash'),
      'Send Cash',
      const Key('record-expense'),
      'Record Expense',
    );
    _expectEqualActionButtons(
      tester,
      const Key('request-cash'),
      'Request Cash',
      const Key('withdraw'),
      'Withdraw',
    );

    await tester.pumpWidget(
      _app(locale: const Locale('ar'), now: () => DateTime(2026, 10, 20, 9)),
    );
    await tester.pumpAndSettle();
    _expectEqualActionButtons(
      tester,
      const Key('send-cash'),
      'إرسال نقد',
      const Key('record-expense'),
      'تسجيل مصروف',
    );
    _expectEqualActionButtons(
      tester,
      const Key('request-cash'),
      'طلب نقد',
      const Key('withdraw'),
      'تسليم نقد',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the welcome does not change with the time of day', (
    tester,
  ) async {
    for (final hour in const [9, 14, 19]) {
      await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, hour)));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back!'), findsOneWidget, reason: '$hour:00');
      expect(find.textContaining('Good '), findsNothing, reason: '$hour:00');
    }
  });

  testWidgets('arabic header is right to left', (tester) async {
    await tester.pumpWidget(
      _app(locale: const Locale('ar'), now: () => DateTime(2026, 10, 20, 9)),
    );
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بعودتك!'), findsOneWidget);
    expect(find.text('أحمد علي'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('أحمد علي'))),
      TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.text('أع')).dx,
      greaterThan(tester.getCenter(find.text('أحمد علي')).dx),
    );
  });

  testWidgets('english header puts the avatar before the name', (tester) async {
    await tester.pumpWidget(_app(now: () => DateTime(2026, 10, 20, 9)));
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.text('AA')).dx,
      lessThan(tester.getCenter(find.text('Ahmed Ali')).dx),
    );
  });
}

void _expectEqualActionButtons(
  WidgetTester tester,
  Key leftKey,
  String leftLabel,
  Key rightKey,
  String rightLabel,
) {
  final left = find.byKey(leftKey);
  final right = find.byKey(rightKey);
  expect(tester.getSize(left).width, tester.getSize(right).width);
  expect(
    find.descendant(of: left, matching: find.text(leftLabel)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: right, matching: find.text(rightLabel)),
    findsOneWidget,
  );
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
