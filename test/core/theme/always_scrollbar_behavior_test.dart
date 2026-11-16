import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/always_scrollbar_behavior.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const behavior = AlwaysScrollbarBehavior();

  Widget wrap(Widget child) {
    return MaterialApp(
      scrollBehavior: behavior,
      home: Scaffold(body: child),
    );
  }

  ScrollableDetails details({
    required AxisDirection direction,
    ScrollController? controller,
  }) {
    return ScrollableDetails(direction: direction, controller: controller);
  }

  testWidgets('vertical AxisDirection.down gets a Scrollbar', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const child = SizedBox(key: Key('content'));

    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = behavior.buildScrollbar(
            context,
            child,
            details(direction: AxisDirection.down, controller: controller),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(built, isA<Scrollbar>());
    final bar = built as Scrollbar;
    expect(identical(bar.controller, controller), isTrue);
    expect(bar.child, same(child));
    expect(bar.thumbVisibility, isNull);
  });

  testWidgets('vertical AxisDirection.up gets a Scrollbar', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const child = SizedBox(key: Key('content-up'));

    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = behavior.buildScrollbar(
            context,
            child,
            details(direction: AxisDirection.up, controller: controller),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(built, isA<Scrollbar>());
    expect(identical((built as Scrollbar).controller, controller), isTrue);
  });

  testWidgets('horizontal AxisDirection.left remains unchanged', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const child = SizedBox(key: Key('horizontal-left'));

    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = behavior.buildScrollbar(
            context,
            child,
            details(direction: AxisDirection.left, controller: controller),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(identical(built, child), isTrue);
  });

  testWidgets('horizontal AxisDirection.right remains unchanged', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const child = SizedBox(key: Key('horizontal-right'));

    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = behavior.buildScrollbar(
            context,
            child,
            details(direction: AxisDirection.right, controller: controller),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(identical(built, child), isTrue);
  });

  testWidgets('null controller is accepted for vertical wrap', (tester) async {
    const child = SizedBox(key: Key('null-controller'));

    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = behavior.buildScrollbar(
            context,
            child,
            const ScrollableDetails(direction: AxisDirection.down),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(built, isA<Scrollbar>());
    final bar = built as Scrollbar;
    expect(bar.controller, isNull);
    expect(bar.child, same(child));
  });

  testWidgets('portal tabs scroll under global behavior without asserts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: behavior,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScope(now: () => DateTime(2026, 10, 20, 9)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Home vertical list is wrapped once by the behavior.
    expect(
      find.descendant(
        of: find.byKey(const Key('home-page')),
        matching: find.byType(Scrollbar),
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.descendant(
        of: find.byKey(const Key('home-page')),
        matching: find.byType(CustomScrollView),
      ),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final key in const [
      Key('nav-approvals'),
      Key('nav-history'),
      Key('nav-profile'),
      Key('nav-home'),
    ]) {
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$key');
    }
  });

  testWidgets('horizontal filter chips are not wrapped in Scrollbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SingleChildScrollView(
          key: const Key('chips'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              12,
              (i) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Chip $i'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
