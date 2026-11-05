import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name shown on the login header
  ///
  /// In en, this message translates to:
  /// **'Driver Portal'**
  String get driverPortal;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your driver account'**
  String get signInSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Driver Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @contactVaultManager.
  ///
  /// In en, this message translates to:
  /// **'Having trouble? Contact your vault manager'**
  String get contactVaultManager;

  /// No description provided for @emptyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emptyEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @emptyPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get emptyPassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unexpectedError;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get signingIn;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning 👋'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon 👋'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening 👋'**
  String get goodEvening;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile.'**
  String get homeLoadError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @charge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get charge;

  /// No description provided for @maxLimit.
  ///
  /// In en, this message translates to:
  /// **'Max Limit'**
  String get maxLimit;

  /// No description provided for @egp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egp;

  /// No description provided for @loadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Loading balance'**
  String get loadingBalance;

  /// No description provided for @balanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your balance.'**
  String get balanceLoadError;

  /// No description provided for @sendCash.
  ///
  /// In en, this message translates to:
  /// **'Send Cash'**
  String get sendCash;

  /// No description provided for @sendCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Cash to Driver'**
  String get sendCashTitle;

  /// No description provided for @sendCashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select driver and enter amount'**
  String get sendCashSubtitle;

  /// No description provided for @requestCash.
  ///
  /// In en, this message translates to:
  /// **'Request Cash'**
  String get requestCash;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @actionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This action will be available soon.'**
  String get actionComingSoon;

  /// No description provided for @requestCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Cash'**
  String get requestCashTitle;

  /// No description provided for @requestCashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request money from the company vault'**
  String get requestCashSubtitle;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawTitle;

  /// No description provided for @withdrawSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return unused cash to the company vault'**
  String get withdrawSubtitle;

  /// No description provided for @availableRequestCapacity.
  ///
  /// In en, this message translates to:
  /// **'Available request capacity'**
  String get availableRequestCapacity;

  /// No description provided for @requestCashTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get requestCashTotalBalance;

  /// No description provided for @pendingRequestCash.
  ///
  /// In en, this message translates to:
  /// **'Pending Request Cash'**
  String get pendingRequestCash;

  /// No description provided for @requestCashSummaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your request cash details.'**
  String get requestCashSummaryLoadError;

  /// No description provided for @withdrawAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get withdrawAvailableBalance;

  /// No description provided for @withdrawAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Amount'**
  String get withdrawAmountLabel;

  /// No description provided for @withdrawBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance After Withdrawal'**
  String get withdrawBalanceAfter;

  /// No description provided for @withdrawSummaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your withdrawal details.'**
  String get withdrawSummaryLoadError;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @submitWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Submit Withdraw'**
  String get submitWithdraw;

  /// No description provided for @exceedsRequestCapacityError.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds your available request capacity'**
  String get exceedsRequestCapacityError;

  /// No description provided for @exceedsAvailableBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds your available balance'**
  String get exceedsAvailableBalanceError;

  /// No description provided for @requestCashFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit the cash request. Please try again.'**
  String get requestCashFailed;

  /// No description provided for @withdrawFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit the withdraw request. Please try again.'**
  String get withdrawFailed;

  /// No description provided for @cashRequestSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted!'**
  String get cashRequestSubmittedTitle;

  /// No description provided for @cashRequestSubmittedDetail.
  ///
  /// In en, this message translates to:
  /// **'{amount} submitted as {number}'**
  String cashRequestSubmittedDetail(String amount, String number);

  /// No description provided for @historyRequestCash.
  ///
  /// In en, this message translates to:
  /// **'Request Cash'**
  String get historyRequestCash;

  /// No description provided for @historyWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get historyWithdraw;

  /// No description provided for @historyPendingBalanceUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Balance unchanged'**
  String get historyPendingBalanceUnchanged;

  /// No description provided for @notificationRequestCashPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash request submitted'**
  String get notificationRequestCashPendingTitle;

  /// No description provided for @notificationRequestCashApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash request approved'**
  String get notificationRequestCashApprovedTitle;

  /// No description provided for @notificationRequestCashRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash request rejected'**
  String get notificationRequestCashRejectedTitle;

  /// No description provided for @notificationWithdrawPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request submitted'**
  String get notificationWithdrawPendingTitle;

  /// No description provided for @notificationWithdrawApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request approved'**
  String get notificationWithdrawApprovedTitle;

  /// No description provided for @notificationWithdrawRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request rejected'**
  String get notificationWithdrawRejectedTitle;

  /// No description provided for @notificationRequestCashPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} request {reference} is pending approval'**
  String notificationRequestCashPendingBody(String amount, String reference);

  /// No description provided for @notificationRequestCashApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} was added for request {reference}'**
  String notificationRequestCashApprovedBody(String amount, String reference);

  /// No description provided for @notificationRequestCashRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} request {reference} was rejected'**
  String notificationRequestCashRejectedBody(String amount, String reference);

  /// No description provided for @notificationWithdrawPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} withdraw {reference} is pending approval'**
  String notificationWithdrawPendingBody(String amount, String reference);

  /// No description provided for @notificationWithdrawApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} was returned for withdraw {reference}'**
  String notificationWithdrawApprovedBody(String amount, String reference);

  /// No description provided for @notificationWithdrawRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} withdraw {reference} was rejected'**
  String notificationWithdrawRejectedBody(String amount, String reference);

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select a driver'**
  String get selectDriver;

  /// No description provided for @noDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers available'**
  String get noDrivers;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance: {amount}'**
  String yourBalance(String amount);

  /// No description provided for @yourBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Your balance after'**
  String get yourBalanceAfter;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @mustApprove.
  ///
  /// In en, this message translates to:
  /// **'{name} must approve to complete'**
  String mustApprove(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @sendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending request'**
  String get sendingRequest;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent!'**
  String get requestSent;

  /// No description provided for @requestSentDetail.
  ///
  /// In en, this message translates to:
  /// **'{amount} request sent to {name}'**
  String requestSentDetail(String amount, String name);

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to approve'**
  String waitingForApproval(String name);

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// Opens Transaction History focused on the request that was just sent.
  ///
  /// In en, this message translates to:
  /// **'View Transaction'**
  String get viewTransaction;

  /// No description provided for @selectDriverError.
  ///
  /// In en, this message translates to:
  /// **'Select a driver'**
  String get selectDriverError;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get invalidAmountError;

  /// No description provided for @insufficientBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds your available balance'**
  String get insufficientBalanceError;

  /// No description provided for @sendCashFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request.'**
  String get sendCashFailed;

  /// No description provided for @driverCodeBalance.
  ///
  /// In en, this message translates to:
  /// **'{code} · {balance}'**
  String driverCodeBalance(String code, String balance);

  /// No description provided for @recordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record Expense'**
  String get recordExpense;

  /// No description provided for @recordExpenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Will be deducted from your balance'**
  String get recordExpenseSubtitle;

  /// No description provided for @selectTripHint.
  ///
  /// In en, this message translates to:
  /// **'Select trip...'**
  String get selectTripHint;

  /// No description provided for @selectTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Trip'**
  String get selectTripTitle;

  /// No description provided for @tripsAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count} trips assigned to you'**
  String tripsAssigned(int count);

  /// No description provided for @searchTrips.
  ///
  /// In en, this message translates to:
  /// **'Search by code or route...'**
  String get searchTrips;

  /// No description provided for @noTripResults.
  ///
  /// In en, this message translates to:
  /// **'No trips match your search'**
  String get noTripResults;

  /// No description provided for @tripActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tripActive;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripCompleted;

  /// No description provided for @selectSettlementHint.
  ///
  /// In en, this message translates to:
  /// **'Select type...'**
  String get selectSettlementHint;

  /// No description provided for @settlementTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement Type'**
  String get settlementTypeTitle;

  /// No description provided for @settlementRoadFeesClient.
  ///
  /// In en, this message translates to:
  /// **'Road Fees — Client'**
  String get settlementRoadFeesClient;

  /// No description provided for @settlementRoadFeesVendors.
  ///
  /// In en, this message translates to:
  /// **'Road Fees — Vendors'**
  String get settlementRoadFeesVendors;

  /// No description provided for @settlementCrossBorder.
  ///
  /// In en, this message translates to:
  /// **'Cross Border'**
  String get settlementCrossBorder;

  /// No description provided for @settlementFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get settlementFuel;

  /// No description provided for @settlementFuelGloss.
  ///
  /// In en, this message translates to:
  /// **'تموين'**
  String get settlementFuelGloss;

  /// No description provided for @settlementLicensing.
  ///
  /// In en, this message translates to:
  /// **'Licensing'**
  String get settlementLicensing;

  /// No description provided for @settlementLicensingGloss.
  ///
  /// In en, this message translates to:
  /// **'تراخيص'**
  String get settlementLicensingGloss;

  /// No description provided for @settlementPermits.
  ///
  /// In en, this message translates to:
  /// **'Permits'**
  String get settlementPermits;

  /// No description provided for @settlementPermitsGloss.
  ///
  /// In en, this message translates to:
  /// **'تصاريح'**
  String get settlementPermitsGloss;

  /// No description provided for @settlementTransportFees.
  ///
  /// In en, this message translates to:
  /// **'Transport Fees'**
  String get settlementTransportFees;

  /// No description provided for @settlementMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get settlementMaintenance;

  /// No description provided for @amountEgpLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (EGP)'**
  String get amountEgpLabel;

  /// No description provided for @balanceAfterPreview.
  ///
  /// In en, this message translates to:
  /// **'Balance after: {amount}'**
  String balanceAfterPreview(String amount);

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any notes...'**
  String get notesHint;

  /// No description provided for @attachmentsOptional.
  ///
  /// In en, this message translates to:
  /// **'Attachments (optional)'**
  String get attachmentsOptional;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @attachmentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String attachmentCount(int count);

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @selectTripError.
  ///
  /// In en, this message translates to:
  /// **'Please select a trip'**
  String get selectTripError;

  /// No description provided for @selectSettlementError.
  ///
  /// In en, this message translates to:
  /// **'Please select a settlement type'**
  String get selectSettlementError;

  /// No description provided for @ineligibleTripError.
  ///
  /// In en, this message translates to:
  /// **'This trip cannot be used for an expense'**
  String get ineligibleTripError;

  /// No description provided for @attachmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the attachment.'**
  String get attachmentFailed;

  /// No description provided for @expenseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record the expense.'**
  String get expenseFailed;

  /// No description provided for @confirmExpense.
  ///
  /// In en, this message translates to:
  /// **'Confirm Expense'**
  String get confirmExpense;

  /// No description provided for @confirmExpenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will be deducted from your balance'**
  String get confirmExpenseSubtitle;

  /// No description provided for @deduction.
  ///
  /// In en, this message translates to:
  /// **'DEDUCTION'**
  String get deduction;

  /// No description provided for @settlementType.
  ///
  /// In en, this message translates to:
  /// **'Settlement Type'**
  String get settlementType;

  /// No description provided for @trip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get trip;

  /// No description provided for @balanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance After'**
  String get balanceAfter;

  /// No description provided for @balanceSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance change'**
  String get balanceSnapshotTitle;

  /// No description provided for @historyBalanceBefore.
  ///
  /// In en, this message translates to:
  /// **'Balance before'**
  String get historyBalanceBefore;

  /// No description provided for @historyBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get historyBalanceAfter;

  /// No description provided for @historyBalanceNoChange.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get historyBalanceNoChange;

  /// No description provided for @historyBalanceNotCreditedYet.
  ///
  /// In en, this message translates to:
  /// **'Not credited yet'**
  String get historyBalanceNotCreditedYet;

  /// No description provided for @historyBalanceNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get historyBalanceNotRecorded;

  /// No description provided for @historyBalanceExpenseNote.
  ///
  /// In en, this message translates to:
  /// **'Deducted when recorded.'**
  String get historyBalanceExpenseNote;

  /// No description provided for @historyBalanceRoadNote.
  ///
  /// In en, this message translates to:
  /// **'Road expenses don\'t affect your balance.'**
  String get historyBalanceRoadNote;

  /// No description provided for @historyBalanceCreditAfterYouApprove.
  ///
  /// In en, this message translates to:
  /// **'Credited after you approve.'**
  String get historyBalanceCreditAfterYouApprove;

  /// No description provided for @historyBalanceCreditAfterApproval.
  ///
  /// In en, this message translates to:
  /// **'Credited after approval.'**
  String get historyBalanceCreditAfterApproval;

  /// No description provided for @historyBalanceCreditedWhenApproved.
  ///
  /// In en, this message translates to:
  /// **'Credited when approved.'**
  String get historyBalanceCreditedWhenApproved;

  /// No description provided for @historyBalanceNeverCredited.
  ///
  /// In en, this message translates to:
  /// **'Rejected, so it was never credited.'**
  String get historyBalanceNeverCredited;

  /// No description provided for @historyBalanceSentPending.
  ///
  /// In en, this message translates to:
  /// **'Deducted when sent. Returned to your balance if rejected.'**
  String get historyBalanceSentPending;

  /// No description provided for @historyBalanceSent.
  ///
  /// In en, this message translates to:
  /// **'Deducted when sent.'**
  String get historyBalanceSent;

  /// No description provided for @historyBalanceSentReturned.
  ///
  /// In en, this message translates to:
  /// **'Deducted when sent, then returned to your balance after rejection.'**
  String get historyBalanceSentReturned;

  /// No description provided for @historyBalanceWithdrawPending.
  ///
  /// In en, this message translates to:
  /// **'Deducted when requested. Returned to your balance if rejected.'**
  String get historyBalanceWithdrawPending;

  /// No description provided for @historyBalanceWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Deducted when requested.'**
  String get historyBalanceWithdraw;

  /// No description provided for @historyBalanceWithdrawReturned.
  ///
  /// In en, this message translates to:
  /// **'Deducted when requested, then returned to your balance after rejection.'**
  String get historyBalanceWithdrawReturned;

  /// No description provided for @historyAmountReturned.
  ///
  /// In en, this message translates to:
  /// **'Amount returned to your balance'**
  String get historyAmountReturned;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirmDeduction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deduction'**
  String get confirmDeduction;

  /// No description provided for @expenseRecorded.
  ///
  /// In en, this message translates to:
  /// **'Expense Recorded'**
  String get expenseRecorded;

  /// No description provided for @expenseDeducted.
  ///
  /// In en, this message translates to:
  /// **'{expense} has been deducted from your balance'**
  String expenseDeducted(String expense);

  /// No description provided for @amountDeducted.
  ///
  /// In en, this message translates to:
  /// **'Amount Deducted'**
  String get amountDeducted;

  /// No description provided for @newBalance.
  ///
  /// In en, this message translates to:
  /// **'New Balance'**
  String get newBalance;

  /// No description provided for @tripCode.
  ///
  /// In en, this message translates to:
  /// **'Trip Code'**
  String get tripCode;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @recordingExpense.
  ///
  /// In en, this message translates to:
  /// **'Recording expense'**
  String get recordingExpense;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get pendingApprovals;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @fromVault.
  ///
  /// In en, this message translates to:
  /// **'From Vault'**
  String get fromVault;

  /// No description provided for @fromDrivers.
  ///
  /// In en, this message translates to:
  /// **'From Drivers'**
  String get fromDrivers;

  /// No description provided for @roadExpenses.
  ///
  /// In en, this message translates to:
  /// **'Road Expenses'**
  String get roadExpenses;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'No pending approvals'**
  String get noPendingApprovals;

  /// No description provided for @receivedFromVault.
  ///
  /// In en, this message translates to:
  /// **'Received from Vault'**
  String get receivedFromVault;

  /// No description provided for @driversVault.
  ///
  /// In en, this message translates to:
  /// **'Drivers Vault'**
  String get driversVault;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approveCashReceipt.
  ///
  /// In en, this message translates to:
  /// **'Approve Cash Receipt'**
  String get approveCashReceipt;

  /// No description provided for @vaultSentFunds.
  ///
  /// In en, this message translates to:
  /// **'Vault sent you custody funds'**
  String get vaultSentFunds;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @approveCashFromDriver.
  ///
  /// In en, this message translates to:
  /// **'Approve Cash from Driver'**
  String get approveCashFromDriver;

  /// No description provided for @driverSentCash.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you cash'**
  String driverSentCash(String name);

  /// No description provided for @receivedFromDriver.
  ///
  /// In en, this message translates to:
  /// **'Received from {name}'**
  String receivedFromDriver(String name);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @roadExpenseApproval.
  ///
  /// In en, this message translates to:
  /// **'Road Expense Approval'**
  String get roadExpenseApproval;

  /// No description provided for @adminSubmittedExpense.
  ///
  /// In en, this message translates to:
  /// **'Admin submitted this expense for your confirmation'**
  String get adminSubmittedExpense;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'TOTAL AMOUNT'**
  String get totalAmount;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @submittedBy.
  ///
  /// In en, this message translates to:
  /// **'Submitted by'**
  String get submittedBy;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'TRIP DETAILS'**
  String get tripDetails;

  /// No description provided for @tripsPerAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} trips · {amount} / trip'**
  String tripsPerAmount(int count, String amount);

  /// No description provided for @tripNumber.
  ///
  /// In en, this message translates to:
  /// **'Trip {number}'**
  String tripNumber(int number);

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @rejectExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject expense?'**
  String get rejectExpenseTitle;

  /// No description provided for @rejectExpenseMessage.
  ///
  /// In en, this message translates to:
  /// **'This will notify the admin that you have rejected {reference}.'**
  String rejectExpenseMessage(String reference);

  /// No description provided for @yesReject.
  ///
  /// In en, this message translates to:
  /// **'Yes, Reject'**
  String get yesReject;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @filterExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get filterExpenses;

  /// No description provided for @filterSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get filterSent;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today — {date}'**
  String historyToday(String date);

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday — {date}'**
  String historyYesterday(String date);

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}'**
  String sentTo(String name);

  /// No description provided for @pendingFrom.
  ///
  /// In en, this message translates to:
  /// **'Pending — from {name}'**
  String pendingFrom(String name);

  /// No description provided for @pendingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pending confirm'**
  String get pendingConfirm;

  /// No description provided for @awaitingYourApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your approval'**
  String get awaitingYourApproval;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get recorded;

  /// No description provided for @expenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetails;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @historyDeducted.
  ///
  /// In en, this message translates to:
  /// **'DEDUCTED'**
  String get historyDeducted;

  /// No description provided for @historyDebit.
  ///
  /// In en, this message translates to:
  /// **'DEBIT'**
  String get historyDebit;

  /// No description provided for @historyCredit.
  ///
  /// In en, this message translates to:
  /// **'CREDIT'**
  String get historyCredit;

  /// No description provided for @historyTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get historyTimeline;

  /// No description provided for @timelineCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get timelineCreated;

  /// No description provided for @timelineStillPending.
  ///
  /// In en, this message translates to:
  /// **'Still pending'**
  String get timelineStillPending;

  /// No description provided for @historyTimelineSince.
  ///
  /// In en, this message translates to:
  /// **'{status} · since {time}'**
  String historyTimelineSince(String status, String time);

  /// No description provided for @historyTimelineCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get historyTimelineCurrent;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your history.'**
  String get historyLoadError;

  /// No description provided for @historySelectTrips.
  ///
  /// In en, this message translates to:
  /// **'Select trips'**
  String get historySelectTrips;

  /// No description provided for @historyTripsDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Done} other{Done · {count}}}'**
  String historyTripsDone(int count);

  /// No description provided for @historyTripsSelectedSection.
  ///
  /// In en, this message translates to:
  /// **'Selected · {count}'**
  String historyTripsSelectedSection(int count);

  /// No description provided for @historyTripsListSection.
  ///
  /// In en, this message translates to:
  /// **'Trips · {count}'**
  String historyTripsListSection(int count);

  /// No description provided for @historyTripCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip} other{{count} trips}}'**
  String historyTripCount(int count);

  /// No description provided for @historyClearTrips.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClearTrips;

  /// No description provided for @historyRelatedTrips.
  ///
  /// In en, this message translates to:
  /// **'Related trips'**
  String get historyRelatedTrips;

  /// No description provided for @historyRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh'**
  String get historyRefreshFailed;

  /// No description provided for @historyRefreshRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get historyRefreshRetry;

  /// No description provided for @historyRemoveFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove filter: {label}'**
  String historyRemoveFilter(String label);

  /// No description provided for @historyDateRangeValue.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String historyDateRangeValue(String start, String end);

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @driverId.
  ///
  /// In en, this message translates to:
  /// **'Driver ID'**
  String get driverId;

  /// No description provided for @requestNumber.
  ///
  /// In en, this message translates to:
  /// **'Request number'**
  String get requestNumber;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @expenseType.
  ///
  /// In en, this message translates to:
  /// **'Expense type'**
  String get expenseType;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @myBalance.
  ///
  /// In en, this message translates to:
  /// **'My Balance'**
  String get myBalance;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again.'**
  String get logoutMessage;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t log out. You are still signed in. Please try again.'**
  String get logoutFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @profileQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get profileQuickAccess;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileBadgeId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get profileBadgeId;

  /// No description provided for @profileBadgeVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get profileBadgeVault;

  /// No description provided for @profileBadgeBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get profileBadgeBalance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @approvalFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this approval.'**
  String get approvalFailed;

  /// No description provided for @homeAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get homeAvailableBalance;

  /// No description provided for @homeTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get homeTotalBalance;

  /// No description provided for @homeFrozenBalance.
  ///
  /// In en, this message translates to:
  /// **'Frozen Balance'**
  String get homeFrozenBalance;

  /// No description provided for @homeLimitUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of limit used'**
  String homeLimitUsed(String percent);

  /// No description provided for @homeRemainingLimit.
  ///
  /// In en, this message translates to:
  /// **'Remaining Limit'**
  String get homeRemainingLimit;

  /// No description provided for @homeActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get homeActiveTrip;

  /// No description provided for @homeNoActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'No Active Trip'**
  String get homeNoActiveTrip;

  /// No description provided for @homeNoActiveTripHint.
  ///
  /// In en, this message translates to:
  /// **'Expenses can be recorded once a trip is active.'**
  String get homeNoActiveTripHint;

  /// No description provided for @homeActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get homeActions;

  /// No description provided for @homeViewAllApprovals.
  ///
  /// In en, this message translates to:
  /// **'View All Approvals'**
  String get homeViewAllApprovals;

  /// No description provided for @homeAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get homeAllCaughtUp;

  /// No description provided for @homeRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get homeRecentTransactions;

  /// No description provided for @notificationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsFilterUnread;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Updates about cash, approvals, and expenses will appear here.'**
  String get notificationsEmptyHint;

  /// No description provided for @notificationsNoUnread.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get notificationsNoUnread;

  /// No description provided for @notificationsNoUnreadHint.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsNoUnreadHint;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications.'**
  String get notificationsLoadError;

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// No description provided for @notificationVaultPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault cash awaiting your approval'**
  String get notificationVaultPendingTitle;

  /// No description provided for @notificationIncomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash from {name} awaiting your approval'**
  String notificationIncomingTitle(String name);

  /// No description provided for @notificationSentApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} confirmed your transfer of {amount}'**
  String notificationSentApprovedTitle(String name, String amount);

  /// No description provided for @notificationSentRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} rejected your transfer of {amount}'**
  String notificationSentRejectedTitle(String name, String amount);

  /// No description provided for @notificationTransferSentTitle.
  ///
  /// In en, this message translates to:
  /// **'You sent {amount} to {name}'**
  String notificationTransferSentTitle(String amount, String name);

  /// No description provided for @notificationTransferSentBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation · {reference}'**
  String notificationTransferSentBody(String reference);

  /// No description provided for @notificationTransferConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed · {reference}'**
  String notificationTransferConfirmedBody(String reference);

  /// No description provided for @notificationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get notificationsSearchHint;

  /// No description provided for @notificationsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get notificationsClearSearch;

  /// No description provided for @notificationsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching notifications'**
  String get notificationsNoResults;

  /// No description provided for @notificationsNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different word or clear the search.'**
  String get notificationsNoResultsHint;

  /// No description provided for @notificationRoadPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Road expense needs your confirmation'**
  String get notificationRoadPendingTitle;

  /// No description provided for @notificationExpenseRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded'**
  String get notificationExpenseRecordedTitle;

  /// No description provided for @notificationAmountReference.
  ///
  /// In en, this message translates to:
  /// **'{amount} · {reference}'**
  String notificationAmountReference(String amount, String reference);

  /// No description provided for @notificationRefundedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} returned to your balance · {reference}'**
  String notificationRefundedBody(String amount, String reference);

  /// No description provided for @notificationDeductedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} deducted · {reference}'**
  String notificationDeductedBody(String amount, String reference);

  /// No description provided for @notificationRequestHandled.
  ///
  /// In en, this message translates to:
  /// **'This request was already handled. Showing its current status.'**
  String get notificationRequestHandled;

  /// No description provided for @notificationTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get notificationTargetUnavailable;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineBannerTitle;

  /// No description provided for @offlineBannerHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the Internet to refresh your data.'**
  String get offlineBannerHint;

  /// No description provided for @offlineRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get offlineRetry;

  /// No description provided for @offlineUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Unavailable offline'**
  String get offlineUnavailableTitle;

  /// No description provided for @offlineUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the Internet to load this information.'**
  String get offlineUnavailableHint;

  /// No description provided for @offlineActionRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'An Internet connection is required for this action.'**
  String get offlineActionRequiresInternet;

  /// No description provided for @loginRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Connect to the Internet to sign in.'**
  String get loginRequiresInternet;

  /// No description provided for @offlineSectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable while offline'**
  String get offlineSectionUnavailable;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @approvalsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search approvals'**
  String get approvalsSearchHint;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get historySearchHint;

  /// No description provided for @notificationsFilterRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationsFilterRead;

  /// No description provided for @notificationsNoRead.
  ///
  /// In en, this message translates to:
  /// **'No read notifications'**
  String get notificationsNoRead;

  /// No description provided for @notificationsNoReadHint.
  ///
  /// In en, this message translates to:
  /// **'Read notifications will appear here.'**
  String get notificationsNoReadHint;

  /// No description provided for @filterCashTransfers.
  ///
  /// In en, this message translates to:
  /// **'Cash Transfers'**
  String get filterCashTransfers;

  /// No description provided for @filterVaultTransactions.
  ///
  /// In en, this message translates to:
  /// **'Vault Transactions'**
  String get filterVaultTransactions;

  /// No description provided for @filterAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get filterAllTransactions;

  /// No description provided for @dateFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get dateFilterAll;

  /// No description provided for @dateFilterDay.
  ///
  /// In en, this message translates to:
  /// **'Specific Day'**
  String get dateFilterDay;

  /// No description provided for @dateFilterRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateFilterRange;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @tripFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Trips'**
  String get tripFilterAll;

  /// No description provided for @tripFilterSpecific.
  ///
  /// In en, this message translates to:
  /// **'Specific Trip'**
  String get tripFilterSpecific;

  /// No description provided for @selectTrip.
  ///
  /// In en, this message translates to:
  /// **'Select trip'**
  String get selectTrip;

  /// No description provided for @invalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'Start date must be on or before the end date.'**
  String get invalidDateRange;

  /// No description provided for @tripRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a trip to apply this filter.'**
  String get tripRequired;

  /// No description provided for @historyTripsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip selected} other{{count} trips selected}}'**
  String historyTripsSelected(int count);

  /// No description provided for @historyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get historyNoResults;

  /// No description provided for @historyNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or reset the filters.'**
  String get historyNoResultsHint;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @approvalsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching approvals'**
  String get approvalsNoResults;

  /// No description provided for @approvalsNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or reset the filters.'**
  String get approvalsNoResultsHint;

  /// No description provided for @filterTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get filterTransactionType;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @filterTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get filterTrip;

  /// No description provided for @filterReadStatus.
  ///
  /// In en, this message translates to:
  /// **'Read status'**
  String get filterReadStatus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
