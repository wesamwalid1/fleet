import 'package:driver_portal_app/core/session/home_scope.dart';
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

    await tester.ensureVisible(find.byKey(const Key('approval-filter-vault')));
    await tester.tap(find.byKey(const Key('approval-filter-vault')));
    await tester.pump();

    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.text('Road Expense Approval'), findsNothing);
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Received from Sami Hassan'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('approval-filter-drivers')),
    );
    await tester.tap(find.byKey(const Key('approval-filter-drivers')));
    await tester.pump();

    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );
    expect(find.text('Received from Sami Hassan'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('approval-filter-road')));
    await tester.tap(find.byKey(const Key('approval-filter-road')));
    await tester.pump();

    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.text('Received from Vault'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);
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
    expect(find.text('3,200'), findsOneWidget);
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
    expect(find.text('3,200'), findsOneWidget);
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
    expect(find.text('3,200'), findsOneWidget);
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
    expect(find.text('3,200'), findsOneWidget);
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
}

Future<void> _openApprovals(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool seedApprovals = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
