import 'package:driver_portal_app/core/localization/localized_names.dart';
import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/presentation/approval_format.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_assigned_trips.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/finance_driver.dart';
import 'package:driver_portal_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:driver_portal_app/features/history/presentation/history_format.dart';
import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/notifications/data/datasources/mock_notification_seed.dart';
import 'package:driver_portal_app/features/notifications/data/models/app_notification_model.dart';
import 'package:driver_portal_app/features/notifications/presentation/notification_text.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizedString', () {
    test('resolves English and Arabic and falls back when Arabic is empty', () {
      const both = LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي');
      const englishOnly = LocalizedString(en: 'Ahmed Ali');

      expect(both.resolve('en'), 'Ahmed Ali');
      expect(both.resolve(const Locale('ar')), 'أحمد علي');
      expect(englishOnly.resolve('ar'), 'Ahmed Ali');
      expect(englishOnly.resolve('en'), 'Ahmed Ali');
    });

    test('matches queries against either language', () {
      const name = LocalizedString(en: 'Khaled Ramadan', ar: 'خالد رمضان');
      expect(name.matchesQuery('khaled'), isTrue);
      expect(name.matchesQuery('خالد'), isTrue);
      expect(name.matchesQuery('sami'), isFalse);
    });
  });

  group('Driver and trip entities', () {
    test('drivers and trips keep stable ids with bilingual names', () {
      const driver = Driver(
        id: 'DR-001',
        fullName: LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي'),
      );
      final trip = MockAssignedTrips.trips.first;

      expect(driver.id, 'DR-001');
      expect(driver.displayName('en'), 'Ahmed Ali');
      expect(driver.displayName('ar'), 'أحمد علي');
      expect(trip.id, 'trip-2026-0927');
      expect(LocalizedNames.tripRoute(trip, 'en'), 'Suez → Cairo');
      expect(LocalizedNames.tripRoute(trip, 'ar'), 'السويس → القاهرة');
    });

    test('ledger nameOf preserves ids and bilingual driver names', () {
      final ledger = MockCashLedger(senderBalanceEgp: 2200);
      final name = ledger.nameOf('DR-003');
      expect(name.en, 'Khaled Ramadan');
      expect(name.ar, 'خالد رمضان');
      expect(name.resolve('ar'), 'خالد رمضان');

      final recipients = ledger.recipients(MockCashLedger.senderId);
      expect(recipients.map((FinanceDriver d) => d.id), [
        'DR-003',
        'DR-002',
        'DR-004',
      ]);
      expect(recipients.first.displayName('ar'), 'خالد رمضان');
    });

    test('expense trip ids stay stable while route text localizes', () {
      final trip = MockAssignedTrips.trips.firstWhere(
        (t) => t.id == 'trip-2026-0881',
      );
      expect(trip.id, 'trip-2026-0881');
      expect(trip.code, 'TR-2026-0881');
      expect(trip.route('en'), 'Cairo → Alexandria');
      expect(trip.route('ar'), 'القاهرة → الإسكندرية');
    });
  });

  group('presentation by locale', () {
    Future<AppLocalizations> loadL10n(
      WidgetTester tester,
      Locale locale,
    ) async {
      late AppLocalizations value;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              value = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return value;
    }

    testWidgets('history approvals and notifications use localized names', (
      tester,
    ) async {
      final ledger = MockCashLedger(senderBalanceEgp: 2200)
        ..seedDriverApprovals();
      final history = await HistoryRepositoryImpl(ledger)
          .getHistory(MockCashLedger.senderId);
      final incoming = history.firstWhere((e) => e.id == 'TRF-2025-0123');
      final notification = MockNotificationSeed.forDriver(
        MockCashLedger.senderId,
      ).firstWhere((n) => n.entityId == 'TRF-2025-0123');
      final approval = ApprovalItem(
        id: incoming.id,
        kind: ApprovalKind.driver,
        outcome: ApprovalOutcome.pending,
        amountEgp: incoming.amountEgp,
        occurredAt: incoming.occurredAt,
        reference: incoming.id,
        counterpartyName: incoming.counterpartyName,
        counterpartyId: incoming.counterpartyId,
      );

      final en = await loadL10n(tester, const Locale('en'));
      final ar = await loadL10n(tester, const Locale('ar'));

      expect(historyTitle(en, incoming), contains('Khaled Ramadan'));
      expect(historyTitle(ar, incoming), contains('خالد رمضان'));
      expect(incoming.counterpartyId, 'DR-003');

      expect(approvalTitle(en, approval), contains('Khaled Ramadan'));
      expect(approvalTitle(ar, approval), contains('خالد رمضان'));

      expect(
        notificationTitle(en, notification, 'en'),
        contains('Khaled Ramadan'),
      );
      expect(notificationTitle(ar, notification, 'ar'), contains('خالد رمضان'));
    });

    testWidgets('home shows Arabic driver and trip names in Arabic locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScope(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أحمد علي'), findsWidgets);
      expect(find.text('السويس'), findsOneWidget);
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.text('Ahmed Ali'), findsNothing);
      expect(find.text('Suez'), findsNothing);
    });

    testWidgets('English locale keeps English driver and trip names', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScope(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ahmed Ali'), findsWidgets);
      expect(find.text('Suez'), findsOneWidget);
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('أحمد علي'), findsNothing);
    });
  });

  test('notification persistence stores both name languages', () {
    final original = MockNotificationSeed.forDriver(MockCashLedger.senderId)
        .firstWhere((n) => n.entityId == 'TRF-2025-0123');
    final restored = AppNotificationModel.fromJson(
      AppNotificationModel.toJson(original),
    )!;
    expect(restored.counterpartyName.en, 'Khaled Ramadan');
    expect(restored.counterpartyName.ar, 'خالد رمضان');
    expect(restored.entityId, original.entityId);
  });
}
