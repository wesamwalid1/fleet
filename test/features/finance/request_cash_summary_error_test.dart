import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/features/finance/data/repositories/cash_request_repository_impl.dart';
import 'package:driver_portal_app/features/finance/domain/entities/cash_request_result.dart';
import 'package:driver_portal_app/features/finance/domain/usecases/request_cash.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_bloc.dart';
import 'package:driver_portal_app/features/finance/presentation/bloc/request_cash_event.dart';
import 'package:driver_portal_app/features/finance/presentation/widgets/request_cash_sheet.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = MockCashLedger.senderId;
const _valueKeys = [
  'request-cash-total-balance',
  'request-cash-max-limit',
  'request-cash-pending',
  'request-cash-capacity',
];

void main() {
  testWidgets('a failed summary shows no zero values and blocks submit', (
    tester,
  ) async {
    await _pumpSheet(tester, failures: 1);

    for (final key in _valueKeys) {
      expect(_text(tester, key), '—', reason: key);
    }
    expect(find.text('0 EGP'), findsNothing);
    expect(
      find.text('Unable to load your request cash details.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(_canSubmit(tester), isFalse);

    await tester.enterText(find.byKey(const Key('request-cash-amount')), '500');
    await tester.pump();
    expect(_canSubmit(tester), isFalse);
    expect(
      find.text('Amount exceeds your available request capacity'),
      findsNothing,
    );
    expect(
      find.text('Unable to load your request cash details.'),
      findsOneWidget,
    );
  });

  testWidgets('retry loads the actual values and restores validation', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester, failures: 1);

    await tester.tap(find.byKey(const Key('request-cash-retry')));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(_text(tester, 'request-cash-total-balance'), '2,200 EGP');
    expect(_text(tester, 'request-cash-max-limit'), '5,000 EGP');
    expect(_text(tester, 'request-cash-pending'), '0 EGP');
    expect(_text(tester, 'request-cash-capacity'), '2,800 EGP');
    expect(find.byKey(const Key('request-cash-summary-error')), findsNothing);
    expect(find.byKey(const Key('request-cash-retry')), findsNothing);

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
  });

  testWidgets('a successful first load shows values without an error', (
    tester,
  ) async {
    await _pumpSheet(tester, failures: 0);

    expect(_text(tester, 'request-cash-total-balance'), '2,200 EGP');
    expect(_text(tester, 'request-cash-max-limit'), '5,000 EGP');
    expect(_text(tester, 'request-cash-pending'), '0 EGP');
    expect(_text(tester, 'request-cash-capacity'), '2,800 EGP');
    expect(find.byKey(const Key('request-cash-summary-error')), findsNothing);
  });

  testWidgets('arabic error presentation is localized and right to left', (
    tester,
  ) async {
    await _pumpSheet(tester, failures: 1, locale: const Locale('ar'));

    expect(find.text('تعذر تحميل بيانات طلب النقد.'), findsOneWidget);
    expect(find.text('حاول مرة أخرى'), findsOneWidget);
    for (final key in _valueKeys) {
      expect(_text(tester, key), '—', reason: key);
    }
    expect(
      Directionality.of(
        tester.element(find.text('تعذر تحميل بيانات طلب النقد.')),
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
          .widget<FilledButton>(find.byKey(const Key('request-cash-submit')))
          .onPressed !=
      null;
}

Future<_FlakyRepository> _pumpSheet(
  WidgetTester tester, {
  required int failures,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repository = _FlakyRepository(
    MockCashLedger(senderBalanceEgp: 2200, maxLimitEgp: 5000),
    failures: failures,
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
      home: Scaffold(
        body: BlocProvider(
          create: (_) => RequestCashBloc(
            driverId: _me,
            requestCash: RequestCash(repository),
            repository: repository,
          )..add(const RequestCashStarted()),
          child: const RequestCashSheet(),
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
  int calls = 0;

  _FlakyRepository(super.ledger, {required this.failures});

  @override
  Future<RequestCashFormSummary> getRequestCashFormSummary(
    String driverId,
  ) async {
    calls += 1;
    if (failures > 0) {
      failures -= 1;
      throw Exception('summary unavailable');
    }
    return super.getRequestCashFormSummary(driverId);
  }
}
