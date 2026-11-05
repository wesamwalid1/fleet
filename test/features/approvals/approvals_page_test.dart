import 'package:driver_portal_app/core/localization/localized_string.dart';
import 'package:driver_portal_app/core/session/home_scope.dart';
import 'package:driver_portal_app/features/approvals/domain/entities/approval_item.dart';
import 'package:driver_portal_app/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:driver_portal_app/features/approvals/presentation/widgets/approval_inbox_row.dart';
import 'package:driver_portal_app/features/finance/data/datasources/mock_cash_ledger.dart';
import 'package:driver_portal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters both sections and updates the pending count', (
    tester,
  ) async {
    await _openApprovals(tester);

    expect(find.text('3 pending'), findsOneWidget);
    expect(find.text('Needs your decision'), findsOneWidget);
    expect(find.text('Already decided'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Sami Hassan'), findsOneWidget);
    expect(find.text('2,000 EGP'), findsWidgets);
    expect(find.text('+2,000 EGP'), findsNothing);

    await _selectApprovalFilter(tester, const Key('approval-filter-vault'));

    expect(find.text('1 pending'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.text('Road Expense Approval'), findsNothing);
    expect(find.text('Received from Vault'), findsWidgets);
    expect(find.text('Received from Sami Hassan'), findsNothing);
    expect(find.text('Already decided'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-drivers'));

    expect(find.text('1 pending'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
      findsNothing,
    );
    expect(find.text('Received from Sami Hassan'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-road'));

    expect(find.text('1 pending'), findsOneWidget);
    expect(find.text('Road Expense Approval'), findsOneWidget);
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.text('Received from Vault'), findsNothing);
    expect(find.text('Already decided'), findsNothing);
  });

  testWidgets('search matches approvals and combines with filters', (
    tester,
  ) async {
    await _openApprovals(tester);

    await tester.enterText(find.byKey(const Key('approvals-search')), 'Khaled');
    await tester.pumpAndSettle();
    expect(find.text('1 pending'), findsOneWidget);
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
    expect(find.text('Needs your decision'), findsNothing);
    expect(find.text('Already decided'), findsNothing);

    await tester.tap(find.byKey(const Key('approvals-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Received from Khaled Ramadan'), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);

    await _selectApprovalFilter(tester, const Key('approval-filter-vault'));
    await tester.enterText(find.byKey(const Key('approvals-search')), 'Khaled');
    await tester.pumpAndSettle();
    expect(find.text('Received from Khaled Ramadan'), findsNothing);
    expect(find.byKey(const Key('approvals-no-results')), findsOneWidget);
  });

  testWidgets('empty states follow the Desk matrix', (tester) async {
    await _openApprovals(tester, seedApprovals: false);

    expect(find.byKey(const Key('approvals-empty')), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('3 pending'), findsNothing);
    expect(find.text('Needs your decision'), findsNothing);
    expect(find.text('Already decided'), findsNothing);
  });

  testWidgets('completed-only filter shows a local pending hint', (
    tester,
  ) async {
    await _openApprovals(tester);

    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-approve')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-TRF-2025-0123')),
    );
    await tester.tap(find.byKey(const Key('approval-action-TRF-2025-0123')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('approval-decline')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-action-RE-2026-1041')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('approval-confirm')));
    await tester.tap(find.byKey(const Key('approval-confirm')));
    await tester.pumpAndSettle();

    await _selectApprovalFilter(tester, const Key('approval-filter-vault'));
    expect(find.byKey(const Key('approvals-no-pending-hint')), findsOneWidget);
    expect(find.text('Already decided'), findsOneWidget);
    expect(find.text("You're all caught up"), findsNothing);
  });

  testWidgets('vault sheet shows the ledger balance after a pending Withdraw', (
    tester,
  ) async {
    late MockCashLedger ledger;
    await _openApprovals(
      tester,
      configureLedger: (value) {
        ledger = value;
        value.submitWithdraw(
          driverId: MockCashLedger.senderId,
          amountEgp: 500,
          createdAt: DateTime(2026, 10, 20, 9),
        );
      },
    );

    expect(ledger.currentBalance(MockCashLedger.senderId), 1700);
    expect(ledger.availableBalance(MockCashLedger.senderId), 1700);
    expect(ledger.frozenBalance(MockCashLedger.senderId), 500);

    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Approve Cash Receipt'), findsOneWidget);
    expect(find.text('Current balance'), findsOneWidget);
    expect(find.text('1,700 EGP'), findsWidgets);
    expect(find.text('3,700 EGP'), findsOneWidget);
    expect(find.text('4,200 EGP'), findsNothing);

    await tester.tap(find.byKey(const Key('approval-cancel')));
    await tester.pumpAndSettle();
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

    expect(find.text('2,200 EGP'), findsNWidgets(2));
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
    await tester.tap(find.byKey(const Key('approval-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('4,200 EGP'), findsNWidgets(2));
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
    expect(find.text('500 EGP'), findsWidgets);

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
    expect(find.text('2,200 EGP'), findsNWidgets(2));
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
    expect(find.byKey(const Key('approval-detail-amount')), findsOneWidget);
    expect(
      find.byKey(const Key('approval-detail-balance-outcome')),
      findsOneWidget,
    );
    expect(find.text('No change'), findsOneWidget);
    expect(
      find.text("Road expenses don't affect your balance."),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('approval-confirm')));
    await tester.tap(find.byKey(const Key('approval-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approval-action-RE-2026-1041')), findsNothing);
    expect(find.text('2 pending'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('2,200 EGP'), findsNWidgets(2));
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('rejecting a road expense uses Desk confirmation copy', (
    tester,
  ) async {
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

    expect(find.text('Reject this road expense?'), findsOneWidget);
    expect(
      find.text(
        'This will mark RE-2026-1041 as rejected. It won’t change your balance.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reject'), findsWidgets);

    await tester.tap(find.byKey(const Key('approval-reject-cancel')));
    await tester.pumpAndSettle();

    // Review sheet stays open after dismissing the reject dialog.
    expect(find.byKey(const Key('approval-reject')), findsOneWidget);
    expect(find.text('3 pending'), findsOneWidget);

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
    expect(find.text('2,200 EGP'), findsNWidgets(2));
    expect(find.text('3,200 EGP'), findsOneWidget);
    expect(find.text('5,000 EGP'), findsOneWidget);
  });

  testWidgets('completed rows open read-only details without actions', (
    tester,
  ) async {
    await _openApprovals(tester);
    final bloc = _approvalsBloc(tester);
    final revision = bloc.state.revision;

    final completed = find.byKey(const Key('approval-card-TRF-2025-0090'));
    await tester.ensureVisible(completed);
    await tester.tap(completed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('approval-detail-amount')), findsOneWidget);
    expect(
      find.byKey(const Key('approval-detail-balance-outcome')),
      findsOneWidget,
    );
    expect(find.text('Credited to your balance.'), findsOneWidget);
    expect(find.text('800 EGP'), findsWidgets);
    expect(find.text('+800 EGP'), findsNothing);
    expect(find.byKey(const Key('approval-approve')), findsNothing);
    expect(find.byKey(const Key('approval-decline')), findsNothing);
    expect(find.byKey(const Key('approval-transaction-close')), findsOneWidget);

    await tester.tap(find.byKey(const Key('approval-transaction-close')));
    await tester.pumpAndSettle();

    expect(bloc.state.revision, revision);
    expect(bloc.state.busy, isFalse);
    expect(find.text('3 pending'), findsOneWidget);
  });

  testWidgets('busy disables pending row actions', (tester) async {
    final pending = ApprovalItem(
      id: 'DSB-busy',
      kind: ApprovalKind.vault,
      amountEgp: 1500,
      reference: 'DSB-busy',
      occurredAt: DateTime(2026, 10, 20, 9),
      outcome: ApprovalOutcome.pending,
      counterpartyName: const LocalizedString(en: 'Vault', ar: 'الخزنة'),
      counterpartyId: 'VAULT',
    );
    var opened = false;
    await tester.pumpWidget(
      _localize(
        ApprovalInboxRow(
          item: pending,
          busy: true,
          onOpen: () => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = tester.widget<FilledButton>(
      find.byKey(const Key('approval-action-DSB-busy')),
    );
    expect(action.onPressed, isNull);
    await tester.tap(find.byKey(const Key('approval-card-DSB-busy')));
    await tester.pump();
    expect(opened, isFalse);
  });

  testWidgets('pending action targets are at least 48dp', (tester) async {
    await _openApprovals(tester);
    final action = tester.getSize(
      find.byKey(const Key('approval-action-DSB-2025-0441')),
    );
    expect(action.height, greaterThanOrEqualTo(48));
    expect(action.width, greaterThanOrEqualTo(48));
  });

  testWidgets('review sheet primary actions are at least 56dp', (tester) async {
    await _openApprovals(tester);
    await tester.tap(find.byKey(const Key('approval-action-DSB-2025-0441')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('approval-approve')), findsOneWidget);
    final approve = tester.getSize(find.byKey(const Key('approval-approve')));
    expect(approve.height, greaterThanOrEqualTo(56));

    await tester.tap(find.byKey(const Key('approval-cancel')));
    await tester.pumpAndSettle();
  });

  testWidgets('arabic approvals copy is localized', (tester) async {
    await _openApprovals(tester, locale: const Locale('ar'));

    expect(find.text('الموافقات'), findsWidgets);
    expect(find.text('3 قيد الانتظار'), findsOneWidget);
    expect(find.text('يحتاج إلى قرارك'), findsOneWidget);
    expect(find.text('تمّ البت فيه'), findsOneWidget);
    expect(find.text('أنت على اطلاع بكل شيء'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('يحتاج إلى قرارك'))),
      TextDirection.rtl,
    );

    await tester.ensureVisible(
      find.byKey(const Key('approval-action-RE-2026-1041')),
    );
    await tester.tap(find.byKey(const Key('approval-action-RE-2026-1041')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('approval-reject')));
    await tester.tap(find.byKey(const Key('approval-reject')));
    await tester.pumpAndSettle();

    expect(find.text('رفض مصروف الطريق؟'), findsOneWidget);
    expect(
      find.text('سيتم تعليم RE-2026-1041 كمرفوض. لن يتغيّر رصيدك.'),
      findsOneWidget,
    );
    expect(find.text('رفض'), findsWidgets);
  });

  testWidgets('inbox rows keep amount on the trailing edge', (tester) async {
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
      find.descendant(of: card, matching: find.text('2,000 EGP')),
    );
    final action = tester.getRect(find.byKey(const Key('approval-action-$id')));

    expect(values.left - details.right, closeTo(12, 1));
    expect(values.right, closeTo(cardRect.right, 1));
    expect(title.left, closeTo(details.left, 1));
    expect(support.left, closeTo(title.left, 1));
    expect(support.top, greaterThan(title.bottom - 1));
    expect(amount.right, closeTo(values.right, 1));
    expect(action.right, closeTo(values.right, 1));
    expect(action.top, greaterThan(amount.bottom - 1));
    expect(title.right, lessThanOrEqualTo(amount.left + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('arabic inbox rows keep the amount on the trailing edge', (
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
    expect(values.left, closeTo(cardRect.left, 1));
    expect(action.left, closeTo(values.left, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow approvals list does not overflow', (tester) async {
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

ApprovalsBloc _approvalsBloc(WidgetTester tester) {
  return BlocProvider.of<ApprovalsBloc>(
    tester.element(find.byKey(const Key('approvals-search'))),
  );
}

Future<void> _selectApprovalFilter(WidgetTester tester, Key optionKey) async {
  await tester.ensureVisible(find.byKey(optionKey));
  await tester.tap(find.byKey(optionKey));
  await tester.pumpAndSettle();
}

Widget _localize(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Future<void> _openApprovals(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool seedApprovals = true,
  Size surfaceSize = const Size(400, 1200),
  double textScale = 1,
  void Function(MockCashLedger ledger)? configureLedger,
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
        configureLedger: configureLedger,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-approvals')));
  await tester.pumpAndSettle();
}
