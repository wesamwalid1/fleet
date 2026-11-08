import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _me = MockCashLedger.senderId;
final _at = DateTime(2026, 11, 3, 9);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows Total Balance instead of Current Balance', (tester) async {
    await _openRequestCash(tester);
    final sheet = find.byKey(const Key('request-cash-flow'));

    expect(
      find.descendant(of: sheet, matching: find.text('Total Balance')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Current balance')),
      findsNothing,
    );
    expect(_text(tester, 'request-cash-total-balance'), '2,200 EGP');
    expect(
      find.descendant(of: sheet, matching: find.text('5,000 EGP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('2,800 EGP')),
      findsOneWidget,
    );
  });

  testWidgets('Total Balance includes frozen amounts, not Available', (
    tester,
  ) async {
    final ledger = await _openRequestCash(
      tester,
      configureLedger: (ledger) {
        ledger.createPendingTransfer(
          senderId: _me,
          recipientId: 'DR-003',
          amountEgp: 300,
          createdAt: _at,
        );
        ledger.submitWithdraw(driverId: _me, amountEgp: 200, createdAt: _at);
      },
    );
    final sheet = find.byKey(const Key('request-cash-flow'));

    expect(ledger.availableBalance(_me), 1700);
    expect(_text(tester, 'request-cash-total-balance'), '2,200 EGP');
    expect(
      find.descendant(of: sheet, matching: find.text('1,700 EGP')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('2,800 EGP')),
      findsOneWidget,
    );
  });

  testWidgets('validation and submission are unchanged', (tester) async {
    final ledger = await _openRequestCash(tester);

    await tester.enterText(
      find.byKey(const Key('request-cash-amount')),
      '2801',
    );
    await tester.pump();
    expect(
      find.text('Amount exceeds your available request capacity'),
      findsOneWidget,
    );
    expect(_canSubmit(tester), isFalse);

    await tester.enterText(
      find.byKey(const Key('request-cash-amount')),
      '1000',
    );
    await tester.pump();
    expect(_canSubmit(tester), isTrue);

    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pumpAndSettle();
    expect(ledger.pendingRequestCash(_me), 1000);
    expect(ledger.totalBalance(_me), 2200);
  });

  testWidgets('Pending Request Cash sits between Max Limit and capacity', (
    tester,
  ) async {
    await _openRequestCash(tester);
    final sheet = find.byKey(const Key('request-cash-flow'));
    double y(String label) => tester
        .getCenter(find.descendant(of: sheet, matching: find.text(label)))
        .dy;

    expect(y('Max Limit'), lessThan(y('Pending Request Cash')));
    expect(
      y('Pending Request Cash'),
      lessThan(y('Available request capacity')),
    );
    _expectSummary(
      tester,
      total: '2,200 EGP',
      pending: '0 EGP',
      capacity: '2,800 EGP',
    );
  });

  testWidgets('sums pending requests and excludes approved and rejected', (
    tester,
  ) async {
    await _openRequestCash(
      tester,
      configureLedger: (ledger) {
        _request(ledger, 1000);
        _request(ledger, 800);
        ledger.approveCashRequest(_request(ledger, 300));
        ledger.rejectCashRequest(_request(ledger, 200));
      },
    );

    _expectSummary(
      tester,
      total: '2,500 EGP',
      pending: '1,800 EGP',
      capacity: '700 EGP',
    );
  });

  testWidgets('pending follows create, approve, and reject', (tester) async {
    final ledger = await _openRequestCash(tester);

    await tester.enterText(
      find.byKey(const Key('request-cash-amount')),
      '1000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cash-request-home')));
    await tester.pumpAndSettle();

    await _openSheet(tester);
    _expectSummary(
      tester,
      total: '2,200 EGP',
      pending: '1,000 EGP',
      capacity: '1,800 EGP',
    );
    await _closeSheet(tester);

    ledger.approveCashRequest(ledger.cashRequests.single.id);
    await tester.pumpAndSettle();
    await _openSheet(tester);
    _expectSummary(
      tester,
      total: '3,200 EGP',
      pending: '0 EGP',
      capacity: '1,800 EGP',
    );
    await _closeSheet(tester);

    final second = _request(ledger, 500);
    await tester.pumpAndSettle();
    await _openSheet(tester);
    _expectSummary(
      tester,
      total: '3,200 EGP',
      pending: '500 EGP',
      capacity: '1,300 EGP',
    );
    await _closeSheet(tester);

    ledger.rejectCashRequest(second);
    await tester.pumpAndSettle();
    await _openSheet(tester);
    _expectSummary(
      tester,
      total: '3,200 EGP',
      pending: '0 EGP',
      capacity: '1,800 EGP',
    );
  });

  testWidgets('a narrow screen with large text does not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: HomeScope(
          now: () => DateTime(2026, 11, 3, 12),
          seedApprovals: false,
          configureLedger: (ledger) => _request(ledger, 1234),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openSheet(tester);

    expect(_text(tester, 'request-cash-pending'), contains('ج.م'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows one consistent snapshot when Home finance is unavailable',
    (tester) async {
      await _openRequestCash(
        tester,
        financeRepository: _UnavailableFinanceRepository(),
        configureLedger: (ledger) {
          ledger.createPendingTransfer(
            senderId: _me,
            recipientId: 'DR-003',
            amountEgp: 300,
            createdAt: _at,
          );
          _request(ledger, 1000);
        },
      );

      expect(
        find.byKey(const Key('balance-error'), skipOffstage: false),
        findsOneWidget,
      );
      _expectSummary(
        tester,
        total: '2,200 EGP',
        pending: '1,000 EGP',
        capacity: '1,800 EGP',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('request-cash-flow')),
          matching: find.text('5,000 EGP'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a very long amount is kept, flagged, and recoverable', (
    tester,
  ) async {
    final ledger = await _openRequestCash(tester);
    const huge = '123456789012345678901234567890';
    const error = 'Amount exceeds your available request capacity';
    final amount = find.byKey(const Key('request-cash-amount'));

    await tester.enterText(amount, '500');
    await tester.pump();
    expect(_canSubmit(tester), isTrue);

    await tester.enterText(amount, huge);
    await tester.pump();
    expect(find.text(error), findsOneWidget);
    expect(_canSubmit(tester), isFalse);
    expect(tester.widget<TextField>(amount).controller!.text, huge);
    _expectSummary(
      tester,
      total: '2,200 EGP',
      pending: '0 EGP',
      capacity: '2,800 EGP',
    );

    await tester.enterText(amount, '1000');
    await tester.pump();
    expect(find.text(error), findsNothing);
    expect(_canSubmit(tester), isTrue);

    expect(ledger.cashRequests, isEmpty);
  });

  testWidgets('arabic shows the localized Total Balance label', (tester) async {
    await _openRequestCash(tester, locale: const Locale('ar'));
    final sheet = find.byKey(const Key('request-cash-flow'));

    expect(
      find.descendant(of: sheet, matching: find.text('إجمالي الرصيد')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('الرصيد الحالي')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('طلبات النقد المعلّقة')),
      findsOneWidget,
    );
    expect(
      Directionality.of(tester.element(find.text('طلبات النقد المعلّقة'))),
      TextDirection.rtl,
    );
    expect(_text(tester, 'request-cash-total-balance'), contains('ج.م'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('amount chips fill the field and allow manual edit', (
    tester,
  ) async {
    await _openRequestCash(tester);

    for (final amount in [500, 1000, 1500, 2000]) {
      expect(find.byKey(Key('request-cash-chip-$amount')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('request-cash-chip-1000')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('request-cash-amount')))
          .controller!
          .text,
      '1000',
    );
    expect(_canSubmit(tester), isTrue);

    await tester.enterText(find.byKey(const Key('request-cash-amount')), '750');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('request-cash-amount')))
          .controller!
          .text,
      '750',
    );
  });

  testWidgets('three-stage progress, review impact, edit, and confirm only', (
    tester,
  ) async {
    final ledger = await _openRequestCash(tester);

    expect(find.byKey(const Key('request-cash-step-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('request-cash-step-dot-1')), findsOneWidget);
    expect(find.textContaining('Step 1 of 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request-cash-chip-500')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('request-cash-note')),
      '  vault top-up  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();

    expect(ledger.cashRequests, isEmpty);
    expect(find.text('Review request'), findsOneWidget);
    expect(find.textContaining('Step 2 of 2'), findsOneWidget);
    expect(find.text('vault top-up'), findsOneWidget);
    expect(find.textContaining('2,800 EGP'), findsWidgets);
    expect(find.textContaining('2,300 EGP'), findsWidgets);
    expect(
      find.textContaining(
        'This request stays pending until the company confirms it',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('request-cash-edit')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('request-cash-amount')))
          .controller!
          .text,
      '500',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('request-cash-note')))
          .controller!
          .text,
      '  vault top-up  ',
    );

    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cash-request-success')), findsOneWidget);
    expect(find.byKey(const Key('request-cash-step-label')), findsNothing);
    expect(find.textContaining('RC-'), findsWidgets);
    expect(ledger.cashRequests.single.requestNumber, startsWith('RC-'));
    expect(ledger.cashRequests.single.note, 'vault top-up');
    expect(ledger.pendingRequestCash(_me), 500);
    expect(ledger.totalBalance(_me), 2200);
  });

  testWidgets('go home and view transaction highlight the request', (
    tester,
  ) async {
    final ledger = await _openRequestCash(tester);
    await tester.tap(find.byKey(const Key('request-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pumpAndSettle();

    final id = ledger.cashRequests.single.id;
    await tester.tap(find.byKey(const Key('cash-request-view')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-title')), findsOneWidget);
    expect(find.byKey(Key('history-highlight-$id')), findsOneWidget);
    expect(find.byKey(Key('history-entry-$id')), findsOneWidget);
  });

  testWidgets('go home returns to Home without highlighting', (tester) async {
    await _openRequestCash(tester);
    await tester.tap(find.byKey(const Key('request-cash-chip-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-cash-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-cash-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cash-request-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('request-cash-flow')), findsNothing);
    expect(find.byKey(const Key('cash-request-success')), findsNothing);
    expect(find.byKey(const Key('request-cash')), findsOneWidget);
  });

  testWidgets('dark mode request cash flow does not overflow', (tester) async {
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
    await tester.ensureVisible(find.byKey(const Key('request-cash')));
    await tester.tap(find.byKey(const Key('request-cash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request-cash-flow')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectSummary(
  WidgetTester tester, {
  required String total,
  required String pending,
  required String capacity,
}) {
  expect(_text(tester, 'request-cash-total-balance'), total);
  expect(_text(tester, 'request-cash-pending'), pending);
  expect(_text(tester, 'request-cash-capacity'), capacity);
}

String _request(MockCashLedger ledger, int amount) {
  return ledger
      .submitRequestCash(driverId: _me, amountEgp: amount, createdAt: _at)
      .id;
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

bool _canSubmit(WidgetTester tester) {
  return tester
          .widget<FilledButton>(find.byKey(const Key('request-cash-continue')))
          .onPressed !=
      null;
}

Future<MockCashLedger> _openRequestCash(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  void Function(MockCashLedger ledger)? configureLedger,
  FinanceRepository? financeRepository,
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
        financeRepository: financeRepository,
        configureLedger: (ledger) {
          if (captured != null) return;
          captured = ledger;
          configureLedger?.call(ledger);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _openSheet(tester);
  return captured!;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('request-cash')));
  await tester.tap(find.byKey(const Key('request-cash')));
  await tester.pumpAndSettle();
}

Future<void> _closeSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('request-cash-back')));
  await tester.pumpAndSettle();
}

class _UnavailableFinanceRepository implements FinanceRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    throw Exception('finance unavailable');
  }
}
