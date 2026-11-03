import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/domain/entities/settlement_type.dart';
import 'package:driver_portal_app/features/finance/domain/failures/cash_request_exception.dart';
import 'package:driver_portal_app/features/finance/domain/failures/send_cash_exception.dart';
import 'package:driver_portal_app/features/home/data/datasources/mock_finance_data_source.dart';
import 'package:driver_portal_app/features/home/data/repositories/session_finance_repository.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _me = MockCashLedger.senderId;
final _at = DateTime(2026, 11, 3, 10);

MockCashLedger _ledger() => MockCashLedger(senderBalanceEgp: 2200);

/// Asserts the three figures and the Total = Available + Frozen invariant.
void _expectSummary(
  MockCashLedger ledger, {
  required int total,
  required int available,
  required int frozen,
}) {
  expect(ledger.totalBalance(_me), total, reason: 'total');
  expect(ledger.availableBalance(_me), available, reason: 'available');
  expect(ledger.frozenBalance(_me), frozen, reason: 'frozen');
  expect(
    ledger.totalBalance(_me),
    ledger.availableBalance(_me) + ledger.frozenBalance(_me),
    reason: 'Total = Available + Frozen',
  );
}

String _sendCash(MockCashLedger ledger, int amount, {int minute = 0}) {
  return ledger
      .createPendingTransfer(
        senderId: _me,
        recipientId: 'DR-003',
        amountEgp: amount,
        createdAt: _at.add(Duration(minutes: minute)),
      )
      .id;
}

String _withdraw(MockCashLedger ledger, int amount, {int minute = 0}) {
  return ledger
      .submitWithdraw(
        driverId: _me,
        amountEgp: amount,
        createdAt: _at.add(Duration(minutes: minute)),
      )
      .id;
}

void main() {
  group('Send Cash reservation', () {
    test('pending deducts the ledger and freezes the amount', () {
      final ledger = _ledger();
      _sendCash(ledger, 300);

      expect(ledger.balanceOf(_me), 1900);
      _expectSummary(ledger, total: 2200, available: 1900, frozen: 300);
    });

    test('approval removes it from Total and Frozen without re-deducting', () {
      final ledger = _ledger();
      final id = _sendCash(ledger, 300);
      ledger.approve(id, finalizedAt: _at.add(const Duration(hours: 1)));

      expect(ledger.balanceOf(_me), 1900);
      _expectSummary(ledger, total: 1900, available: 1900, frozen: 0);
    });

    test('rejection refunds exactly once', () {
      final ledger = _ledger();
      final id = _sendCash(ledger, 300);
      ledger.reject(id, finalizedAt: _at.add(const Duration(hours: 1)));

      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
      expect(
        () => ledger.reject(id),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      expect(
        () => ledger.approve(id),
        throwsA(isA<TransferAlreadyFinalizedException>()),
      );
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
    });
  });

  group('Withdraw reservation', () {
    test('pending deducts the ledger and freezes the amount', () {
      final ledger = _ledger();
      final id = _withdraw(ledger, 200);

      expect(ledger.balanceOf(_me), 2000);
      final request = ledger.cashRequests.singleWhere((r) => r.id == id);
      expect(request.status, CashRequestStatus.pending);
      expect(request.balanceBeforeEgp, 2200);
      expect(request.balanceAfterEgp, 2000);
      _expectSummary(ledger, total: 2200, available: 2000, frozen: 200);
    });

    test('approval removes it from Total without a second deduction', () {
      final ledger = _ledger();
      final id = _withdraw(ledger, 200);
      final approved = ledger.approveCashRequest(
        id,
        processedAt: _at.add(const Duration(hours: 1)),
      );

      expect(approved.status, CashRequestStatus.approved);
      expect(approved.balanceBeforeEgp, 2200);
      expect(approved.balanceAfterEgp, 2000);
      expect(ledger.balanceOf(_me), 2000);
      expect(ledger.transactions, hasLength(1));
      _expectSummary(ledger, total: 2000, available: 2000, frozen: 0);
    });

    test('rejection refunds exactly once', () {
      final ledger = _ledger();
      final id = _withdraw(ledger, 200);
      ledger.rejectCashRequest(
        id,
        processedAt: _at.add(const Duration(hours: 1)),
      );

      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
      expect(
        () => ledger.rejectCashRequest(id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(
        () => ledger.approveCashRequest(id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(ledger.transactions, isEmpty);
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
    });

    test('repeated approval does not deduct again', () {
      final ledger = _ledger();
      final id = _withdraw(ledger, 200);
      ledger.approveCashRequest(id);

      expect(
        () => ledger.approveCashRequest(id),
        throwsA(isA<CashRequestAlreadyFinalizedException>()),
      );
      expect(ledger.transactions, hasLength(1));
      _expectSummary(ledger, total: 2000, available: 2000, frozen: 0);
    });
  });

  group('combined scenarios from 2,200 EGP', () {
    late MockCashLedger ledger;
    late String sendId;
    late String withdrawId;

    setUp(() {
      ledger = _ledger();
      sendId = _sendCash(ledger, 300);
      withdrawId = _withdraw(ledger, 200, minute: 1);
    });

    test('scenario 1: Send Cash 300 + Withdraw 200 pending', () {
      _expectSummary(ledger, total: 2200, available: 1700, frozen: 500);
    });

    test('scenario 2: approve Send Cash', () {
      ledger.approve(sendId);
      _expectSummary(ledger, total: 1900, available: 1700, frozen: 200);
    });

    test('scenario 3: reject Send Cash', () {
      ledger.reject(sendId);
      _expectSummary(ledger, total: 2200, available: 2000, frozen: 200);
    });

    test('approving both leaves nothing frozen', () {
      ledger.approve(sendId);
      ledger.approveCashRequest(withdrawId);
      _expectSummary(ledger, total: 1700, available: 1700, frozen: 0);
    });

    test('rejecting both restores everything once', () {
      ledger.reject(sendId);
      ledger.rejectCashRequest(withdrawId);
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
    });
  });

  group('validation', () {
    test('multiple pending reservations accumulate', () {
      final ledger = _ledger();
      _sendCash(ledger, 100);
      _sendCash(ledger, 150, minute: 1);
      _withdraw(ledger, 200, minute: 2);
      _withdraw(ledger, 250, minute: 3);

      expect(ledger.pendingSendCash(_me), 250);
      expect(ledger.reservedWithdraw(_me), 450);
      _expectSummary(ledger, total: 2200, available: 1500, frozen: 700);
    });

    test('reserved amounts cannot be spent again', () {
      final ledger = _ledger();
      _sendCash(ledger, 1500);
      _withdraw(ledger, 500, minute: 1);

      expect(
        () => _withdraw(ledger, 201, minute: 2),
        throwsA(isA<InsufficientWithdrawBalanceException>()),
      );
      expect(
        () => _sendCash(ledger, 201, minute: 3),
        throwsA(isA<InsufficientBalanceException>()),
      );
      _expectSummary(ledger, total: 2200, available: 200, frozen: 2000);

      _withdraw(ledger, 200, minute: 4);
      _expectSummary(ledger, total: 2200, available: 0, frozen: 2200);
      expect(ledger.availableBalance(_me), greaterThanOrEqualTo(0));
    });

    test('Request Cash capacity is unchanged by a pending Withdraw', () {
      final ledger = _ledger();
      expect(ledger.availableRequestCapacity(_me), 2800);
      final id = _withdraw(ledger, 200);
      expect(ledger.availableRequestCapacity(_me), 2800);
      ledger.rejectCashRequest(id);
      expect(ledger.availableRequestCapacity(_me), 2800);
    });
  });

  group('other operations are unchanged', () {
    test('Record Expense deducts immediately and is never frozen', () {
      final ledger = _ledger();
      ledger.createRecordedExpense(
        driverId: _me,
        tripId: 'trip-2026-0927',
        settlementType: SettlementType.fuel,
        amountEgp: 300,
        notes: null,
        attachments: const [],
        createdAt: _at,
        tripScope: ExpenseTripScope.anyTrip,
      );
      _expectSummary(ledger, total: 1900, available: 1900, frozen: 0);
    });

    test('Request Cash does not move money until approved', () {
      final ledger = _ledger();
      final request = ledger.submitRequestCash(
        driverId: _me,
        amountEgp: 400,
        createdAt: _at,
      );
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
      ledger.approveCashRequest(request.id);
      _expectSummary(ledger, total: 2600, available: 2600, frozen: 0);
    });

    test('Request Cash rejection does not move money', () {
      final ledger = _ledger();
      final request = ledger.submitRequestCash(
        driverId: _me,
        amountEgp: 400,
        createdAt: _at,
      );
      ledger.rejectCashRequest(request.id);
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
    });

    test('incoming transfer credits only after approval', () {
      final ledger = _ledger();
      final incoming = ledger.createPendingTransfer(
        senderId: 'DR-004',
        recipientId: _me,
        amountEgp: 250,
        createdAt: _at,
      );
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
      ledger.approve(incoming.id);
      _expectSummary(ledger, total: 2450, available: 2450, frozen: 0);
    });

    test('vault receipt credits only after approval', () {
      final ledger = _ledger()..seedDriverApprovals();
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
      ledger.approveVaultReceipt('DSB-2025-0441');
      _expectSummary(ledger, total: 4200, available: 4200, frozen: 0);
    });

    test('road expense never moves money', () {
      final ledger = _ledger()..seedDriverApprovals();
      ledger.confirmRoadExpense('RE-2026-1041');
      _expectSummary(ledger, total: 2200, available: 2200, frozen: 0);
    });
  });

  group('SessionFinanceRepository', () {
    test('maps ledger reservations into the financial summary', () async {
      final ledger = _ledger();
      final repository = SessionFinanceRepository(
        const MockFinanceDataSource(),
        ledger,
      );
      _sendCash(ledger, 300);
      _withdraw(ledger, 200, minute: 1);

      final summary = await repository.getFinancialSummary();
      expect(summary.availableBalanceEgp, 1700);
      expect(summary.frozenBalanceEgp, 500);
      expect(summary.totalBalanceEgp, 2200);
      expect(summary.chargeEgp, 3200);
      expect(summary.maxLimitEgp, 5000);
    });

    test('total is derived so the invariant always holds', () {
      const summary = FinancialSummary(
        balanceEgp: 1700,
        frozenBalanceEgp: 500,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      );
      expect(
        summary.totalBalanceEgp,
        summary.availableBalanceEgp + summary.frozenBalanceEgp,
      );
    });
  });

  group('Home balance section', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('english shows total, available, and frozen balances', (
      tester,
    ) async {
      final ledger = await _pumpHome(tester);
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('Frozen Balance'), findsOneWidget);
      expect(_text(tester, 'home-total-balance'), '2,200 EGP');
      expect(_text(tester, 'home-balance'), '2,200 EGP');
      expect(_text(tester, 'home-frozen-balance'), '0 EGP');

      final sendId = _sendCash(ledger, 300);
      _withdraw(ledger, 200, minute: 1);
      await tester.pumpAndSettle();
      expect(_text(tester, 'home-total-balance'), '2,200 EGP');
      expect(_text(tester, 'home-balance'), '1,700 EGP');
      expect(_text(tester, 'home-frozen-balance'), '500 EGP');

      ledger.approve(sendId);
      await tester.pumpAndSettle();
      expect(_text(tester, 'home-total-balance'), '1,900 EGP');
      expect(_text(tester, 'home-balance'), '1,700 EGP');
      expect(_text(tester, 'home-frozen-balance'), '200 EGP');

      expect(_text(tester, 'home-charge'), '3,200 EGP');
      expect(_text(tester, 'home-max-limit'), '5,000 EGP');
      expect(_text(tester, 'home-remaining'), '1,800 EGP');
    });

    testWidgets('arabic labels and amounts are localized', (tester) async {
      final ledger = await _pumpHome(tester, locale: const Locale('ar'));
      _sendCash(ledger, 300);
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الرصيد'), findsOneWidget);
      expect(find.text('الرصيد المتاح'), findsOneWidget);
      expect(find.text('الرصيد المجمّد'), findsOneWidget);
      expect(_text(tester, 'home-frozen-balance'), contains('ج.م'));
      expect(
        Directionality.of(tester.element(find.text('الرصيد المجمّد'))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a narrow screen with large text does not overflow', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(320, 1400),
        textScale: 1.6,
        configureLedger: (ledger) {
          _sendCash(ledger, 1234);
          _withdraw(ledger, 567, minute: 1);
        },
      );
      expect(_text(tester, 'home-frozen-balance'), '1,801 EGP');
      expect(tester.takeException(), isNull);
    });
  });
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Future<MockCashLedger> _pumpHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(400, 2400),
  double textScale = 1,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  await tester.binding.setSurfaceSize(size);
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
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
  return captured!;
}
