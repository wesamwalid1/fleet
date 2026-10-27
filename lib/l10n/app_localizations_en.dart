// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get driverPortal => 'Driver Portal';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get signInSubtitle => 'Sign in to your driver account';

  @override
  String get emailHint => 'Driver Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get contactVaultManager =>
      'Having trouble? Contact your vault manager';

  @override
  String get emptyEmail => 'Please enter your email';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get emptyPassword => 'Please enter your password';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get signingIn => 'Signing in';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goodMorning => 'Good morning 👋';

  @override
  String get goodAfternoon => 'Good afternoon 👋';

  @override
  String get goodEvening => 'Good evening 👋';

  @override
  String get notifications => 'Notifications';

  @override
  String get homeLoadError => 'Unable to load your profile.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get balance => 'Balance';

  @override
  String get charge => 'Charge';

  @override
  String get maxLimit => 'Max Limit';

  @override
  String get egp => 'EGP';

  @override
  String get loadingBalance => 'Loading balance';

  @override
  String get balanceLoadError => 'Unable to load your balance.';

  @override
  String get sendCash => 'Send Cash';

  @override
  String get sendCashTitle => 'Send Cash to Driver';

  @override
  String get sendCashSubtitle => 'Select driver and enter amount';

  @override
  String get selectDriver => 'Select a driver';

  @override
  String get noDrivers => 'No drivers available';

  @override
  String yourBalance(String amount) {
    return 'Your balance: $amount';
  }

  @override
  String get yourBalanceAfter => 'Your balance after';

  @override
  String get amount => 'Amount';

  @override
  String mustApprove(String name) {
    return '$name must approve to complete';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get sendingRequest => 'Sending request';

  @override
  String get requestSent => 'Request Sent!';

  @override
  String requestSentDetail(String amount, String name) {
    return '$amount request sent to $name';
  }

  @override
  String waitingForApproval(String name) {
    return 'Waiting for $name to approve';
  }

  @override
  String get currentBalance => 'Current balance';

  @override
  String get close => 'Close';

  @override
  String get goHome => 'Go Home';

  @override
  String get viewTransaction => 'View Transaction';

  @override
  String get selectDriverError => 'Select a driver';

  @override
  String get invalidAmountError => 'Enter an amount greater than zero';

  @override
  String get insufficientBalanceError =>
      'Amount exceeds your available balance';

  @override
  String get sendCashFailed => 'Could not send the request.';

  @override
  String driverCodeBalance(String code, String balance) {
    return '$code · $balance';
  }

  @override
  String get recordExpense => 'Record Expense';

  @override
  String get recordExpenseSubtitle => 'Will be deducted from your balance';

  @override
  String get selectTripHint => 'Select trip...';

  @override
  String get selectTripTitle => 'Select Trip';

  @override
  String tripsAssigned(int count) {
    return '$count trips assigned to you';
  }

  @override
  String get searchTrips => 'Search by code or route...';

  @override
  String get noTripResults => 'No trips match your search';

  @override
  String get tripActive => 'Active';

  @override
  String get tripCompleted => 'Completed';

  @override
  String get selectSettlementHint => 'Select type...';

  @override
  String get settlementTypeTitle => 'Settlement Type';

  @override
  String get settlementRoadFeesClient => 'Road Fees — Client';

  @override
  String get settlementRoadFeesVendors => 'Road Fees — Vendors';

  @override
  String get settlementCrossBorder => 'Cross Border';

  @override
  String get settlementFuel => 'Fuel';

  @override
  String get settlementFuelGloss => 'تموين';

  @override
  String get settlementLicensing => 'Licensing';

  @override
  String get settlementLicensingGloss => 'تراخيص';

  @override
  String get settlementPermits => 'Permits';

  @override
  String get settlementPermitsGloss => 'تصاريح';

  @override
  String get settlementTransportFees => 'Transport Fees';

  @override
  String get settlementMaintenance => 'Maintenance';

  @override
  String get amountEgpLabel => 'Amount (EGP)';

  @override
  String balanceAfterPreview(String amount) {
    return 'Balance after: $amount';
  }

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get notesHint => 'Add any notes...';

  @override
  String get attachmentsOptional => 'Attachments (optional)';

  @override
  String get attachments => 'Attachments';

  @override
  String attachmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get file => 'File';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get selectTripError => 'Please select a trip';

  @override
  String get selectSettlementError => 'Please select a settlement type';

  @override
  String get ineligibleTripError => 'This trip cannot be used for an expense';

  @override
  String get attachmentFailed => 'Couldn\'t add the attachment.';

  @override
  String get expenseFailed => 'Could not record the expense.';

  @override
  String get confirmExpense => 'Confirm Expense';

  @override
  String get confirmExpenseSubtitle =>
      'This will be deducted from your balance';

  @override
  String get deduction => 'DEDUCTION';

  @override
  String get settlementType => 'Settlement Type';

  @override
  String get trip => 'Trip';

  @override
  String get balanceAfter => 'Balance After';

  @override
  String get back => 'Back';

  @override
  String get confirmDeduction => 'Confirm Deduction';

  @override
  String get expenseRecorded => 'Expense Recorded';

  @override
  String expenseDeducted(String expense) {
    return '$expense has been deducted from your balance';
  }

  @override
  String get amountDeducted => 'Amount Deducted';

  @override
  String get newBalance => 'New Balance';

  @override
  String get tripCode => 'Trip Code';

  @override
  String get reference => 'Reference';

  @override
  String get done => 'Done';

  @override
  String get recordingExpense => 'Recording expense';

  @override
  String get approvals => 'Approvals';

  @override
  String get pendingApprovals => 'Pending Approvals';

  @override
  String get recent => 'Recent';

  @override
  String get seeAll => 'See all';

  @override
  String get yesterday => 'Yesterday';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get filterAll => 'All';

  @override
  String get fromVault => 'From Vault';

  @override
  String get fromDrivers => 'From Drivers';

  @override
  String get roadExpenses => 'Road Expenses';

  @override
  String get actionRequired => 'Action Required';

  @override
  String get completed => 'Completed';

  @override
  String get noPendingApprovals => 'No pending approvals';

  @override
  String get receivedFromVault => 'Received from Vault';

  @override
  String get driversVault => 'Drivers Vault';

  @override
  String get justNow => 'Just now';

  @override
  String get now => 'Now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String get approve => 'Approve';

  @override
  String get approveCashReceipt => 'Approve Cash Receipt';

  @override
  String get vaultSentFunds => 'Vault sent you custody funds';

  @override
  String get from => 'From';

  @override
  String get date => 'Date';

  @override
  String get approveCashFromDriver => 'Approve Cash from Driver';

  @override
  String driverSentCash(String name) {
    return '$name sent you cash';
  }

  @override
  String receivedFromDriver(String name) {
    return 'Received from $name';
  }

  @override
  String get decline => 'Decline';

  @override
  String get roadExpenseApproval => 'Road Expense Approval';

  @override
  String get adminSubmittedExpense =>
      'Admin submitted this expense for your confirmation';

  @override
  String get totalAmount => 'TOTAL AMOUNT';

  @override
  String get period => 'Period';

  @override
  String get submittedBy => 'Submitted by';

  @override
  String get tripDetails => 'TRIP DETAILS';

  @override
  String tripsPerAmount(int count, String amount) {
    return '$count trips · $amount / trip';
  }

  @override
  String tripNumber(int number) {
    return 'Trip $number';
  }

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get reject => 'Reject';

  @override
  String get confirm => 'Confirm';

  @override
  String get rejectExpenseTitle => 'Reject expense?';

  @override
  String rejectExpenseMessage(String reference) {
    return 'This will notify the admin that you have rejected $reference.';
  }

  @override
  String get yesReject => 'Yes, Reject';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get filterExpenses => 'Expenses';

  @override
  String get filterSent => 'Sent';

  @override
  String get filterPending => 'Pending';

  @override
  String historyToday(String date) {
    return 'Today — $date';
  }

  @override
  String historyYesterday(String date) {
    return 'Yesterday — $date';
  }

  @override
  String sentTo(String name) {
    return 'Sent to $name';
  }

  @override
  String pendingFrom(String name) {
    return 'Pending — from $name';
  }

  @override
  String get pendingConfirm => 'Pending confirm';

  @override
  String get awaitingYourApproval => 'Awaiting your approval';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get recorded => 'Recorded';

  @override
  String get expenseDetails => 'Expense Details';

  @override
  String get historyDeducted => 'DEDUCTED';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get navProfile => 'Profile';

  @override
  String get myBalance => 'My Balance';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutMessage => 'You will need to sign in again.';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get profileQuickAccess => 'Quick Access';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileAccount => 'Account';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String profileBalance(String amount) {
    return 'Balance: $amount';
  }

  @override
  String profileIdentity(String id, String vault) {
    return '$id · $vault';
  }

  @override
  String get approvalFailed => 'Could not update this approval.';

  @override
  String get homeAvailableBalance => 'Available Balance';

  @override
  String homeLimitUsed(String percent) {
    return '$percent% of limit used';
  }

  @override
  String get homeRemainingLimit => 'Remaining Limit';

  @override
  String get homeActiveTrip => 'Active Trip';

  @override
  String get homeNoActiveTrip => 'No Active Trip';

  @override
  String get homeNoActiveTripHint =>
      'Expenses can be recorded once a trip is active.';

  @override
  String get homeActions => 'Actions';

  @override
  String get homeViewAllApprovals => 'View All Approvals';

  @override
  String get homeAllCaughtUp => 'You\'re all caught up';

  @override
  String get homeRecentTransactions => 'Recent Transactions';

  @override
  String get notificationsFilterUnread => 'Unread';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptyHint =>
      'Updates about cash, approvals, and expenses will appear here.';

  @override
  String get notificationsNoUnread => 'No unread notifications';

  @override
  String get notificationsNoUnreadHint => 'You\'re all caught up.';

  @override
  String get notificationsLoadError => 'Unable to load notifications.';

  @override
  String get notificationUnread => 'Unread';

  @override
  String get notificationVaultPendingTitle =>
      'Vault cash awaiting your approval';

  @override
  String notificationIncomingTitle(String name) {
    return 'Cash from $name awaiting your approval';
  }

  @override
  String notificationSentApprovedTitle(String name, String amount) {
    return '$name confirmed your transfer of $amount';
  }

  @override
  String notificationSentRejectedTitle(String name, String amount) {
    return '$name rejected your transfer of $amount';
  }

  @override
  String notificationTransferSentTitle(String amount, String name) {
    return 'You sent $amount to $name';
  }

  @override
  String notificationTransferSentBody(String reference) {
    return 'Waiting for confirmation · $reference';
  }

  @override
  String notificationTransferConfirmedBody(String reference) {
    return 'Confirmed · $reference';
  }

  @override
  String get notificationsSearchHint => 'Search notifications';

  @override
  String get notificationsClearSearch => 'Clear search';

  @override
  String get notificationsNoResults => 'No matching notifications';

  @override
  String get notificationsNoResultsHint =>
      'Try a different word or clear the search.';

  @override
  String get notificationRoadPendingTitle =>
      'Road expense needs your confirmation';

  @override
  String get notificationExpenseRecordedTitle => 'Expense recorded';

  @override
  String notificationAmountReference(String amount, String reference) {
    return '$amount · $reference';
  }

  @override
  String notificationRefundedBody(String amount, String reference) {
    return '$amount returned to your balance · $reference';
  }

  @override
  String notificationDeductedBody(String amount, String reference) {
    return '$amount deducted · $reference';
  }

  @override
  String get notificationRequestHandled =>
      'This request was already handled. Showing its current status.';

  @override
  String get notificationTargetUnavailable =>
      'This item is no longer available.';
}
