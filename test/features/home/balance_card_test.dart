import 'dart:async';

import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/reveal_finance.dart';

void main() {
  testWidgets('shows the header and the calculated wallet figures', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await revealHomeFinance(tester);

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('AA'), findsOneWidget);
    expect(find.text('Available Balance'), findsOneWidget);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(find.text('Charge'), findsOneWidget);
    expect(_text(tester, 'home-charge'), '3,200 EGP');
    expect(find.text('Remaining Limit'), findsOneWidget);
    expect(_text(tester, 'home-remaining'), '1,800 EGP');
    expect(find.text('Max Limit'), findsOneWidget);
    expect(_text(tester, 'home-max-limit'), '5,000 EGP');
    expect(find.text('Send Cash'), findsOneWidget);
    expect(find.text('Record Expense'), findsNWidgets(2));
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);

    final pending = find.byKey(const Key('home-pending-card'));
    expect(
      find.descendant(of: pending, matching: find.text('Received from Vault')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: pending,
        matching: find.text('Received from Khaled Ramadan'),
      ),
      findsOneWidget,
    );
    // Home shows only the two newest pending rows; road expense is third.
    expect(
      find.descendant(
        of: pending,
        matching: find.text('Road Expense Approval'),
      ),
      findsNothing,
    );

    final recent = find.byKey(const Key('home-recent-card'));
    expect(
      find.descendant(of: recent, matching: find.text('Drivers Vault')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: recent,
        matching: find.text('Awaiting your approval'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: recent,
        matching: find.text('Pending — from Khaled Ramadan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recent, matching: find.text('Road Expense Approval')),
      findsOneWidget,
    );
    expect(
      tester.getCenter(find.text('Remaining Limit')).dx,
      lessThan(tester.getCenter(find.text('Max Limit')).dx),
    );
  });

  testWidgets('arabic wallet figures are right to left', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('الرصيد المتاح'), findsOneWidget);
    expect(find.text('العهدة'), findsOneWidget);
    expect(find.text('الحد المتبقي'), findsOneWidget);
    expect(find.text('الحد الأقصى'), findsOneWidget);
    expect(_text(tester, 'home-balance'), contains('ج.م'));
    expect(find.text('Send Cash'), findsNothing);
    expect(find.text('Record Expense'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('الرصيد المتاح'))),
      TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.text('الحد المتبقي')).dx,
      greaterThan(tester.getCenter(find.text('الحد الأقصى')).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the header and shows a placeholder while balance loads', (
    tester,
  ) async {
    final finance = _PendingFinanceRepository();
    await tester.pumpWidget(_app(financeRepository: finance));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    // Skeleton mirrors the finance card: label, total, available + frozen.
    final loading = find.byKey(const Key('balance-loading'));
    expect(
      find.descendant(of: loading, matching: find.byType(DecoratedBox)),
      findsWidgets,
    );
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(find.text('Available Balance'), findsNothing);

    finance.complete(
      const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await tester.pumpAndSettle();
    await revealHomeFinance(tester);

    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(find.byKey(const Key('balance-loading')), findsNothing);
  });

  testWidgets('a balance failure keeps the header and hides totals', (
    tester,
  ) async {
    final finance = _FailingFinanceRepository();
    await tester.pumpWidget(_app(financeRepository: finance));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Unable to load your balance.'), findsOneWidget);
    expect(find.text('Unable to load your profile.'), findsNothing);
    expect(find.byKey(const Key('home-balance')), findsNothing);
    expect(find.byKey(const Key('home-charge')), findsNothing);
    expect(find.byKey(const Key('home-max-limit')), findsNothing);

    await tester.tap(find.byKey(const Key('balance-retry')));
    await tester.pumpAndSettle();
    await revealHomeFinance(tester);

    expect(finance.calls, 2);
    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(find.text('Ahmed Ali'), findsOneWidget);
  });

  testWidgets('a narrow screen with large text does not overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    await revealHomeFinance(tester);

    expect(_text(tester, 'home-balance'), '2,200 EGP');
    expect(tester.takeException(), isNull);
  });
}

String _text(WidgetTester tester, String key) {
  final text = tester.widget<Text>(find.byKey(Key(key)));
  return text.data ?? text.textSpan!.toPlainText();
}

Widget _app({
  Locale? locale,
  FinanceRepository? financeRepository,
  Widget Function(BuildContext, Widget?)? builder,
}) {
  return MaterialApp(
    locale: locale ?? const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: builder,
    home: HomeScope(
      financeRepository: financeRepository,
      now: () => DateTime(2026, 10, 20, 9),
    ),
  );
}

class _PendingFinanceRepository implements FinanceRepository {
  final Completer<FinancialSummary> _completer = Completer<FinancialSummary>();

  @override
  Stream<void> get changes => const Stream.empty();

  void complete(FinancialSummary summary) {
    _completer.complete(summary);
  }

  @override
  Future<FinancialSummary> getFinancialSummary() => _completer.future;
}

class _FailingFinanceRepository implements FinanceRepository {
  int calls = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<FinancialSummary> getFinancialSummary() async {
    calls += 1;
    if (calls == 1) throw Exception('balance unavailable');
    return const FinancialSummary(
      balanceEgp: 2200,
      chargeEgp: 3200,
      maxLimitEgp: 5000,
    );
  }
}
