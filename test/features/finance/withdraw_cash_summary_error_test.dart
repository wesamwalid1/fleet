import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request_result.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/withdraw_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/withdraw_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/withdraw_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/withdraw_cash_sheet.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = MockCashLedger.senderId;
const _error = 'Unable to load your withdrawal details.';
const _exceeds = 'Amount exceeds your available balance';

void main() {
  testWidgets('a failed summary shows no zero balance and blocks submit', (
    tester,
  ) async {
    await _pumpSheet(tester, failures: 1);

    expect(_text(tester, 'withdraw-available-balance'), '—');
    expect(_text(tester, 'withdraw-balance-after'), '—');
    expect(find.text('0 EGP'), findsNothing);
    expect(find.text(_error), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(_canSubmit(tester), isFalse);
  });

  testWidgets('an amount entered while unavailable stays blocked and quiet', (
    tester,
  ) async {
    await _pumpSheet(tester, failures: 1);

    await tester.enterText(find.byKey(const Key('withdraw-amount')), '500');
    await tester.pump();

    expect(_canSubmit(tester), isFalse);
    expect(find.text(_exceeds), findsNothing);
    expect(_text(tester, 'withdraw-balance-after'), '—');
    expect(find.text(_error), findsOneWidget);
  });

  testWidgets('retry restores the real balance and normal validation', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester, failures: 1);

    await tester.tap(find.byKey(const Key('withdraw-retry')));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(_text(tester, 'withdraw-available-balance'), '2,200 EGP');
    expect(_text(tester, 'withdraw-balance-after'), '2,200 EGP');
    expect(find.byKey(const Key('withdraw-summary-error')), findsNothing);
    expect(find.byKey(const Key('withdraw-retry')), findsNothing);

    await tester.enterText(find.byKey(const Key('withdraw-amount')), '2201');
    await tester.pump();
    expect(find.text(_exceeds), findsOneWidget);
    expect(_canSubmit(tester), isFalse);

    await tester.enterText(find.byKey(const Key('withdraw-amount')), '500');
    await tester.pump();
    expect(_text(tester, 'withdraw-balance-after'), '1,700 EGP');
    expect(_canSubmit(tester), isTrue);
  });

  testWidgets('retry shows loading and ignores rapid repeated taps', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester, failures: 1, delayed: true);

    final retry = find.byKey(const Key('withdraw-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('withdraw-retry')), findsNothing);

    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(_text(tester, 'withdraw-available-balance'), '2,200 EGP');
  });

  testWidgets('arabic error is localized, right to left, and fits', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      failures: 1,
      locale: const Locale('ar'),
      size: const Size(320, 1200),
      textScale: 1.6,
    );

    expect(find.text('تعذر تحميل بيانات التسليم.'), findsOneWidget);
    expect(find.text('حاول مرة أخرى'), findsOneWidget);
    expect(_text(tester, 'withdraw-available-balance'), '—');
    expect(
      Directionality.of(
        tester.element(find.text('تعذر تحميل بيانات التسليم.')),
      ),
      TextDirection.rtl,
    );
    expect(_canSubmit(tester), isFalse);
    expect(tester.takeException(), isNull);
  });
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

bool _canSubmit(WidgetTester tester) {
  return tester
          .widget<FilledButton>(find.byKey(const Key('withdraw-submit')))
          .onPressed !=
      null;
}

Future<_FlakyRepository> _pumpSheet(
  WidgetTester tester, {
  required int failures,
  bool delayed = false,
  Locale locale = const Locale('en'),
  Size size = const Size(400, 1200),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repository = _FlakyRepository(
    MockCashLedger(senderBalanceEgp: 2200),
    failures: failures,
    delayed: delayed,
  );
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
      home: Scaffold(
        body: BlocProvider(
          create: (_) => WithdrawCashBloc(
            driverId: _me,
            withdrawCash: WithdrawCash(repository),
            repository: repository,
          )..add(const WithdrawCashStarted()),
          child: const WithdrawCashSheet(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Fails the first [failures] summary loads, then reads the real ledger.
class _FlakyRepository extends CashRequestRepositoryImpl {
  int failures;
  final bool delayed;
  int calls = 0;

  _FlakyRepository(
    super.ledger, {
    required this.failures,
    this.delayed = false,
  });

  @override
  Future<WithdrawFormSummary> getWithdrawFormSummary(String driverId) async {
    calls += 1;
    if (delayed && calls > 1) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (failures > 0) {
      failures -= 1;
      throw Exception('summary unavailable');
    }
    return super.getWithdrawFormSummary(driverId);
  }
}
