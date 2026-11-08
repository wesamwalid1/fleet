// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get driverPortal => 'بوابة السائق';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get signInSubtitle => 'سجّل الدخول إلى حساب السائق';

  @override
  String get emailHint => 'البريد الإلكتروني للسائق';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get contactVaultManager => 'هل تواجه مشكلة؟ تواصل مع مدير الخزنة';

  @override
  String get emptyEmail => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get invalidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get emptyPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get invalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get unexpectedError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get goodMorning => 'صباح الخير 👋';

  @override
  String get goodAfternoon => 'طاب نهارك 👋';

  @override
  String get goodEvening => 'مساء الخير 👋';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get homeLoadError => 'تعذر تحميل ملفك.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get balance => 'الرصيد';

  @override
  String get charge => 'العهدة';

  @override
  String get maxLimit => 'الحد الأقصى';

  @override
  String get egp => 'ج.م';

  @override
  String get loadingBalance => 'جارٍ تحميل الرصيد';

  @override
  String get balanceLoadError => 'تعذر تحميل الرصيد.';

  @override
  String get sendCash => 'إرسال نقد';

  @override
  String get sendCashTitle => 'إرسال نقد إلى سائق';

  @override
  String get sendCashSubtitle => 'اختر السائق وأدخل المبلغ';

  @override
  String get sendCashStepRecipient => 'المستلم';

  @override
  String get sendCashStepAmount => 'المبلغ';

  @override
  String get sendCashStepReview => 'مراجعة';

  @override
  String get sendCashContinue => 'متابعة';

  @override
  String get sendCashEdit => 'تعديل';

  @override
  String get sendCashReviewHeading => 'مراجعة التحويل';

  @override
  String get sendCashRecipientLabel => 'المستلم';

  @override
  String get sendCashSearchHint => 'ابحث بالاسم أو الرمز';

  @override
  String get sendCashNoSearchResults => 'لا يوجد سائقون مطابقون';

  @override
  String sendCashStepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get requestCash => 'طلب نقد';

  @override
  String get withdraw => 'تسليم نقد';

  @override
  String get actionComingSoon => 'سيكون هذا الإجراء متاحاً قريباً.';

  @override
  String get requestCashTitle => 'طلب نقد';

  @override
  String get requestCashSubtitle => 'اطلب مالاً من خزينة الشركة';

  @override
  String get withdrawTitle => 'تسليم نقد';

  @override
  String get withdrawSubtitle => 'أعد النقد غير المستخدم إلى خزينة الشركة';

  @override
  String get availableRequestCapacity => 'السعة المتاحة للطلب';

  @override
  String get requestCashTotalBalance => 'إجمالي الرصيد';

  @override
  String get pendingRequestCash => 'طلبات النقد المعلّقة';

  @override
  String get requestCashSummaryLoadError => 'تعذر تحميل بيانات طلب النقد.';

  @override
  String get withdrawAvailableBalance => 'الرصيد المتاح';

  @override
  String get withdrawAmountLabel => 'مبلغ التسليم';

  @override
  String get withdrawBalanceAfter => 'الرصيد بعد التسليم';

  @override
  String get withdrawSummaryLoadError => 'تعذر تحميل بيانات التسليم.';

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get submitWithdraw => 'إرسال التسليم';

  @override
  String get exceedsRequestCapacityError =>
      'المبلغ أكبر من السعة المتاحة للطلب';

  @override
  String get exceedsAvailableBalanceError => 'المبلغ أكبر من رصيدك المتاح';

  @override
  String get requestCashFailed =>
      'تعذر إرسال طلب النقد. يرجى المحاولة مرة أخرى.';

  @override
  String get withdrawFailed =>
      'تعذر إرسال طلب التسليم. يرجى المحاولة مرة أخرى.';

  @override
  String get cashRequestSubmittedTitle => 'تم إرسال الطلب!';

  @override
  String cashRequestSubmittedDetail(String amount, String number) {
    return 'تم إرسال $amount برقم $number';
  }

  @override
  String get historyRequestCash => 'طلب نقد';

  @override
  String get historyWithdraw => 'تسليم نقد';

  @override
  String get historyPendingBalanceUnchanged => 'الرصيد لم يتغير';

  @override
  String get notificationRequestCashPendingTitle => 'تم إرسال طلب النقد';

  @override
  String get notificationRequestCashApprovedTitle =>
      'تمت الموافقة على طلب النقد';

  @override
  String get notificationRequestCashRejectedTitle => 'تم رفض طلب النقد';

  @override
  String get notificationWithdrawPendingTitle => 'تم إرسال طلب التسليم';

  @override
  String get notificationWithdrawApprovedTitle =>
      'تمت الموافقة على طلب التسليم';

  @override
  String get notificationWithdrawRejectedTitle => 'تم رفض طلب التسليم';

  @override
  String notificationRequestCashPendingBody(String amount, String reference) {
    return 'طلب $amount برقم $reference بانتظار الموافقة';
  }

  @override
  String notificationRequestCashApprovedBody(String amount, String reference) {
    return 'تمت إضافة $amount للطلب $reference';
  }

  @override
  String notificationRequestCashRejectedBody(String amount, String reference) {
    return 'تم رفض طلب $amount برقم $reference';
  }

  @override
  String notificationWithdrawPendingBody(String amount, String reference) {
    return 'تسليم $amount برقم $reference بانتظار الموافقة';
  }

  @override
  String notificationWithdrawApprovedBody(String amount, String reference) {
    return 'تم إرجاع $amount للتسليم $reference';
  }

  @override
  String notificationWithdrawRejectedBody(String amount, String reference) {
    return 'تم رفض تسليم $amount برقم $reference';
  }

  @override
  String get selectDriver => 'اختر سائقاً';

  @override
  String get noDrivers => 'لا يوجد سائقون';

  @override
  String yourBalance(String amount) {
    return 'رصيدك: $amount';
  }

  @override
  String get yourBalanceAfter => 'رصيدك بعد العملية';

  @override
  String get amount => 'المبلغ';

  @override
  String mustApprove(String name) {
    return 'يجب أن يوافق $name لإتمام العملية';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String get sendingRequest => 'جارٍ إرسال الطلب';

  @override
  String get requestSent => 'تم إرسال الطلب!';

  @override
  String requestSentDetail(String amount, String name) {
    return 'تم إرسال طلب بقيمة $amount إلى $name';
  }

  @override
  String waitingForApproval(String name) {
    return 'بانتظار موافقة $name';
  }

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get close => 'إغلاق';

  @override
  String get goHome => 'العودة للرئيسية';

  @override
  String get viewTransaction => 'عرض الحركة';

  @override
  String get selectDriverError => 'اختر سائقاً';

  @override
  String get invalidAmountError => 'أدخل مبلغاً أكبر من صفر';

  @override
  String get insufficientBalanceError => 'المبلغ أكبر من رصيدك المتاح';

  @override
  String get sendCashFailed => 'تعذر إرسال الطلب.';

  @override
  String driverCodeBalance(String code, String balance) {
    return '$code · $balance';
  }

  @override
  String get recordExpense => 'تسجيل مصروف';

  @override
  String get recordExpenseSubtitle => 'سيُخصم من رصيدك';

  @override
  String get selectTripHint => 'اختر الرحلة...';

  @override
  String get selectTripTitle => 'اختر الرحلة';

  @override
  String tripsAssigned(int count) {
    return '$count رحلات مخصصة لك';
  }

  @override
  String get searchTrips => 'ابحث بالرمز أو المسار...';

  @override
  String get noTripResults => 'لا توجد رحلات مطابقة';

  @override
  String get tripActive => 'نشطة';

  @override
  String get tripCompleted => 'مكتملة';

  @override
  String get selectSettlementHint => 'اختر النوع...';

  @override
  String get settlementTypeTitle => 'نوع التسوية';

  @override
  String get settlementRoadFeesClient => 'رسوم الطريق — العميل';

  @override
  String get settlementRoadFeesVendors => 'رسوم الطريق — الموردين';

  @override
  String get settlementCrossBorder => 'عبور الحدود';

  @override
  String get settlementFuel => 'تموين';

  @override
  String get settlementFuelGloss => '';

  @override
  String get settlementLicensing => 'تراخيص';

  @override
  String get settlementLicensingGloss => '';

  @override
  String get settlementPermits => 'تصاريح';

  @override
  String get settlementPermitsGloss => '';

  @override
  String get settlementTransportFees => 'رسوم النقل';

  @override
  String get settlementMaintenance => 'صيانة';

  @override
  String get amountEgpLabel => 'المبلغ (ج.م)';

  @override
  String balanceAfterPreview(String amount) {
    return 'الرصيد بعد العملية: $amount';
  }

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get notesHint => 'أضف أي ملاحظات...';

  @override
  String get attachmentsOptional => 'المرفقات (اختياري)';

  @override
  String get attachments => 'المرفقات';

  @override
  String attachmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملفات',
      one: 'ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get file => 'ملف';

  @override
  String get removeAttachment => 'إزالة المرفق';

  @override
  String get selectTripError => 'يرجى اختيار رحلة';

  @override
  String get selectSettlementError => 'يرجى اختيار نوع التسوية';

  @override
  String get ineligibleTripError => 'لا يمكن استخدام هذه الرحلة لمصروف';

  @override
  String get attachmentFailed => 'تعذر إضافة المرفق.';

  @override
  String get expenseFailed => 'تعذر تسجيل المصروف.';

  @override
  String get confirmExpense => 'تأكيد المصروف';

  @override
  String get confirmExpenseSubtitle => 'سيتم خصم هذا المبلغ من رصيدك';

  @override
  String get deduction => 'الخصم';

  @override
  String get settlementType => 'نوع التسوية';

  @override
  String get trip => 'الرحلة';

  @override
  String get balanceAfter => 'الرصيد بعد';

  @override
  String get balanceSnapshotTitle => 'تغيّر الرصيد';

  @override
  String get historyBalanceBefore => 'الرصيد قبل';

  @override
  String get historyBalanceAfter => 'الرصيد بعد';

  @override
  String get historyBalanceNoChange => 'لا تغيير';

  @override
  String get historyBalanceNotCreditedYet => 'لم يضف بعد';

  @override
  String get historyBalanceNotRecorded => 'غير مسجل';

  @override
  String get historyBalanceExpenseNote => 'خصم عند التسجيل.';

  @override
  String get historyBalanceRoadNote => 'مصروفات الطريق لا تؤثر على رصيدك.';

  @override
  String get historyBalanceCreditAfterYouApprove =>
      'يضاف إلى رصيدك بعد موافقتك.';

  @override
  String get historyBalanceCreditAfterApproval =>
      'يضاف إلى رصيدك بعد الموافقة.';

  @override
  String get historyBalanceCreditedWhenApproved => 'أضيف عند الموافقة.';

  @override
  String get historyBalanceNeverCredited => 'رفض، لذلك لم يضف إلى رصيدك.';

  @override
  String get historyBalanceSentPending =>
      'خصم عند الإرسال، ويعاد إلى رصيدك إذا رفض.';

  @override
  String get historyBalanceSent => 'خصم عند الإرسال.';

  @override
  String get historyBalanceSentReturned =>
      'خصم عند الإرسال، ثم أعيد إلى رصيدك بعد الرفض.';

  @override
  String get historyBalanceWithdrawPending =>
      'خصم عند الطلب، ويعاد إلى رصيدك إذا رفض.';

  @override
  String get historyBalanceWithdraw => 'خصم عند الطلب.';

  @override
  String get historyBalanceWithdrawReturned =>
      'خصم عند الطلب، ثم أعيد إلى رصيدك بعد الرفض.';

  @override
  String get historyAmountReturned => 'أعيد المبلغ إلى رصيدك';

  @override
  String get back => 'رجوع';

  @override
  String get confirmDeduction => 'تأكيد الخصم';

  @override
  String get expenseRecorded => 'تم تسجيل المصروف';

  @override
  String expenseDeducted(String expense) {
    return 'تم خصم $expense من رصيدك';
  }

  @override
  String get amountDeducted => 'المبلغ المخصوم';

  @override
  String get newBalance => 'الرصيد الجديد';

  @override
  String get tripCode => 'رمز الرحلة';

  @override
  String get reference => 'المرجع';

  @override
  String get done => 'تم';

  @override
  String get recordingExpense => 'جارٍ تسجيل المصروف';

  @override
  String get approvals => 'الموافقات';

  @override
  String get pendingApprovals => 'الموافقات المعلقة';

  @override
  String get recent => 'الأخيرة';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get yesterday => 'أمس';

  @override
  String pendingCount(int count) {
    return '$count قيد الانتظار';
  }

  @override
  String get filterAll => 'الكل';

  @override
  String get fromVault => 'من الخزينة';

  @override
  String get fromDrivers => 'من السائقين';

  @override
  String get roadExpenses => 'مصاريف الطريق';

  @override
  String get actionRequired => 'إجراء مطلوب';

  @override
  String get approvalsNeedsDecision => 'يحتاج إلى قرارك';

  @override
  String get approvalsAlreadyDecided => 'تمّ البت فيه';

  @override
  String get approvalsNoPendingHint => 'لا يوجد ما يحتاج إلى قرار الآن.';

  @override
  String get approvalsAllCaughtUp => 'أنت على اطلاع بكل شيء';

  @override
  String get approvalsLoadError => 'تعذر تحميل الموافقات.';

  @override
  String get approvalsRetry => 'إعادة المحاولة';

  @override
  String get approvalCreditsWhenApproved => 'يُضاف إلى رصيدك عند الموافقة.';

  @override
  String get approvalCreditedToBalance => 'أُضيف إلى رصيدك.';

  @override
  String get approvalNotCreditedToBalance => 'لم يُضف إلى رصيدك.';

  @override
  String get approvalNoBalanceChange => 'لا تغيير';

  @override
  String get approvalRoadBalanceNote => 'مصروفات الطريق لا تؤثر على رصيدك.';

  @override
  String get completed => 'مكتملة';

  @override
  String get noPendingApprovals => 'لا توجد موافقات معلّقة';

  @override
  String get receivedFromVault => 'استلام من الخزينة';

  @override
  String get driversVault => 'خزينة السائقين';

  @override
  String get justNow => 'الآن';

  @override
  String get now => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String get approve => 'موافقة';

  @override
  String get approveCashReceipt => 'اعتماد استلام النقدية';

  @override
  String get vaultSentFunds => 'أرسلت لك الخزينة أموال العهدة';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get date => 'التاريخ';

  @override
  String get approveCashFromDriver => 'اعتماد نقدية من سائق';

  @override
  String driverSentCash(String name) {
    return 'أرسل لك $name نقدية';
  }

  @override
  String receivedFromDriver(String name) {
    return 'استلام من $name';
  }

  @override
  String get decline => 'رفض';

  @override
  String get roadExpenseApproval => 'اعتماد مصروف طريق';

  @override
  String get adminSubmittedExpense => 'أرسل المسؤول هذا المصروف لتأكيدك';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get period => 'الفترة';

  @override
  String get submittedBy => 'مقدَّم من';

  @override
  String get vehicle => 'المركبة';

  @override
  String get tripDetails => 'تفاصيل الرحلات';

  @override
  String tripsPerAmount(int count, String amount) {
    return '$count رحلات · $amount / رحلة';
  }

  @override
  String tripNumber(int number) {
    return 'رحلة $number';
  }

  @override
  String get grandTotal => 'الإجمالي';

  @override
  String get reject => 'رفض';

  @override
  String get confirm => 'تأكيد';

  @override
  String get rejectExpenseTitle => 'رفض مصروف الطريق؟';

  @override
  String rejectExpenseMessage(String reference) {
    return 'سيتم تعليم $reference كمرفوض. لن يتغيّر رصيدك.';
  }

  @override
  String get yesReject => 'رفض';

  @override
  String get approved => 'تمت الموافقة';

  @override
  String get rejected => 'مرفوض';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navHistory => 'السجل';

  @override
  String get filterExpenses => 'المصروفات';

  @override
  String get filterSent => 'المرسلة';

  @override
  String get filterPending => 'المعلّقة';

  @override
  String historyToday(String date) {
    return 'اليوم — $date';
  }

  @override
  String historyYesterday(String date) {
    return 'أمس — $date';
  }

  @override
  String sentTo(String name) {
    return 'أُرسل إلى $name';
  }

  @override
  String pendingFrom(String name) {
    return 'معلّق — من $name';
  }

  @override
  String get pendingConfirm => 'بانتظار التأكيد';

  @override
  String get awaitingYourApproval => 'بانتظار موافقتك';

  @override
  String get confirmed => 'تم التأكيد';

  @override
  String get recorded => 'مسجّل';

  @override
  String get expenseDetails => 'تفاصيل المصروف';

  @override
  String get transactionDetails => 'تفاصيل الحركة';

  @override
  String get historyDeducted => 'تم الخصم';

  @override
  String get historyDebit => 'مدين';

  @override
  String get historyCredit => 'دائن';

  @override
  String get historyTimeline => 'الجدول الزمني';

  @override
  String get timelineCreated => 'تم الإنشاء';

  @override
  String get timelineStillPending => 'ما زال معلقاً';

  @override
  String historyTimelineSince(String status, String time) {
    return '$status · منذ $time';
  }

  @override
  String get historyTimelineCurrent => 'الحالي';

  @override
  String get historyLoadError => 'تعذر تحميل السجل.';

  @override
  String get historySelectTrips => 'اختر الرحلات';

  @override
  String historyTripsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم · $count',
      zero: 'تم',
    );
    return '$_temp0';
  }

  @override
  String historyTripsSelectedSection(int count) {
    return 'المحددة · $count';
  }

  @override
  String historyTripsListSection(int count) {
    return 'الرحلات · $count';
  }

  @override
  String historyTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة',
      many: '$count رحلة',
      few: '$count رحلات',
      two: 'رحلتان',
      one: 'رحلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get historyClearTrips => 'مسح';

  @override
  String get historyRelatedTrips => 'الرحلات المرتبطة';

  @override
  String get historyRefreshFailed => 'تعذر التحديث';

  @override
  String get historyRefreshRetry => 'إعادة المحاولة';

  @override
  String historyRemoveFilter(String label) {
    return 'إزالة عامل التصفية: $label';
  }

  @override
  String historyDateRangeValue(String start, String end) {
    return '$start – $end';
  }

  @override
  String get recipient => 'المستلم';

  @override
  String get driverId => 'رقم السائق';

  @override
  String get requestNumber => 'رقم الطلب';

  @override
  String get source => 'المصدر';

  @override
  String get expenseType => 'نوع المصروف';

  @override
  String get note => 'ملاحظة';

  @override
  String get noTransactions => 'لا توجد حركات';

  @override
  String get navProfile => 'الملف';

  @override
  String get myBalance => 'رصيدي';

  @override
  String get transactionHistory => 'سجل الحركات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutTitle => 'تسجيل الخروج؟';

  @override
  String get logoutMessage => 'ستحتاج إلى تسجيل الدخول مرة أخرى.';

  @override
  String get logoutFailed =>
      'تعذر تسجيل الخروج. ما زلت مسجلاً الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get profileQuickAccess => 'وصول سريع';

  @override
  String get profileSettings => 'الإعدادات';

  @override
  String get profileAccount => 'الحساب';

  @override
  String get profileBadgeId => 'رقم السائق';

  @override
  String get profileBadgeVault => 'الخزينة';

  @override
  String get profileBadgeBalance => 'الرصيد';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get approvalFailed => 'تعذر تحديث هذه الموافقة.';

  @override
  String get homeAvailableBalance => 'الرصيد المتاح';

  @override
  String get homeTotalBalance => 'إجمالي الرصيد';

  @override
  String get homeFrozenBalance => 'الرصيد المجمّد';

  @override
  String homeLimitUsed(String percent) {
    return 'تم استخدام $percent% من الحد';
  }

  @override
  String get homeRemainingLimit => 'الحد المتبقي';

  @override
  String get homeActiveTrip => 'الرحلة النشطة';

  @override
  String get homeNoActiveTrip => 'لا توجد رحلة نشطة';

  @override
  String get homeNoActiveTripHint => 'يمكن تسجيل المصروفات عند وجود رحلة نشطة.';

  @override
  String get homeActions => 'الإجراءات';

  @override
  String get homeViewAllApprovals => 'عرض كل الموافقات';

  @override
  String get homeAllCaughtUp => 'لا توجد طلبات بانتظارك';

  @override
  String get homeRecentTransactions => 'أحدث الحركات';

  @override
  String get notificationsFilterUnread => 'غير المقروءة';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد';

  @override
  String get notificationsEmptyHint =>
      'ستظهر هنا التحديثات الخاصة بالنقدية والموافقات والمصروفات.';

  @override
  String get notificationsNoUnread => 'لا توجد إشعارات غير مقروءة';

  @override
  String get notificationsNoUnreadHint => 'لا يوجد ما يحتاج إلى متابعتك.';

  @override
  String get notificationsLoadError => 'تعذر تحميل الإشعارات.';

  @override
  String get notificationsRetry => 'إعادة المحاولة';

  @override
  String get notificationUnread => 'غير مقروء';

  @override
  String get notificationVaultPendingTitle =>
      'نقدية من الخزينة بانتظار موافقتك';

  @override
  String notificationIncomingTitle(String name) {
    return 'نقدية من $name بانتظار موافقتك';
  }

  @override
  String notificationSentApprovedTitle(String name, String amount) {
    return 'أكد $name تحويلك بقيمة $amount';
  }

  @override
  String notificationSentRejectedTitle(String name, String amount) {
    return 'رفض $name تحويلك بقيمة $amount';
  }

  @override
  String notificationTransferSentTitle(String amount, String name) {
    return 'أرسلت $amount إلى $name';
  }

  @override
  String notificationTransferSentBody(String reference) {
    return 'بانتظار التأكيد · $reference';
  }

  @override
  String notificationTransferConfirmedBody(String reference) {
    return 'تم التأكيد · $reference';
  }

  @override
  String get notificationsSearchHint => 'ابحث في الإشعارات';

  @override
  String get notificationsClearSearch => 'مسح البحث';

  @override
  String get notificationsNoResults => 'لا توجد إشعارات مطابقة';

  @override
  String get notificationsNoResultsHint => 'جرّب كلمة أخرى أو امسح البحث.';

  @override
  String get notificationRoadPendingTitle => 'مصروف طريق يحتاج إلى تأكيدك';

  @override
  String get notificationExpenseRecordedTitle => 'تم تسجيل المصروف';

  @override
  String notificationAmountReference(String amount, String reference) {
    return '$amount · $reference';
  }

  @override
  String notificationRefundedBody(String amount, String reference) {
    return 'تمت إعادة $amount إلى رصيدك · $reference';
  }

  @override
  String notificationDeductedBody(String amount, String reference) {
    return 'تم خصم $amount · $reference';
  }

  @override
  String get notificationRequestHandled =>
      'تمت معالجة هذا الطلب بالفعل. يتم عرض حالته الحالية.';

  @override
  String get notificationTargetUnavailable => 'هذا العنصر لم يعد متاحاً.';

  @override
  String get offlineBannerTitle => 'أنت غير متصل';

  @override
  String get offlineBannerHint => 'اتصل بالإنترنت لتحديث بياناتك.';

  @override
  String get offlineRetry => 'إعادة المحاولة';

  @override
  String get offlineUnavailableTitle => 'غير متاح بدون اتصال';

  @override
  String get offlineUnavailableHint => 'اتصل بالإنترنت لتحميل هذه المعلومات.';

  @override
  String get offlineActionRequiresInternet =>
      'يلزم اتصال بالإنترنت لتنفيذ هذا الإجراء.';

  @override
  String get loginRequiresInternet => 'اتصل بالإنترنت لتسجيل الدخول.';

  @override
  String get offlineSectionUnavailable => 'غير متاح أثناء عدم الاتصال';

  @override
  String get filter => 'تصفية';

  @override
  String get filterTransactions => 'تصفية الحركات';

  @override
  String get apply => 'تطبيق';

  @override
  String get applyFilters => 'تطبيق عوامل التصفية';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get approvalsSearchHint => 'ابحث في الموافقات';

  @override
  String get historySearchHint => 'ابحث في الحركات';

  @override
  String get notificationsFilterRead => 'مقروء';

  @override
  String get notificationsNoRead => 'لا توجد إشعارات مقروءة';

  @override
  String get notificationsNoReadHint => 'ستظهر الإشعارات المقروءة هنا.';

  @override
  String get filterCashTransfers => 'التحويلات النقدية';

  @override
  String get filterVaultTransactions => 'معاملات الخزينة';

  @override
  String get filterAllTransactions => 'كل الحركات';

  @override
  String get dateFilterAll => 'كل التواريخ';

  @override
  String get dateFilterDay => 'يوم محدد';

  @override
  String get dateFilterRange => 'نطاق تاريخ';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get tripFilterAll => 'كل الرحلات';

  @override
  String get tripFilterSpecific => 'رحلة محددة';

  @override
  String get selectTrip => 'اختر الرحلة';

  @override
  String get invalidDateRange =>
      'يجب أن يكون تاريخ البدء قبل تاريخ الانتهاء أو مساوياً له.';

  @override
  String get tripRequired => 'اختر رحلة لتطبيق هذا التصفية.';

  @override
  String historyTripsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة محددة',
      many: '$count رحلة محددة',
      few: '$count رحلات محددة',
      two: 'رحلتان محددتان',
      zero: 'لا رحلات محددة',
      one: 'رحلة واحدة محددة',
    );
    return '$_temp0';
  }

  @override
  String get historyNoResults => 'لا توجد حركات مطابقة';

  @override
  String get historyNoResultsHint =>
      'جرّب بحثاً آخر أو أعد تعيين عوامل التصفية.';

  @override
  String get clearFilters => 'مسح عوامل التصفية';

  @override
  String get approvalsNoResults => 'لا توجد موافقات مطابقة';

  @override
  String get approvalsNoResultsHint =>
      'جرّب بحثاً آخر أو أعد تعيين عوامل التصفية.';

  @override
  String get filterTransactionType => 'نوع الحركة';

  @override
  String get filterDate => 'التاريخ';

  @override
  String get filterTrip => 'الرحلة';

  @override
  String get filterReadStatus => 'حالة القراءة';
}
