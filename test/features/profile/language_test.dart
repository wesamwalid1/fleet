import 'package:driver_portal_app/core/locale/domain/locale_repository.dart';
import 'package:driver_portal_app/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:driver_portal_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'the language sheet marks the active language and switches immediately',
    (tester) async {
      final repository = _MemoryLocaleRepository();
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(DriverPortalApp(localeRepository: repository));
      await tester.pumpAndSettle();
      await _login(tester);
      await tester.tap(find.byKey(const Key('nav-profile')));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('profile-name'))),
        ),
        TextDirection.ltr,
      );

      await tester.tap(find.byKey(const Key('profile-language')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Choose Language'), findsOneWidget);
      expect(_check(const Key('language-option-en')), findsOneWidget);
      expect(_check(const Key('language-option-ar')), findsNothing);

      await tester.tap(find.byKey(const Key('language-option-ar')));
      await tester.pumpAndSettle();

      expect(find.text('Choose Language'), findsNothing);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('اللغة'), findsOneWidget);
      expect(find.text('رصيدي'), findsOneWidget);
      expect(find.byTooltip('الرئيسية'), findsOneWidget);
      expect(repository.saved, const Locale('ar'));
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('profile-name'))),
        ),
        TextDirection.rtl,
      );

      await tester.tap(find.byKey(const Key('profile-language')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_check(const Key('language-option-ar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('language-option-en')));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(repository.saved, const Locale('en'));
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('profile-name'))),
        ),
        TextDirection.ltr,
      );
    },
  );

  testWidgets('a saved locale is restored on startup', (tester) async {
    final repository = _MemoryLocaleRepository(const Locale('ar'));
    await tester.pumpWidget(DriverPortalApp(localeRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بعودتك!'), findsOneWidget);
    expect(find.text('Welcome back!'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('مرحباً بعودتك!'))),
      TextDirection.rtl,
    );
  });

  testWidgets('no saved locale keeps an explicit app locale', (tester) async {
    await tester.pumpWidget(
      DriverPortalApp(
        locale: const Locale('ar'),
        localeRepository: _MemoryLocaleRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بعودتك!'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('مرحباً بعودتك!'))),
      TextDirection.rtl,
    );
  });
}

Finder _check(Key optionKey) {
  return find.descendant(
    of: find.byKey(optionKey),
    matching: find.byIcon(Icons.check_rounded),
  );
}

Future<void> _login(WidgetTester tester) async {
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
}

class _MemoryLocaleRepository implements LocaleRepository {
  Locale? saved;

  _MemoryLocaleRepository([this.saved]);

  @override
  Future<Locale?> read() async => saved;

  @override
  Future<void> save(Locale locale) async {
    saved = locale;
  }
}
