import 'dart:async';

import 'package:driver_portal_app/core/theme/app_surfaces.dart';
import 'package:driver_portal_app/core/theme/app_theme.dart';
import 'package:driver_portal_app/core/widgets/fleet_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders its child', (tester) async {
    await _pump(
      tester,
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [Text('child-content')],
      ),
    );

    expect(find.text('child-content'), findsOneWidget);
    expect(find.byType(FleetRefreshIndicator), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('pulling down triggers the supplied callback', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      onRefresh: () async {
        calls += 1;
      },
      child: _tallList(),
    );

    await _pullToRefresh(tester);
    expect(calls, 1);
  });

  testWidgets('indicator stays while the callback Future is pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pump(
      tester,
      onRefresh: () => gate.future,
      child: _tallList(),
    );

    await _flingRefresh(tester);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    gate.complete();
    await _settleIndicator(tester);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('ordinary short drag does not trigger refresh', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      onRefresh: () async {
        calls += 1;
      },
      child: _tallList(),
    );

    await tester.fling(find.text('A'), const Offset(0, 50), 1000);
    await _settleIndicator(tester);
    expect(calls, 0);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('short content refreshes with AlwaysScrollableScrollPhysics', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      onRefresh: () async {
        calls += 1;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 48, child: Text('short')),
        ],
      ),
    );

    await tester.fling(find.text('short'), const Offset(0, 300), 1000);
    await _settleIndicator(tester);
    expect(calls, 1);
  });

  testWidgets('empty always-scrollable content can trigger refresh', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      onRefresh: () async {
        calls += 1;
      },
      child: ListView(
        key: const Key('empty-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[],
      ),
    );

    await tester.fling(find.byKey(const Key('empty-list')), const Offset(0, 300), 1000);
    await _settleIndicator(tester);
    expect(calls, 1);
  });

  testWidgets(
    'callback failure stays visible to the caller and still dismisses',
    (tester) async {
      final gate = Completer<void>();
      Object? seenByCaller;
      await _pump(
        tester,
        // Mirrors Phase B screen integrations: await the work, observe the
        // failure, then complete so the indicator can dismiss. The wrapper
        // itself must not catch or rewrite the error.
        onRefresh: () async {
          try {
            await gate.future;
          } catch (error) {
            seenByCaller = error;
          }
        },
        child: _tallList(),
      );

      await _flingRefresh(tester);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      gate.completeError(StateError('refresh failed'));
      await _settleIndicator(tester);

      expect(seenByCaller, isA<StateError>());
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    },
  );

  testWidgets('does not insert an extra Scrollable around the child', (
    tester,
  ) async {
    await _pump(
      tester,
      onRefresh: () async {},
      child: ListView(
        key: const Key('caller-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: 200, child: Text('A'))],
      ),
    );

    expect(find.byType(Scrollable), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FleetRefreshIndicator),
        matching: find.byKey(const Key('caller-list')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('light theme uses AppPalette.action for the indicator', (
    tester,
  ) async {
    await _pump(
      tester,
      themeMode: ThemeMode.light,
      onRefresh: () async {},
      child: _tallList(),
    );

    final palette = AppPalette.of(
      tester.element(find.byType(FleetRefreshIndicator)),
    );
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.color, palette.action);
    expect(indicator.backgroundColor, palette.surface);
    expect(indicator.strokeWidth, FleetRefreshIndicator.strokeWidth);
    expect(indicator.elevation, 0);
  });

  testWidgets('dark theme uses AppPalette.action for the indicator', (
    tester,
  ) async {
    await _pump(
      tester,
      themeMode: ThemeMode.dark,
      onRefresh: () async {},
      child: _tallList(),
    );

    final palette = AppPalette.of(
      tester.element(find.byType(FleetRefreshIndicator)),
    );
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.color, palette.action);
    expect(indicator.backgroundColor, palette.surface);
    expect(palette.isDark, isTrue);
  });

  testWidgets('RTL layout still triggers refresh on vertical pull', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      textDirection: TextDirection.rtl,
      onRefresh: () async {
        calls += 1;
      },
      child: _tallList(),
    );

    await _pullToRefresh(tester);
    expect(calls, 1);
  });

  testWidgets('refresh remains functional when animations are disabled', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      disableAnimations: true,
      onRefresh: () async {
        calls += 1;
      },
      child: _tallList(),
    );

    await _pullToRefresh(tester);
    expect(calls, 1);
  });
}

Widget _tallList() {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: <String>['A', 'B', 'C', 'D', 'E', 'F']
        .map(
          (item) => SizedBox(height: 200, child: Text(item)),
        )
        .toList(),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function() onRefresh,
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        Widget built = child!;
        if (disableAnimations) {
          built = MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: built,
          );
        }
        return Directionality(
          textDirection: textDirection,
          child: built,
        );
      },
      home: Scaffold(
        body: FleetRefreshIndicator(
          onRefresh: onRefresh,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _flingRefresh(WidgetTester tester) async {
  await tester.fling(find.text('A'), const Offset(0, 300), 1000);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // scroll settle
  await tester.pump(const Duration(seconds: 1)); // indicator snap → refresh
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  await _flingRefresh(tester);
  await _settleIndicator(tester);
}

Future<void> _settleIndicator(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}
