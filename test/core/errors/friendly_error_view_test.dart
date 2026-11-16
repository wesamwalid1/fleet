import 'package:driver_portal_app/core/errors/friendly_error_view.dart';
import 'package:driver_portal_app/core/theme/app_theme.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ErrorWidgetBuilder previousBuilder;
  late FlutterExceptionHandler? previousOnError;
  late bool Function(Object, StackTrace)? previousPlatformOnError;

  setUp(() {
    previousBuilder = ErrorWidget.builder;
    previousOnError = FlutterError.onError;
    previousPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    ErrorWidget.builder = previousBuilder;
    FlutterError.onError = previousOnError;
    PlatformDispatcher.instance.onError = previousPlatformOnError;
  });

  FlutterErrorDetails details() {
    return FlutterErrorDetails(
      exception: StateError('secret-exception-do-not-leak'),
      stack: StackTrace.fromString('#0 secret-stack-frame\n'),
      library: 'test library',
    );
  }

  Widget app({
    required Widget home,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
    Size? surface,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            size: surface ?? media.size,
          ),
          child: child!,
        );
      },
      home: home,
    );
  }

  testWidgets('renders without throwing', (tester) async {
    await tester.pumpWidget(
      app(home: Scaffold(body: FriendlyErrorView(details: details()))),
    );
    expect(find.byType(FriendlyErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('english localization', (tester) async {
    await tester.pumpWidget(
      app(home: Scaffold(body: FriendlyErrorView(details: details()))),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text("This section couldn't be shown."), findsOneWidget);
  });

  testWidgets('arabic localization and RTL', (tester) async {
    await tester.pumpWidget(
      app(
        locale: const Locale('ar'),
        home: Scaffold(body: FriendlyErrorView(details: details())),
      ),
    );
    expect(find.text('حدث خطأ ما'), findsOneWidget);
    expect(find.text('تعذر عرض هذا الجزء.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(FriendlyErrorView))),
      TextDirection.rtl,
    );
  });

  testWidgets('light and dark theme paint without throwing', (tester) async {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        app(
          themeMode: mode,
          home: Scaffold(body: FriendlyErrorView(details: details())),
        ),
      );
      expect(find.byType(FriendlyErrorView), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('large text scale 1.6 does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        textScale: 1.6,
        home: Scaffold(body: FriendlyErrorView(details: details())),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FriendlyErrorView), findsOneWidget);
  });

  testWidgets('compact layout fits tiny constraints', (tester) async {
    await tester.pumpWidget(
      app(
        home: const Scaffold(
          body: SizedBox(
            width: 96,
            height: 48,
            child: FriendlyErrorView(
              details: FlutterErrorDetails(exception: 'x'),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FriendlyErrorView), findsOneWidget);
    // Compact mode shows title only (no hint).
    expect(find.text("This section couldn't be shown."), findsNothing);
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('does not leak exception or stack into the UI', (tester) async {
    await tester.pumpWidget(
      app(home: Scaffold(body: FriendlyErrorView(details: details()))),
    );
    expect(find.textContaining('secret-exception'), findsNothing);
    expect(find.textContaining('secret-stack'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });

  testWidgets('renders with English literals when l10n is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FriendlyErrorView(details: details()),
      ),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text("This section couldn't be shown."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('install debug path keeps default ErrorWidget', (tester) async {
    expect(kDebugMode, isTrue);
    // Must restore inside the test body: the binding checks ErrorWidget.builder
    // after the test callback returns and before package tearDown.
    final restoredBuilder = previousBuilder;
    try {
      installFriendlyErrorWidget();

      await tester.pumpWidget(
        app(home: const Scaffold(body: _ThrowingChild())),
      );
      await tester.pump();

      expect(find.byType(FriendlyErrorView), findsNothing);
      expect(tester.takeException(), isNotNull);
    } finally {
      ErrorWidget.builder = restoredBuilder;
    }
  });

  testWidgets(
    'install forceFriendly shows FriendlyErrorView; reporting stays observable',
    (tester) async {
      final onErrorBefore = FlutterError.onError;
      final platformBefore = PlatformDispatcher.instance.onError;
      final restoredBuilder = previousBuilder;

      try {
        installFriendlyErrorWidget(forceFriendly: true);

        expect(identical(FlutterError.onError, onErrorBefore), isTrue);
        expect(
          identical(PlatformDispatcher.instance.onError, platformBefore),
          isTrue,
        );

        await tester.pumpWidget(
          app(home: const Scaffold(body: _ThrowingChild())),
        );
        await tester.pump();

        expect(find.byType(FriendlyErrorView), findsOneWidget);
        expect(find.textContaining('deliberate-build-failure'), findsNothing);
        // Framework still reports the build error to the test binding.
        expect(tester.takeException(), isNotNull);
      } finally {
        ErrorWidget.builder = restoredBuilder;
      }
    },
  );

  test('install does not replace FlutterError.onError or platform onError', () {
    final onErrorBefore = FlutterError.onError;
    final platformBefore = PlatformDispatcher.instance.onError;
    final restoredBuilder = previousBuilder;

    try {
      installFriendlyErrorWidget();
      installFriendlyErrorWidget(forceFriendly: true);
      installFriendlyErrorWidget(forceFriendly: false);

      expect(identical(FlutterError.onError, onErrorBefore), isTrue);
      expect(
        identical(PlatformDispatcher.instance.onError, platformBefore),
        isTrue,
      );
    } finally {
      ErrorWidget.builder = restoredBuilder;
    }
  });
}

class _ThrowingChild extends StatelessWidget {
  const _ThrowingChild();

  @override
  Widget build(BuildContext context) {
    throw StateError('deliberate-build-failure');
  }
}
