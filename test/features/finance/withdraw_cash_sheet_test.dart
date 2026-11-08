import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _me = MockCashLedger.senderId;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows available balance and live balance after withdrawal', (
    tester,
  ) async {
    final ledger = await _openWithdraw(tester);
    final sheet = find.byKey(const Key('withdraw-flow'));

    expect(
      find.descendant(of: sheet, matching: find.text('Available Balance')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Withdrawal Amount')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('Balance After Withdrawal'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Current balance')),
      findsNothing,
    );
    expect(_text(tester, 'withdraw-available-balance'), '2,200 EGP');
    expect(_text(tester, 'withdraw-balance-after'), '2,200 EGP');
    expect(_canSubmit(tester), isFalse);

    await _enter(tester, '500');
    expect(_text(tester, 'withdraw-balance-after'), '1,700 EGP');
    expect(_text(tester, 'withdraw-available-balance'), '2,200 EGP');
    expect(_canSubmit(tester), isTrue);

    await _enter(tester, '2200');
    expect(_text(tester, 'withdraw-balance-after'), '0 EGP');
    expect(_canSubmit(tester), isTrue);

    expect(ledger.balanceOf(_me), 2200);
  });

  testWidgets('empty, zero, and excessive amounts cannot be submitted', (
    tester,
  ) async {
    final ledger = await _openWithdraw(tester);

    await _enter(tester, '0');
    expect(_text(tester, 'withdraw-balance-after'), '2,200 EGP');
    expect(_canSubmit(tester), isFalse);

    await _enter(tester, '2201');
    expect(_text(tester, 'withdraw-balance-after'), '—');
    expect(find.text('Amount exceeds your available balance'), findsOneWidget);
    expect(_canSubmit(tester), isFalse);

    await _enter(tester, '');
    expect(_text(tester, 'withdraw-balance-after'), '2,200 EGP');
    expect(find.text('Amount exceeds your available balance'), findsNothing);
    expect(_canSubmit(tester), isFalse);

    expect(ledger.cashRequests, isEmpty);
    expect(ledger.balanceOf(_me), 2200);
  });

  testWidgets('an amount beyond the numeric range is not read as zero', (
    tester,
  ) async {
    final ledger = await _openWithdraw(tester);
    const huge = '123456789012345678901234567890';

    await _enter(tester, '500');
    expect(_canSubmit(tester), isTrue);

    await _enter(tester, huge);
    expect(_text(tester, 'withdraw-balance-after'), '—');
    expect(find.text('Amount exceeds your available balance'), findsOneWidget);
    expect(_canSubmit(tester), isFalse);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('withdraw-amount')))
          .controller!
          .text,
      huge,
    );

    await _enter(tester, '300');
    expect(_text(tester, 'withdraw-balance-after'), '1,900 EGP');
    expect(_canSubmit(tester), isTrue);

    expect(ledger.cashRequests, isEmpty);
    expect(ledger.balanceOf(_me), 2200);
  });

  testWidgets('uses the available balance after an existing reservation', (
    tester,
  ) async {
    final ledger = await _openWithdraw(
      tester,
      configureLedger: (ledger) => ledger.submitWithdraw(
        driverId: _me,
        amountEgp: 200,
        createdAt: DateTime(2026, 11, 3, 9),
      ),
    );

    expect(_text(tester, 'withdraw-available-balance'), '2,000 EGP');
    await _enter(tester, '500');
    expect(_text(tester, 'withdraw-balance-after'), '1,500 EGP');

    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('withdraw-submit')));
    await tester.pumpAndSettle();

    expect(ledger.cashRequests, hasLength(2));
    expect(ledger.availableBalance(_me), 1500);
    expect(ledger.frozenBalance(_me), 700);
    expect(ledger.totalBalance(_me), 2200);
  });

  testWidgets('arabic labels and amounts are localized', (tester) async {
    await _openWithdraw(tester, locale: const Locale('ar'));
    final sheet = find.byKey(const Key('withdraw-flow'));

    expect(
      find.descendant(of: sheet, matching: find.text('الرصيد المتاح')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('مبلغ التسليم')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('الرصيد بعد التسليم')),
      findsOneWidget,
    );
    await _enter(tester, '500');
    expect(_text(tester, 'withdraw-balance-after'), contains('ج.م'));
    expect(
      Directionality.of(tester.element(find.text('الرصيد بعد التسليم'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('amount chips fill the field and allow manual edit', (
    tester,
  ) async {
    await _openWithdraw(tester);

    for (final amount in [500, 1000, 1500, 2000]) {
      expect(find.byKey(Key('withdraw-chip-$amount')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('withdraw-chip-1500')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('withdraw-amount')))
          .controller!
          .text,
      '1500',
    );
    expect(_text(tester, 'withdraw-balance-after'), '700 EGP');
    expect(_canSubmit(tester), isTrue);

    await _enter(tester, '400');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('withdraw-amount')))
          .controller!
          .text,
      '400',
    );
    expect(_text(tester, 'withdraw-balance-after'), '1,800 EGP');
  });

  testWidgets('three-stage progress, review impact, edit, and confirm only', (
    tester,
  ) async {
    final ledger = await _openWithdraw(tester);

    expect(find.byKey(const Key('withdraw-step-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('withdraw-step-dot-1')), findsOneWidget);
    expect(find.textContaining('Step 1 of 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('withdraw-chip-500')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('withdraw-note')),
      '  desk handoff  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();

    expect(ledger.cashRequests, isEmpty);
    expect(ledger.balanceOf(_me), 2200);
    expect(find.textContaining('Step 2 of 2'), findsOneWidget);
    expect(find.text('desk handoff'), findsOneWidget);
    expect(find.textContaining('2,200 EGP'), findsWidgets);
    expect(find.textContaining('1,700 EGP'), findsWidgets);
    expect(
      find.textContaining(
        'The amount is deducted now and held until the company confirms',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('withdraw-edit')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('withdraw-amount')))
          .controller!
          .text,
      '500',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('withdraw-note')))
          .controller!
          .text,
      '  desk handoff  ',
    );

    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('withdraw-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cash-request-success')), findsOneWidget);
    expect(find.byKey(const Key('withdraw-step-label')), findsNothing);
    expect(find.textContaining('WD-'), findsWidgets);
    expect(ledger.cashRequests.single.requestNumber, startsWith('WD-'));
    expect(ledger.cashRequests.single.note, 'desk handoff');
    expect(ledger.availableBalance(_me), 1700);
    expect(ledger.frozenBalance(_me), 500);
    expect(ledger.totalBalance(_me), 2200);
  });

  testWidgets('go home and view transaction highlight the withdrawal', (
    tester,
  ) async {
    final ledger = await _openWithdraw(tester);
    await tester.tap(find.byKey(const Key('withdraw-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('withdraw-submit')));
    await tester.pumpAndSettle();

    final id = ledger.cashRequests.single.id;
    await tester.tap(find.byKey(const Key('cash-request-view')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.byKey(Key('history-highlight-$id')), findsOneWidget);
    expect(find.byKey(Key('history-entry-$id')), findsOneWidget);
  });

  testWidgets('go home returns to Home without highlighting', (tester) async {
    await _openWithdraw(tester);
    await tester.tap(find.byKey(const Key('withdraw-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('withdraw-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('withdraw-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cash-request-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('withdraw-flow')), findsNothing);
    expect(find.byKey(const Key('cash-request-success')), findsNothing);
    expect(find.byKey(const Key('withdraw')), findsOneWidget);
  });

  testWidgets('dark mode withdraw flow does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScope(
          now: () => DateTime(2026, 11, 3, 12),
          seedApprovals: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('withdraw')));
    await tester.tap(find.byKey(const Key('withdraw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('withdraw-flow')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

bool _canSubmit(WidgetTester tester) {
  return tester
          .widget<FilledButton>(find.byKey(const Key('withdraw-continue')))
          .onPressed !=
      null;
}

Future<void> _enter(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(const Key('withdraw-amount')), value);
  await tester.pump();
}

Future<MockCashLedger> _openWithdraw(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  MockCashLedger? captured;
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
        now: () => DateTime(2026, 11, 3, 12),
        seedApprovals: false,
        configureLedger: (ledger) {
          if (captured != null) return;
          captured = ledger;
          configureLedger?.call(ledger);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('withdraw')));
  await tester.tap(find.byKey(const Key('withdraw')));
  await tester.pumpAndSettle();
  return captured!;
}
