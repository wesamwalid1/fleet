import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home shows the two newest actionable approvals', (tester) async {
    await _pump(tester);

    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-RE-2026-1041')), findsNothing);
    expect(find.byKey(const Key('home-pending-DSB-2025-0301')), findsNothing);
    expect(find.byKey(const Key('home-recent-TRF-2025-0090')), findsOneWidget);
    expect(find.textContaining('EXP-'), findsNothing);

    expect(
      tester.getTopLeft(find.byKey(const Key('home-pending-DSB-2025-0441'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('home-pending-TRF-2025-0123')))
            .dy,
      ),
    );
    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
  });

  testWidgets('home keeps only the latest two when more are pending', (
    tester,
  ) async {
    await _pump(
      tester,
      configureLedger: (ledger) {
        ledger.addPendingVaultReceipt(
          id: 'DSB-2026-1201',
          amountEgp: 150,
          createdAt: DateTime(2026, 12, 1),
        );
        ledger.addPendingVaultReceipt(
          id: 'DSB-2024-0101',
          amountEgp: 50,
          createdAt: DateTime(2024, 1, 1),
        );
      },
    );

    expect(find.text('5 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2026-1201')), findsNothing);
    expect(find.byKey(const Key('home-pending-RE-2026-1041')), findsNothing);
    expect(find.byKey(const Key('home-pending-DSB-2024-0101')), findsNothing);
    expect(find.text('Received from Sami Hassan'), findsNothing);
  });

  testWidgets('home shows an empty state when nothing is pending', (
    tester,
  ) async {
    await _pump(tester, seedApprovals: false);

    expect(find.byKey(const Key('home-all-caught-up')), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('No pending approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsNothing);
    expect(find.text('Received from Vault'), findsNothing);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
  });

  testWidgets('approving a home request credits the shared balance once', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('home-pending-DSB-2025-0441')));
    await tester.pumpAndSettle();
    expect(find.text('Action Required'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Approve Cash Receipt'), findsOneWidget);
    expect(find.text('4,200 EGP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('approval-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(find.text('3 pending'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-pending-DSB-2025-0441')));
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

    expect(_text(tester, 'home-balance'), '4,200 EGP');
    expect(find.text('6,200 EGP'), findsNothing);
    expect(find.text('2 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsNothing);
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');

    await tester.tap(find.byKey(const Key('home-view-all-approvals')));
    await tester.pumpAndSettle();
    expect(find.text('Action Required'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );
    expect(find.text('2 pending'), findsOneWidget);
  });
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Future<void> _pump(
  WidgetTester tester, {
  bool seedApprovals = true,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      home: HomeScope(
        now: () => DateTime(2026, 10, 20, 9),
        seedApprovals: seedApprovals,
        configureLedger: configureLedger,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
