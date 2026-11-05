import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/history/presentation/history_format.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recent shows the three newest ledger rows and opens history', (
    tester,
  ) async {
    await _pump(tester);

    final recent = find.byKey(const Key('home-recent-card'));
    expect(
      find.descendant(of: recent, matching: find.text('Recent Transactions')),
      findsOneWidget,
    );
    expect(find.text('See all'), findsOneWidget);
    expect(find.byKey(const Key('home-recent-RE-2026-1041')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-TRF-2025-0090')), findsNothing);
    expect(find.byKey(const Key('home-recent-DSB-2025-0301')), findsNothing);
    expect(
      find.descendant(
        of: recent,
        matching: find.text('Pending — from Khaled Ramadan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: recent,
        matching: find.text('Drivers Vault · Awaiting your approval'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: recent,
        matching: find.textContaining('DR-004 · Approved'),
      ),
      findsNothing,
    );
    // Pending road expense is the newest history row (2026) among seed data.
    expect(
      find.descendant(of: recent, matching: find.text('Road Expense Approval')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-pending-card')),
        matching: find.text('Road Expense Approval'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: recent, matching: find.text('-300 EGP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recent, matching: find.text('13 May 2025')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: recent, matching: find.text('12 May 2025')),
      findsNothing,
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('home-recent-RE-2026-1041'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('home-recent-TRF-2025-0123')))
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('home-recent-TRF-2025-0123'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('home-recent-DSB-2025-0441')))
            .dy,
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('home-recent-DSB-2025-0441')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-recent-DSB-2025-0441')));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('history-detail-amount'))).data,
      startsWith('+'),
    );
    await tester.tap(find.byKey(const Key('history-transaction-dismiss')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'home-balance'), '2,200 EGP');

    await tester.ensureVisible(find.byKey(const Key('home-recent-see-all')));
    await tester.tap(find.byKey(const Key('home-recent-see-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.byKey(const Key('home-recent-TRF-2025-0123')), findsNothing);
    expect(find.byKey(const Key('home-balance')), findsNothing);
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
    expect(_text(tester, 'home-balance'), '2,050 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
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

    expect(_text(tester, 'home-balance'), '2,100 EGP');
    await tester.ensureVisible(find.byKey(const Key('home-recent-EXP-412138')));
    await tester.tap(find.byKey(const Key('home-recent-EXP-412138')));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('history-detail-amount'))).data,
      startsWith('-'),
    );
    expect(find.text('EXP-412138'), findsWidgets);

    await tester.tap(find.byKey(const Key('history-expense-close')));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Details'), findsNothing);
    expect(_text(tester, 'home-balance'), '2,100 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
  });

  testWidgets('an approval updates the recent status without a second credit', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Drivers Vault · Awaiting your approval'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-approvals')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();

    final row = find.byKey(const Key('home-recent-DSB-2025-0441'));
    expect(
      find.descendant(
        of: row,
        matching: find.text('Drivers Vault · Awaiting your approval'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('Drivers Vault · Approved'),
      ),
      findsOneWidget,
    );
    expect(_text(tester, 'home-balance'), '4,200 EGP');
    expect(find.text('6,200 EGP'), findsNothing);
    expect(_text(tester, 'home-charge'), '3,200 EGP');
  });

  testWidgets('an empty ledger shows the empty state', (tester) async {
    await _pump(tester, seedApprovals: false);

    expect(find.byKey(const Key('home-recent-empty')), findsOneWidget);
    expect(find.text('No transactions'), findsOneWidget);
    expect(find.byKey(const Key('home-recent-DSB-2025-0441')), findsNothing);
    expect(find.byType(HistoryEntryTile), findsNothing);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
  });

  testWidgets('recent rows are spaced in order without dividers', (
    tester,
  ) async {
    await _pump(tester);

    const ids = ['RE-2026-1041', 'TRF-2025-0123', 'DSB-2025-0441'];
    final recent = find.byKey(const Key('home-recent-card'));
    expect(
      find.descendant(of: recent, matching: find.byType(HistoryEntryDivider)),
      findsNothing,
    );
    final rects = [
      for (final id in ids) tester.getRect(find.byKey(Key('home-recent-$id'))),
    ];
    for (var index = 1; index < rects.length; index++) {
      expect(rects[index].top, greaterThanOrEqualTo(rects[index - 1].bottom));
      expect(rects[index].width, closeTo(rects[0].width, 1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('arabic recent copy is localized', (tester) async {
    await _pump(tester, locale: const Locale('ar'));

    expect(find.text('أحدث الحركات'), findsOneWidget);
    expect(find.text('عرض الكل'), findsOneWidget);
    expect(find.text('بانتظار موافقتك'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('أحدث الحركات'))),
      TextDirection.rtl,
    );
  });
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool seedApprovals = true,
  DateTime Function()? now,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 2400));
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
