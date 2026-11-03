import 'package:driver_portal_app/core/routing/fade_through_route.dart';
import 'package:driver_portal_app/core/widgets/ticket_border.dart';
import 'package:driver_portal_app/features/auth/presentation/widgets/login_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketBorder', () {
    const border = TicketBorder(
      tearY: 80,
      borderColor: Color(0xFFDCE3EF),
      radius: 20,
      notchRadius: 10,
    );
    const rect = Rect.fromLTWH(0, 0, 300, 400);

    test('cuts a notch on each side at the tear line', () {
      final path = border.getOuterPath(rect);

      expect(path.contains(const Offset(150, 200)), isTrue);
      expect(path.contains(const Offset(150, 80)), isTrue);
      expect(path.contains(const Offset(4, 80)), isFalse);
      expect(path.contains(const Offset(296, 80)), isFalse);
      expect(path.contains(const Offset(4, 140)), isTrue);
    });

    test('keeps the tear line clear of the rounded corners', () {
      const high = TicketBorder(tearY: 0, borderColor: Color(0xFFDCE3EF));
      final path = high.getOuterPath(rect);

      expect(path.contains(const Offset(150, 2)), isTrue);
      expect(path.contains(const Offset(4, 30)), isFalse);
    });
  });

  group('LoginHeader height', () {
    test('the stacked stub is taller than the inline one at large text', () {
      const scaler = TextScaler.linear(1.6);
      expect(
        LoginHeader.heightFor(scaler, inline: false),
        greaterThan(LoginHeader.heightFor(scaler, inline: true)),
      );
    });

    test('the stub never shrinks below the mark plus padding', () {
      expect(
        LoginHeader.heightFor(TextScaler.noScaling, inline: true),
        greaterThanOrEqualTo(72),
      );
    });
  });

  group('FadeThroughRoute', () {
    Future<void> push(WidgetTester tester, {required bool reduceMotion}) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: const Scaffold(body: Text('first')),
        ),
      );
      navigator.currentState!.push(
        FadeThroughRoute<void>(
          ground: (_) => const Color(0xFFEEF1F7),
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
    }

    Iterable<FadeTransition> fadesAbove(WidgetTester tester, String text) {
      return tester.widgetList<FadeTransition>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(FadeTransition),
        ),
      );
    }

    testWidgets('fades the incoming page in mid-transition', (tester) async {
      await push(tester, reduceMotion: false);

      final fades = fadesAbove(tester, 'second');
      expect(fades, isNotEmpty);
      expect(fades.any((fade) => fade.opacity.value < 1), isTrue);

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('shows the page at once when animations are off', (
      tester,
    ) async {
      await push(tester, reduceMotion: true);

      expect(
        fadesAbove(tester, 'second').where((fade) => fade.opacity.value < 1),
        isEmpty,
      );
      await tester.pumpAndSettle();
    });
  });
}
