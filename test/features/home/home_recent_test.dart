import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/presentation/history_format.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/app_colors.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recent shows the three newest ledger rows and opens history', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(const Key('home-recent-title')), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(find.byKey(const Key('recent-entry-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('recent-entry-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('recent-entry-TRF-2025-0090')), findsOneWidget);
    expect(find.byKey(const Key('recent-entry-DSB-2025-0301')), findsNothing);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Pending — from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Drivers Vault · Awaiting your approval'), findsOneWidget);
    expect(find.textContaining('DR-004 · Approved'), findsOneWidget);
    expect(find.text('+800 EGP'), findsOneWidget);
    expect(find.text('13 May 2025'), findsNWidgets(2));
    expect(find.text('12 May 2025'), findsOneWidget);

    expect(
      tester.getTopLeft(find.byKey(const Key('recent-entry-TRF-2025-0123'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('recent-entry-DSB-2025-0441')))
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('recent-entry-DSB-2025-0441'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('recent-entry-TRF-2025-0090')))
            .dy,
      ),
    );

    await tester.tap(find.byKey(const Key('recent-entry-TRF-2025-0090')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-title')), findsNothing);
    expect(find.text('Expense Details'), findsNothing);
    expect(find.text('2,200 EGP'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('home-recent-see-all')));
    await tester.tap(find.byKey(const Key('home-recent-see-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.byKey(const Key('recent-entry-TRF-2025-0123')), findsNothing);
    expect(find.text('2,200 EGP'), findsNothing);
  });

  testWidgets('today and yesterday use the clock and a relative label', (
    tester,
  ) async {
    await _pump(
      tester,
      now: () => DateTime(2026, 10, 21, 12),
      configureLedger: (ledger) {
        ledger.createPendingTransfer(
          senderId: MockCashLedger.senderId,
          recipientId: 'DR-004',
          amountEgp: 100,
          createdAt: DateTime(2026, 10, 21, 9),
        );
        ledger.createPendingTransfer(
          senderId: MockCashLedger.senderId,
          recipientId: 'DR-002',
          amountEgp: 50,
          createdAt: DateTime(2026, 10, 20, 14, 30),
        );
      },
    );

    expect(
      find.text(historyClock(DateTime(2026, 10, 21, 9), 'en')),
      findsOneWidget,
    );
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Sent to Sami Hassan'), findsOneWidget);
    expect(find.textContaining('DR-004 · Pending confirm'), findsOneWidget);
    expect(find.text('-100 EGP'), findsOneWidget);
    expect(find.text('2,050 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('a recorded expense opens the existing details sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      configureLedger: (ledger) {
        ledger.createRecordedExpense(
          driverId: MockCashLedger.senderId,
          tripId: 'trip-2026-0927',
          settlementType: SettlementType.crossBorder,
          amountEgp: 100,
          notes: null,
          attachments: const [],
          createdAt: DateTime(2026, 10, 21, 11, 37),
        );
      },
    );

    expect(find.text('2,100 EGP'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('recent-entry-EXP-412138')),
    );
    await tester.tap(find.byKey(const Key('recent-entry-EXP-412138')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Expense Details'), findsOneWidget);
    expect(find.text('DEDUCTED'), findsOneWidget);
    expect(find.text('EXP-412138'), findsWidgets);

    await tester.tap(find.byKey(const Key('history-expense-close')));
    await tester.pumpAndSettle();
    expect(find.text('Expense Details'), findsNothing);
    expect(find.text('2,100 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('an approval updates the recent status without a second credit', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Drivers Vault · Awaiting your approval'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();

    expect(find.text('Drivers Vault · Awaiting your approval'), findsNothing);
    expect(find.textContaining('Drivers Vault · Approved'), findsOneWidget);
    expect(find.text('4,200 EGP'), findsOneWidget);
    expect(find.text('6,200 EGP'), findsNothing);
    expect(find.text('3,200'), findsOneWidget);
  });

  testWidgets('an empty ledger shows the empty state', (tester) async {
    await _pump(tester, seedApprovals: false);

    expect(find.byKey(const Key('home-recent-empty')), findsOneWidget);
    expect(find.text('No transactions'), findsOneWidget);
    expect(find.byKey(const Key('recent-entry-DSB-2025-0441')), findsNothing);
    expect(find.byType(HistoryEntryDivider), findsNothing);
    expect(find.text('2,200 EGP'), findsOneWidget);
  });

  testWidgets('every recent transaction has a divider below it', (
    tester,
  ) async {
    await _pump(tester);

    const ids = ['TRF-2025-0123', 'DSB-2025-0441', 'TRF-2025-0090'];
    expect(find.byType(HistoryEntryDivider), findsNWidgets(ids.length));
    final line = tester.widget<Divider>(find.byType(Divider).first);
    expect(line.height, 1);
    expect(line.thickness, 1);
    expect(line.color, AppColors.title.withValues(alpha: 0.08));

    for (final id in ids) {
      final tile = tester.getRect(find.byKey(Key('recent-entry-$id')));
      final below = _dividerBelow(tester, tile);
      expect(below.top, closeTo(tile.bottom, 1));
      expect(below.width, closeTo(tile.width, 1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('arabic recent copy is localized', (tester) async {
    await _pump(tester, locale: const Locale('ar'));

    expect(find.text('الأخيرة'), findsOneWidget);
    expect(find.text('عرض الكل'), findsOneWidget);
    expect(find.text('بانتظار موافقتك'), findsWidgets);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('home-recent-title'))),
      ),
      TextDirection.rtl,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool seedApprovals = true,
  DateTime Function()? now,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      home: HomeScope(
        now: now ?? () => DateTime(2026, 10, 21, 12),
        seedApprovals: seedApprovals,
        configureLedger: configureLedger,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _dividerBelow(WidgetTester tester, Rect tile) {
  final dividers = find.byType(HistoryEntryDivider);
  final count = tester.widgetList(dividers).length;
  return [
    for (var index = 0; index < count; index++)
      tester.getRect(dividers.at(index)),
  ].firstWhere((rect) => (rect.top - tile.bottom).abs() <= 1);
}
