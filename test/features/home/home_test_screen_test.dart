import 'dart:async';

import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_request.dart';
import 'package:driver_portal_app/features/finance/domain/entities/expense_trip_scope.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/record_expense_bloc.dart';
import 'package:driver_portal_app/features/history/presentation/widgets/history_ledger_row.dart';
import 'package:driver_portal_app/features/home/domain/entities/driver.dart';
import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/driver_repository.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the login route opens the Home tab with its actions', (
    tester,
  ) async {
    _setView(tester);
    await tester.pumpWidget(testPortalApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-email')),
      MockAuthDataSource.email,
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      MockAuthDataSource.password,
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(MockAuthDataSource.delay);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-actions')),
        matching: find.byKey(const Key('send-cash')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sections show the existing finance, trip, and approval data', (
    tester,
  ) async {
    await _pump(tester);

    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(_text(tester, 'home-remaining'), '1,800 EGP');
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
    expect(find.byKey(const Key('home-expenses')), findsNothing);
    expect(find.byKey(const Key('home-sample-tag')), findsNothing);
    expect(find.text('Expense Overview'), findsNothing);
    expect(find.text('Sample data'), findsNothing);

    final tripSection = find.byKey(const Key('home-trip-card'));
    final record = find.descendant(
      of: tripSection,
      matching: find.byKey(const Key('trip-record-expense')),
    );
    expect(record, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(record).onPressed, isNotNull);
    expect(
      tester.getRect(record).top,
      greaterThan(
        tester.getRect(find.byKey(const Key('home-trip-details'))).bottom,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-finance-card')),
        matching: find.byKey(const Key('trip-record-expense')),
      ),
      findsNothing,
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('home-charge-progress')),
    );
    expect(progress.value, closeTo(0.64, 0.001));
    expect(progress.semanticsLabel, '64% of limit used');

    expect(
      find.descendant(
        of: find.byKey(const Key('home-trip-code')),
        matching: find.text('TR-2026-0927'),
      ),
      findsOneWidget,
    );
    expect(_text(tester, 'home-trip-origin'), 'Suez');
    expect(_text(tester, 'home-trip-destination'), 'Cairo');
    expect(find.byKey(const Key('home-no-trip')), findsNothing);

    expect(find.text('3 pending'), findsOneWidget);
    expect(find.byKey(const Key('home-pending-DSB-2025-0441')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-TRF-2025-0123')), findsOneWidget);
    expect(find.byKey(const Key('home-pending-RE-2026-1041')), findsNothing);

    expect(find.text('Recent Transactions'), findsOneWidget);
    final recent = find.byKey(const Key('home-recent-card'));
    expect(
      find.descendant(of: recent, matching: find.text('-300 EGP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recent, matching: find.text('Road Expense Approval')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: recent,
        matching: find.text('Pending — from Khaled Ramadan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recent, matching: find.byType(HistoryLedgerRow)),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('active trip record expense is bound to the active trip', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('home-trip-card')),
        matching: find.byKey(const Key('trip-record-expense')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expense-close')), findsOneWidget);
    expect(find.byKey(const Key('expense-trip')), findsNothing);
    expect(find.text('Select Trip'), findsNothing);
    expect(_expenseBloc(tester).state.tripId, 'trip-2026-0927');
    expect(_expenseBloc(tester).tripScope, ExpenseTripScope.activeTrip);

    await tester.tap(find.byKey(const Key('expense-settlement')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount')), '300');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Expense Recorded'), findsOneWidget);
    final expense = ledger.expenses.single;
    expect(expense.tripId, 'trip-2026-0927');
    expect(expense.status, ExpenseStatus.recorded);
    expect(ledger.balanceOf('DR-001'), 1900);
  });

  testWidgets('the general record expense records against a completed trip', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);
    final actions = find.byKey(const Key('home-actions'));
    expect(
      find.descendant(of: actions, matching: find.text('Actions')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-actions-panel')), findsOneWidget);
    final record = find.descendant(
      of: actions,
      matching: find.byKey(const Key('record-expense')),
    );
    final send = find.descendant(
      of: actions,
      matching: find.byKey(const Key('send-cash')),
    );
    final request = find.descendant(
      of: actions,
      matching: find.byKey(const Key('request-cash')),
    );
    final withdraw = find.descendant(
      of: actions,
      matching: find.byKey(const Key('withdraw')),
    );
    expect(record, findsOneWidget);
    expect(send, findsOneWidget);
    expect(request, findsOneWidget);
    expect(withdraw, findsOneWidget);
    expect(tester.getRect(record).top, tester.getRect(send).top);
    expect(tester.getRect(request).top, tester.getRect(withdraw).top);
    expect(
      tester.getRect(request).top,
      greaterThan(tester.getRect(send).bottom),
    );
    expect(
      tester.getRect(actions).top,
      greaterThan(
        tester.getRect(find.byKey(const Key('home-trip-card'))).bottom,
      ),
    );

    await tester.tap(record);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expense-trip')), findsOneWidget);
    final bloc = _expenseBloc(tester);
    expect(bloc.state.tripId, isNull);
    expect(bloc.state.trips, hasLength(6));

    await tester.tap(find.byKey(const Key('expense-trip')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'expense-trip-locked-',
            ),
      ),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const Key('expense-trip-trip-2026-0904')),
    );
    await tester.tap(find.byKey(const Key('expense-trip-trip-2026-0904')));
    await tester.pumpAndSettle();
    expect(bloc.state.tripId, 'trip-2026-0904');
    expect(find.byKey(const Key('expense-trip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('expense-settlement')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-settlement-fuel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount')), '100');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('expense-submit')));
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Expense Recorded'), findsOneWidget);
    final expense = ledger.expenses.single;
    expect(expense.tripId, 'trip-2026-0904');
    expect(expense.status, ExpenseStatus.recorded);
    expect(ledger.balanceOf('DR-001'), 2100);
  });

  testWidgets('request cash and withdraw open real sheets', (tester) async {
    late MockCashLedger ledger;
    await _pump(tester, configureLedger: (value) => ledger = value);
    final balanceBefore = ledger.balanceOf('DR-001');

    await tester.ensureVisible(find.byKey(const Key('request-cash')));
    await tester.tap(find.byKey(const Key('request-cash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request-cash-amount')), findsOneWidget);
    expect(find.byKey(const Key('request-cash-submit')), findsOneWidget);
    expect(ledger.balanceOf('DR-001'), balanceBefore);
    await tester.tap(find.byKey(const Key('request-cash-cancel')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('withdraw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('withdraw-amount')), findsOneWidget);
    expect(find.byKey(const Key('withdraw-submit')), findsOneWidget);
    expect(ledger.balanceOf('DR-001'), balanceBefore);
  });

  testWidgets('send cash is in the actions row and opens the real sheet', (
    tester,
  ) async {
    await _pump(tester);
    final send = find.byKey(const Key('send-cash'));

    expect(send, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-trip-card')),
        matching: send,
      ),
      findsNothing,
    );
    expect(
      tester.getRect(send).top,
      greaterThan(
        tester.getRect(find.byKey(const Key('home-trip-card'))).bottom,
      ),
    );

    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('send-cash-driver')), findsOneWidget);
    expect(find.byKey(const Key('send-cash-amount')), findsOneWidget);
  });

  testWidgets('header and section links use the existing tabs', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('home-view-all-approvals')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pending-count')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-recent-see-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-header')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-page')), findsOneWidget);
  });

  testWidgets('header greets the driver and keeps bell and avatar behavior', (
    tester,
  ) async {
    await _pump(tester);

    expect(_text(tester, 'home-welcome'), 'Welcome back!');
    expect(_text(tester, 'home-driver-name'), 'Ahmed Ali');
    expect(find.text('Good morning 👋'), findsNothing);
    expect(find.byKey(const Key('home-notification-dot')), findsOneWidget);

    final avatar = tester.getRect(find.byKey(const Key('home-avatar')));
    final identity = tester.getRect(
      find.byKey(const Key('home-header-identity')),
    );
    final bell = tester.getRect(find.byKey(const Key('home-notifications')));
    expect(avatar.right, lessThanOrEqualTo(identity.left));
    expect(bell.left, greaterThanOrEqualTo(identity.right));

    await tester.tap(find.byKey(const Key('home-notifications')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-page')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
  });

  testWidgets('arabic header mirrors with the localized welcome', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('ar'),
      size: const Size(320, 2400),
    );

    expect(_text(tester, 'home-welcome'), 'مرحباً بعودتك!');
    final avatar = tester.getRect(find.byKey(const Key('home-avatar')));
    final identity = tester.getRect(
      find.byKey(const Key('home-header-identity')),
    );
    final bell = tester.getRect(find.byKey(const Key('home-notifications')));
    expect(avatar.left, greaterThanOrEqualTo(identity.right));
    expect(bell.right, lessThanOrEqualTo(identity.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no pending approvals keeps the card without a badge', (
    tester,
  ) async {
    await _pump(tester, seedApprovals: false);

    expect(find.byKey(const Key('home-pending-card')), findsOneWidget);
    expect(find.byKey(const Key('home-all-caught-up')), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.byKey(const Key('home-pending-count')), findsNothing);
    expect(find.byKey(const Key('home-notification-dot')), findsNothing);
    expect(find.byKey(const Key('home-view-all-approvals')), findsNothing);
  });

  testWidgets('a driver without an active trip cannot record an expense', (
    tester,
  ) async {
    await _pump(tester, repository: const _DriverWithoutTrips());

    expect(find.byKey(const Key('home-no-trip')), findsOneWidget);
    expect(find.text('No Active Trip'), findsOneWidget);
    final record = find.descendant(
      of: find.byKey(const Key('home-trip-card')),
      matching: find.byKey(const Key('trip-record-expense')),
    );
    expect(record, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(record).onPressed, isNull);
    expect(
      find.descendant(
        of: record,
        matching: find.byIcon(Icons.lock_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: record, matching: find.text('Record Expense')),
      findsOneWidget,
    );

    await tester.tap(record, warnIfMissed: false);
    await tester.pump();
    expect(find.byKey(const Key('expense-close')), findsNothing);

    final general = find.byKey(const Key('record-expense'));
    expect(tester.widget<ButtonStyleButton>(general).onPressed, isNotNull);
  });

  testWidgets('arabic uses localized labels and a right-to-left layout', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('ar'),
      size: const Size(320, 2400),
    );

    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('home-finance-card'))),
      ),
      TextDirection.rtl,
    );
    expect(find.text('الرصيد المتاح'), findsOneWidget);
    expect(find.text('الرحلة النشطة'), findsOneWidget);
    expect(find.text('الإجراءات'), findsOneWidget);
    expect(find.text('أحدث الحركات'), findsOneWidget);
    expect(find.text('Available Balance'), findsNothing);
    expect(find.text('بيانات تجريبية'), findsNothing);

    final card = tester.getRect(find.byKey(const Key('home-finance-card')));
    final remaining = tester.getRect(find.byKey(const Key('home-remaining')));
    final max = tester.getRect(find.byKey(const Key('home-max-limit')));
    expect(remaining.center.dx, greaterThan(card.center.dx));
    expect(max.center.dx, lessThan(card.center.dx));

    final origin = tester.getRect(find.byKey(const Key('home-trip-origin')));
    final arrow = tester.getRect(find.byKey(const Key('home-trip-arrow')));
    final destination = tester.getRect(
      find.byKey(const Key('home-trip-destination')),
    );
    expect(origin.left, greaterThan(arrow.right));
    expect(arrow.left, greaterThan(destination.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow screen with large text does not overflow', (
    tester,
  ) async {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await _pump(
        tester,
        locale: locale,
        size: const Size(320, 3200),
        textScale: 1.6,
      );
      expect(find.byKey(const Key('home-finance-card')), findsOneWidget);
      expect(find.byKey(const Key('trip-record-expense')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the finance card shows the loading placeholder first', (
    tester,
  ) async {
    final pending = Completer<FinancialSummary>();
    _setView(tester);
    await tester.pumpWidget(
      _app(
        HomeScope(
          now: () => DateTime(2026, 10, 20, 9),
          financeRepository: _PendingFinance(pending.future),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.byKey(const Key('home-finance-card')), findsNothing);

    pending.complete(
      const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('balance-loading')), findsNothing);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
  });
}

class _PendingFinance implements FinanceRepository {
  final Future<FinancialSummary> summary;

  const _PendingFinance(this.summary);

  @override
  Future<FinancialSummary> getFinancialSummary() => summary;

  @override
  Stream<void> get changes => const Stream.empty();
}

class _DriverWithoutTrips implements DriverRepository {
  const _DriverWithoutTrips();

  @override
  Future<Driver> getCurrentDriver() async {
    return const Driver(
      id: 'DR-002',
      fullName: LocalizedString(en: 'Mohamed Said', ar: 'محمد سعيد'),
    );
  }
}

void _setView(WidgetTester tester, [Size size = const Size(400, 2400)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(400, 2400),
  double textScale = 1,
  bool seedApprovals = true,
  DriverRepository? repository,
  void Function(MockCashLedger ledger)? configureLedger,
}) async {
  _setView(tester, size);
  await tester.pumpWidget(
    _app(
      HomeScope(
        key: ValueKey(locale),
        now: () => DateTime(2026, 10, 20, 9),
        seedApprovals: seedApprovals,
        repository: repository,
        configureLedger: configureLedger,
      ),
      locale: locale,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _app(
  Widget home, {
  Locale locale = const Locale('en'),
  double textScale = 1,
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
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

RecordExpenseBloc _expenseBloc(WidgetTester tester) {
  return BlocProvider.of<RecordExpenseBloc>(
    tester.element(find.byKey(const Key('expense-amount'))),
  );
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}
