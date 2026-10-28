import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/core/theme/app_text_styles.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters the action list and keeps the pending count', (
    tester,
  ) async {
    await _openApprovals(tester);

    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('Action Required'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Sami Hassan'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-vault'));

    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.text('Road Expense Approval'), findsNothing);
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Received from Sami Hassan'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-drivers'));

    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );
    expect(find.text('Received from Sami Hassan'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-road'));

    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.text('Received from Vault'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
  });

  testWidgets('search matches approvals and combines with filters', (
    tester,
  ) async {
    await _openApprovals(tester);

    await tester.enterText(find.byKey(const Key('approvals-search')), 'Khaled');
    await tester.pumpAndSettle();
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsNothing);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('approvals-search')),
      'no-such-approval',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approvals-no-results')), findsOneWidget);

    await tester.tap(find.byKey(const Key('approvals-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-vault'));
    await tester.enterText(find.byKey(const Key('approvals-search')), 'Khaled');
    await tester.pumpAndSettle();
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.byKey(const Key('approvals-no-results')), findsOneWidget);
  });

  testWidgets('empty approvals show no pending approvals', (tester) async {
    await _openApprovals(tester, seedApprovals: false);

    expect(find.byKey(const Key('approvals-empty')), findsOneWidget);
    expect(find.text('No pending approvals'), findsOneWidget);
    expect(find.text('3 pending'), findsNothing);
    expect(find.text('Action Required'), findsNothing);
  });

  testWidgets('cancel closes a vault receipt without changing the balance', (
    tester,
  ) async {
    await _openApprovals(tester);
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Approve Cash Receipt'), findsOneWidget);
    expect(find.text('Vault sent you custody funds'), findsOneWidget);
    expect(find.text('2,200 EGP'), findsWidgets);
    expect(find.text('4,200 EGP'), findsOneWidget);
    expect(find.text('Decline'), findsNothing);

    await tester.tap(find.byKey(const Key('approval-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('3 pending'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();

    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('approving a vault receipt credits the balance once', (
    tester,
  ) async {
    await _openApprovals(tester);
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();

    expect(find.text('2 pending'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-TRF-2025-0123')),
    );
    await tester.tap(find.byKey(const Key('approval-action-TRF-2025-0123')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4,200 EGP'), findsWidgets);
    expect(find.text('4,700 EGP'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('4,200 EGP'), findsOneWidget);
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('declining driver cash leaves the recipient balance unchanged', (
    tester,
  ) async {
    await _openApprovals(tester);
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-TRF-2025-0123')),
    );
    await tester.tap(find.byKey(const Key('approval-action-TRF-2025-0123')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Approve Cash from Driver'), findsOneWidget);
    expect(find.text('Khaled Ramadan sent you cash'), findsOneWidget);
    expect(find.text('2,700 EGP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('approval-decline')));
    await tester.pumpAndSettle();

    expect(find.text('2 pending'), findsOneWidget);
    expect(find.textContaining('Rejected'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-TRF-2025-0123')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsOneWidget);
  });

  testWidgets('confirming a road expense does not change the balance', (
    tester,
  ) async {
    await _openApprovals(tester);
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-action-RE-2026-1041')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Admin submitted this expense for your confirmation'),
      findsOneWidget,
    );
    expect(find.text('TR-2026-0881'), findsOneWidget);
    expect(find.text('Cairo → Alexandria'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('approval-confirm')));
    await tester.tap(find.byKey(const Key('approval-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approval-action-RE-2026-1041')), findsNothing);
    expect(find.text('2 pending'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('rejecting a road expense requires confirmation', (tester) async {
    await _openApprovals(tester);
    await tester.ensureVisible(
      find.byKey(const Key('approval-action-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-action-RE-2026-1041')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('approval-reject')));
    await tester.tap(find.byKey(const Key('approval-reject')));
    await tester.pumpAndSettle();

    expect(find.text('Reject expense?'), findsOneWidget);
    expect(
      find.text(
        'This will notify the admin that you have rejected RE-2026-1041.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('approval-reject-cancel')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('approval-action-RE-2026-1041')),
      findsOneWidget,
    );
    expect(find.text('3 pending'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-action-RE-2026-1041')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('approval-reject')));
    await tester.tap(find.byKey(const Key('approval-reject')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approval-reject-yes')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approval-action-RE-2026-1041')), findsNothing);
    expect(find.text('2 pending'), findsOneWidget);
    expect(find.textContaining('Rejected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsOneWidget);
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('arabic approvals copy is localized', (tester) async {
    await _openApprovals(tester, locale: const Locale('ar'));

    expect(find.text('الموافقات'), findsWidgets);
    expect(find.text('3 قيد الانتظار'), findsOneWidget);
    expect(find.text('إجراء مطلوب'), findsOneWidget);
    expect(find.text('مكتملة'), findsOneWidget);
    expect(find.text('لا توجد موافقات معلّقة'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('إجراء مطلوب'))),
      TextDirection.rtl,
    );
  });

  testWidgets('approval cards use a compact trailing amount and action', (
    tester,
  ) async {
    await _openApprovals(tester);

    const id = 'DSB-2025-0441';
    final card = find.byKey(const Key('approval-card-$id'));
    final details = tester.getRect(find.byKey(Key('approval-details-$id')));
    final values = tester.getRect(find.byKey(Key('approval-values-$id')));
    final cardRect = tester.getRect(card);
    final title = tester.getRect(
      find.descendant(of: card, matching: find.text('Received from Vault')),
    );
    final support = tester.getRect(
      find.descendant(
        of: card,
        matching: find.text('Drivers Vault · Just now'),
      ),
    );
    final amount = tester.getRect(
      find.descendant(of: card, matching: find.text('+2,000 EGP')),
    );
    final action = tester.getRect(find.byKey(const Key('approval-action-$id')));

    expect(values.left - details.right, closeTo(12, 1));
    expect(values.right, closeTo(cardRect.right - _cardInset, 1));
    expect(title.left, closeTo(details.left, 1));
    expect(support.left, closeTo(title.left, 1));
    expect(support.top, greaterThan(title.bottom - 1));
    expect(amount.right, closeTo(values.right, 1));
    expect(action.right, closeTo(values.right, 1));
    expect(action.top, greaterThan(amount.bottom - 1));
    expect(title.right, lessThanOrEqualTo(amount.left + 1));

    final titleStyle = tester
        .widget<Text>(
          find.descendant(of: card, matching: find.text('Received from Vault')),
        )
        .style!;
    final amountStyle = tester
        .widget<Text>(
          find.descendant(of: card, matching: find.text('+2,000 EGP')),
        )
        .style!;
    final supportStyle = tester
        .widget<Text>(
          find.descendant(
            of: card,
            matching: find.text('Drivers Vault · Just now'),
          ),
        )
        .style!;
    final actionStyle = tester
        .widget<Text>(find.descendant(of: card, matching: find.text('Approve')))
        .style!;
    expect(titleStyle.fontSize, AppTextStyles.rowTitle.fontSize);
    expect(amountStyle.fontSize, AppTextStyles.amount.fontSize);
    expect(supportStyle.fontSize, lessThan(titleStyle.fontSize!));
    expect(actionStyle.fontSize, 13);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arabic approval cards keep the amount on the trailing edge', (
    tester,
  ) async {
    await _openApprovals(tester, locale: const Locale('ar'));

    const id = 'DSB-2025-0441';
    final card = find.byKey(const Key('approval-card-$id'));
    expect(Directionality.of(tester.element(card)), TextDirection.rtl);
    final details = tester.getRect(find.byKey(Key('approval-details-$id')));
    final values = tester.getRect(find.byKey(Key('approval-values-$id')));
    final cardRect = tester.getRect(card);
    final action = tester.getRect(find.byKey(const Key('approval-action-$id')));

    expect(details.left - values.right, closeTo(12, 1));
    expect(values.left, closeTo(cardRect.left + _cardInset, 1));
    expect(action.left, closeTo(values.left, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow approval card does not overflow', (tester) async {
    await _openApprovals(
      tester,
      surfaceSize: const Size(320, 640),
      textScale: 1.6,
    );

    expect(find.text('Received from Vault'), findsWidgets);
    final card = find.byKey(const Key('approval-card-DSB-2025-0441'));
    final title = tester.getRect(
      find.descendant(of: card, matching: find.text('Received from Vault')),
    );
    final amount = tester.getRect(
      find.descendant(of: card, matching: find.textContaining('EGP')),
    );
    expect(title.right, lessThanOrEqualTo(amount.left + 1));
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Received from Khaled Ramadan'),
      250,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
      ),
    );
    await tester.pump();
    final longCard = find.byKey(const Key('approval-card-TRF-2025-0123'));
    final longTitle = tester.getRect(
      find.descendant(
        of: longCard,
        matching: find.text('Received from Khaled Ramadan'),
      ),
    );
    final longAmount = tester.getRect(
      find.descendant(of: longCard, matching: find.textContaining('EGP')),
    );
    expect(longTitle.right, lessThanOrEqualTo(longAmount.left + 1));
    expect(tester.takeException(), isNull);
  });
}

/// Card padding (14) plus its border (1), from the card's edge to the row.
const _cardInset = 15.0;

Future<void> _selectApprovalFilter(WidgetTester tester, Key optionKey) async {
  await tester.tap(find.byKey(const Key('approvals-filter-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(optionKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('approvals-filter-apply')));
  await tester.pumpAndSettle();
}

Future<void> _openApprovals(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool seedApprovals = true,
  Size surfaceSize = const Size(400, 1200),
  double textScale = 1,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: HomeScope(
        now: () => DateTime(2026, 10, 20, 9),
        seedApprovals: seedApprovals,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-approvals')));
  await tester.pumpAndSettle();
}
