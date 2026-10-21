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
  String get balanceAfter => 'الرصيد بعد الخصم';

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
  String get rejectExpenseTitle => 'رفض المصروف؟';

  @override
  String rejectExpenseMessage(String reference) {
    return 'سيصل إشعار إلى المسؤول بأنك رفضت $reference.';
  }

  @override
  String get yesReject => 'نعم، رفض';

  @override
  String get approved => 'تمت الموافقة';

  @override
  String get rejected => 'مرفوض';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navHistory => 'السجل';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مصروفات',
      one: 'مصروف واحد',
    );
    return '$_temp0';
  }

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
  String get historyDeducted => 'تم الخصم';

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
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String profileBalance(String amount) {
    return 'الرصيد: $amount';
  }

  @override
  String profileIdentity(String id, String vault) {
    return '$id · $vault';
  }

  @override
  String get approvalFailed => 'تعذر تحديث هذه الموافقة.';
}
