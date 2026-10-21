import 'dart:async';

import 'package:driver_portal_app/features/home/domain/entities/financial_summary.dart';
import 'package:driver_portal_app/features/home/domain/repositories/finance_repository.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the header and the calculated balance card', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Good morning 👋'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('AA'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('3,200'), findsOneWidget);
    expect(find.text('3,200 EGP'), findsNothing);
    expect(find.text('Charge'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
    expect(find.text('Max Limit'), findsOneWidget);
    expect(find.text('Send Cash'), findsOneWidget);
    expect(find.text('Record Expense'), findsOneWidget);
    expect(find.text('Pending Approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('Received from Vault'), findsNWidgets(2));
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Sami Hassan'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Charge')).dx,
      lessThan(tester.getCenter(find.text('Max Limit')).dx),
    );
  });

  testWidgets('arabic balance card is right to left', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('الرصيد'), findsOneWidget);
    expect(find.text('العهدة'), findsOneWidget);
    expect(find.text('الحد الأقصى'), findsOneWidget);
    expect(find.text('ج.م'), findsNothing);
    expect(find.textContaining('ج.م'), findsNWidgets(8));
    expect(find.text('Send Cash'), findsNothing);
    expect(find.text('Record Expense'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('الرصيد'))),
      TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.text('العهدة')).dx,
      greaterThan(tester.getCenter(find.text('الحد الأقصى')).dx),
    );
  });

  testWidgets('keeps the header and shows a placeholder while balance loads', (
    tester,
  ) async {
    final finance = _PendingFinanceRepository();
    await tester.pumpWidget(_app(financeRepository: finance));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.byKey(const Key('balance-loading')), findsOneWidget);
    expect(find.text('2,200 EGP'), findsNothing);
    expect(find.text('Balance'), findsNothing);

    finance.complete(
      const FinancialSummary(
        balanceEgp: 2200,
        chargeEgp: 3200,
        maxLimitEgp: 5000,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2,200 EGP'), findsOneWidget);
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
    expect(find.text('2,200 EGP'), findsNothing);
    expect(find.text('3,200'), findsNothing);
    expect(find.text('5,000 EGP'), findsNothing);

    await tester.tap(find.byKey(const Key('balance-retry')));
    await tester.pumpAndSettle();

    expect(finance.calls, 2);
    expect(find.text('2,200 EGP'), findsOneWidget);
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

    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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

  void complete(FinancialSummary summary) {
    _completer.complete(summary);
  }

  @override
  Future<FinancialSummary> getFinancialSummary() => _completer.future;
}

class _FailingFinanceRepository implements FinanceRepository {
  int calls = 0;

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
