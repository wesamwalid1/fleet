import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reveals the Home finance groups so existing amount assertions still see
/// the formatted figures. A fresh session starts hidden. Calling this again
/// leaves an already revealed group visible.
Future<void> revealHomeFinance(WidgetTester tester) async {
  Future<void> showIfHidden(Key key) async {
    final any = find.byKey(key, skipOffstage: false);
    if (any.evaluate().isEmpty) return;
    if (any.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(any);
      await tester.pumpAndSettle();
    }
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) return;
    final tooltip = tester.widget<IconButton>(finder).tooltip ?? '';
    final hidden = tooltip.startsWith('Show') || tooltip.startsWith('إظهار');
    if (!hidden) return;
    await tester.tap(finder);
    await tester.pump();
  }

  await showIfHidden(const Key('home-balance-visibility'));
  await showIfHidden(const Key('home-limit-visibility'));
}
