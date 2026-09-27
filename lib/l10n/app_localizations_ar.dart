// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Eventor';

  @override
  String get backLabel => 'رجوع';

  @override
  String get languageSwitchLabel => 'اللغة';

  @override
  String get continueAction => 'متابعة';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get unknownRouteTitle => 'الصفحة غير موجودة';

  @override
  String unknownRouteMessage(String routeName) {
    return 'لا توجد صفحة باسم \"$routeName\".';
  }

  @override
  String get errorUnexpected => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get errorStorage => 'تعذّر حفظ تغييراتك على هذا الجهاز.';

  @override
  String get errorNetwork => 'لا يوجد اتصال. تحقّق من الإنترنت وأعد المحاولة.';

  @override
  String get errorSessionExpired => 'انتهت جلستك. سجّل الدخول مجددًا للمتابعة.';

  @override
  String get sessionExpiredTitle => 'انتهت جلستك';

  @override
  String get sessionExpiredBody => 'سجّل الدخول مجددًا لتكمل من حيث توقّفت.';

  @override
  String get splashTagline => 'كل ما تحتاجه مناسبتك في مكان واحد';

  @override
  String get splashByline => 'من SYMLOOP';

  @override
  String get skip => 'تخطّي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String sectionProgress(int current, int total) {
    return 'القسم $current من $total';
  }

  @override
  String get onboardingServicesTitle => 'كل الخدمات التي تحتاجها مناسبتك';

  @override
  String get onboardingServicesDescription =>
      'مصوّرون، قاعات، متعهّدو طعام، منسّقو أغانٍ، بائعو زهور ومزيّنون، في مكان واحد.';

  @override
  String get onboardingCompareTitle => 'قارن، ثم احجز بثقة';

  @override
  String get onboardingCompareDescription =>
      'تقييمات حقيقية، أسعار واضحة وتواريخ متاحة. راسل مقدّم الخدمة قبل أن تلتزم.';

  @override
  String get onboardingTrackTitle => 'تابع مناسبتك خطوة بخطوة';

  @override
  String get onboardingTrackDescription =>
      'تابع كل حجز وراقب ميزانيتك مع اقتراب اليوم الكبير.';

  @override
  String get welcomeTitle => 'لنبدأ';

  @override
  String get welcomeSubtitle =>
      'أنشئ حسابًا لتبدأ الحجز، أو سجّل الدخول إن كنت هنا من قبل.';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get welcomeHaveAccount => 'لديّ حساب بالفعل';

  @override
  String get roleSelectionTitle => 'كيف ستستخدم Eventor ؟';

  @override
  String get roleSelectionSubtitle =>
      'هذا يحدّد تجربتك بالكامل في التطبيق. ولا يمكن تغييره لاحقًا.';

  @override
  String get roleClientTitle => 'أخطّط لمناسبة';

  @override
  String get roleClientDescription => 'أجد فريق مناسبتي وأحجزه';

  @override
  String get roleProviderTitle => 'أقدّم خدمة';

  @override
  String get roleProviderDescription => 'أعرض خدماتي وأدير الحجوزات';

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle =>
      'بعض المعلومات فقط، ثم يمكنك البدء بحجز فريق مناسبتك.';

  @override
  String get registerSubtitleProvider =>
      'أخبرنا عن نشاطك، ثم أضف مستنداتك في الخطوة التالية.';

  @override
  String get registerBusinessTitle => 'نشاطك';

  @override
  String get registerBusinessNote => 'يظهر للعملاء في ملفك.';

  @override
  String get registerCreateAccount => 'إنشاء الحساب';

  @override
  String get registerTermsPrefix => 'بالمتابعة، أنت توافق على ';

  @override
  String get registerTermsLink => 'الشروط وسياسة الخصوصية';

  @override
  String get registerTermsSuffix => '.';

  @override
  String get registerHasAccountPrompt => 'لديك حساب بالفعل ؟';

  @override
  String get registerEmailTakenTitle => 'هذا البريد له حساب بالفعل';

  @override
  String get registerEmailTakenBody =>
      'سجّل الدخول بدلًا من ذلك، أو أنشئ حسابًا ببريد آخر.';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get nameLabel => 'الاسم الكامل';

  @override
  String get namePlaceholder => 'أمينة بن علي';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailPlaceholder => 'name@example.com';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phonePlaceholder => '0555 12 34 56';

  @override
  String get phoneHint => '10 أرقام تبدأ بـ 0، أو ‎+213.';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String passwordHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرف على الأقل، مع حرف ورقم.',
      many: '$count حرفًا على الأقل، مع حرف ورقم.',
      few: '$count أحرف على الأقل، مع حرف ورقم.',
      two: 'حرفان على الأقل، مع حرف ورقم.',
      one: 'حرف واحد على الأقل، مع حرف ورقم.',
      zero: 'يجب أن تحتوي على حرف ورقم.',
    );
    return '$_temp0';
  }

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get businessNameLabel => 'اسم النشاط';

  @override
  String get businessNamePlaceholder => 'استوديو لوميار';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get categoryPlaceholder => 'اختر فئة';

  @override
  String get categorySheetTitle => 'اختر فئتك';

  @override
  String get wilayaOptionalLabel => 'الولاية (اختياري)';

  @override
  String get wilayaPlaceholder => 'اختر ولاية';

  @override
  String get wilayaSheetTitle => 'اختر ولايتك';

  @override
  String get wilayaSearchHint => 'ابحث عن ولاية';

  @override
  String get wilayasServedLabel => 'الولايات التي تعمل بها';

  @override
  String get wilayasServedPlaceholder => 'اختر أين تعمل';

  @override
  String get wilayasServedSheetTitle => 'أين تعمل ؟';

  @override
  String get referenceLoadFailed =>
      'تعذّر تحميل القائمة. اضغط لإعادة المحاولة.';

  @override
  String get nameRequired => 'أدخل اسمك الكامل.';

  @override
  String nameTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استخدم $count حرف على الأقل.',
      many: 'استخدم $count حرفًا على الأقل.',
      few: 'استخدم $count أحرف على الأقل.',
      two: 'استخدم حرفين على الأقل.',
      one: 'استخدم حرفًا واحدًا على الأقل.',
      zero: 'أدخل اسمك الكامل.',
    );
    return '$_temp0';
  }

  @override
  String get businessNameRequired => 'أدخل اسم نشاطك.';

  @override
  String get emailRequired => 'أدخل بريدك الإلكتروني.';

  @override
  String get emailInvalid =>
      'أدخل بريدًا إلكترونيًا صحيحًا، مثل name@example.com.';

  @override
  String get emailTaken => 'هذا البريد له حساب بالفعل.';

  @override
  String get phoneRequired => 'أدخل رقم هاتفك.';

  @override
  String get phoneInvalid => 'أدخل 10 أرقام تبدأ بـ 0، أو رقمًا يبدأ بـ ‎+213.';

  @override
  String get phoneTaken => 'رقم الهاتف هذا له حساب بالفعل.';

  @override
  String get passwordRequired => 'أدخل كلمة المرور.';

  @override
  String passwordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استخدم $count حرف على الأقل.',
      many: 'استخدم $count حرفًا على الأقل.',
      few: 'استخدم $count أحرف على الأقل.',
      two: 'استخدم حرفين على الأقل.',
      one: 'استخدم حرفًا واحدًا على الأقل.',
      zero: 'أدخل كلمة المرور.',
    );
    return '$_temp0';
  }

  @override
  String get passwordNeedsLetterAndDigit =>
      'استخدم حرفًا واحدًا ورقمًا واحدًا على الأقل.';

  @override
  String get passwordWeak => 'كلمة المرور هذه سهلة التخمين. اختر غيرها.';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get categoryRequired => 'اختر فئتك.';

  @override
  String get wilayasRequired => 'اختر ولاية واحدة على الأقل.';

  @override
  String get verifyEmailTitle => 'أكّد بريدك الإلكتروني';

  @override
  String verifyEmailSubtitle(String email) {
    return 'أدخل الرمز الذي أرسلناه إلى $email لتفعيل حسابك.';
  }

  @override
  String get verificationCodeLabel => 'رمز التحقق';

  @override
  String get verifyAction => 'تأكيد';

  @override
  String get verifyNoCodePrompt => 'لم يصلك الرمز ؟';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String resendIn(String time) {
    return 'إعادة الإرسال بعد $time';
  }

  @override
  String get verifyCodeResent => 'رمز جديد في الطريق إليك';

  @override
  String get codeInvalidTitle => 'هذا الرمز غير صحيح';

  @override
  String get codeInvalidBody => 'تحقّق من الأرقام الستة وأعد المحاولة.';

  @override
  String mockCodeHint(String code) {
    return 'وضع تجريبي — الرمز دائمًا $code.';
  }

  @override
  String get codeExpiredTitle => 'انتهت صلاحية الرمز';

  @override
  String get codeExpiredBody =>
      'الرموز صالحة 15 دقيقة. اطلب رمزًا جديدًا وسنرسله فورًا.';

  @override
  String get documentsTitle => 'تحقق من نشاطك';

  @override
  String get documentsSubtitle =>
      'ارفع هذه المستندات الثلاثة. نراجعها خلال يوم إلى يومين.';

  @override
  String get documentsSectionTitle => 'وثائق التحقق';

  @override
  String get documentsSectionNote => 'نراجعها قبل نشر خدماتك.';

  @override
  String get documentsSubmit => 'إرسال للمراجعة';

  @override
  String get documentsLater => 'لاحقًا';

  @override
  String get documentsSubmitted =>
      'تم إرسال المستندات. نراجعها خلال يوم إلى يومين.';

  @override
  String get documentUploadAction => 'إرفاق ملف';

  @override
  String get documentUploading => 'جارٍ الرفع…';

  @override
  String get documentUploaded => 'تم الاستلام';

  @override
  String get documentUnderReview => 'قيد المراجعة';

  @override
  String get documentApproved => 'مقبول';

  @override
  String get documentReplace => 'اختيار ملف آخر';

  @override
  String get documentRemove => 'إزالة الملف';

  @override
  String get documentMissing => 'أرفق هذا المستند.';

  @override
  String documentTooLarge(int count) {
    return 'حجم هذا الملف أكبر من $count ميغابايت. أرفق ملفًا أصغر.';
  }

  @override
  String get documentWrongType => 'أرفق ملف PDF أو صورة.';

  @override
  String get documentUploadFailed => 'فشل الرفع. اضغط لإعادة المحاولة.';

  @override
  String get documentIdentityCard => 'بطاقة التعريف الوطنية';

  @override
  String get documentIdentityCardHint => 'الوجهان في ملف واحد';

  @override
  String get documentCommercialRegister => 'السجل التجاري أو بطاقة الحرفي';

  @override
  String get documentCommercialRegisterHint => 'حسب الجهة المسجّل لديها';

  @override
  String get documentTaxRegistration => 'بطاقة التعريف الجبائي (NIF)';

  @override
  String get documentTaxRegistrationHint => 'تحمل رقم التعريف الجبائي';

  @override
  String get loginTitle => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لتكمل من حيث توقّفت.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور ؟';

  @override
  String get loginNewPrompt => 'جديد على Eventor ؟';

  @override
  String get loginWrongTitle => 'البريد الإلكتروني أو كلمة المرور غير صحيح';

  @override
  String get loginWrongBody =>
      'تحقّق من العنوان وأعد المحاولة — كلمة المرور حسّاسة لحالة الأحرف.';

  @override
  String get loginUnverifiedTitle => 'أكّد بريدك الإلكتروني أولًا';

  @override
  String loginUnverifiedBody(String email) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $email عند التسجيل، وما يزال ينتظرك.';
  }

  @override
  String get loginSendNewCode => 'إرسال رمز جديد';

  @override
  String get loginLockedTitle => 'محاولات فاشلة كثيرة';

  @override
  String loginLockedBody(String time) {
    return 'قُفل هذا الحساب مؤقتًا لحمايته. يمكنك المحاولة عند $time، أو إعادة تعيين كلمة المرور الآن.';
  }

  @override
  String loginTryAgainAt(String time) {
    return 'أعد المحاولة عند $time';
  }

  @override
  String get loginBlockedTitle => 'هذا الحساب محظور';

  @override
  String get loginNotAllowedTitle => 'لا يمكن لهذا الحساب استخدام التطبيق';

  @override
  String get passwordResetDone =>
      'تم تحديث كلمة المرور. سجّل الدخول بكلمة المرور الجديدة.';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل البريد الإلكتروني لحسابك وسنرسل لك رمزًا من 6 أرقام.';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get backToLogIn => 'العودة إلى تسجيل الدخول';

  @override
  String get resetCodeTitle => 'تحقق من بريدك';

  @override
  String resetCodeSubtitle(String email) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $email.';
  }

  @override
  String get resetPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get resetPasswordSubtitle =>
      'يجب أن تكون كلمة المرور الجديدة مختلفة عن كلمة المرور التي استخدمتها من قبل.';

  @override
  String get resetPasswordAction => 'إعادة تعيين كلمة المرور';

  @override
  String get setPasswordTitle => 'عيّن كلمة المرور';

  @override
  String get setPasswordSubtitle =>
      'حسابك على Eventor جاهز. اختر كلمة مرور وستُسجّل الدخول مباشرة.';

  @override
  String get setPasswordAction => 'تعيين كلمة المرور والدخول';

  @override
  String get needHelpContactSupport => 'تحتاج مساعدة ؟ تواصل مع الدعم';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get inviteExpiredTitle => 'انتهت صلاحية رابط الدعوة';

  @override
  String get inviteExpiredBody =>
      'روابط الدعوة صالحة 7 أيام وتُستعمل مرة واحدة. اطلب رابطًا جديدًا وسيصلك بعد لحظات.';

  @override
  String get inviteInvalidTitle => 'رابط الدعوة هذا لا يعمل';

  @override
  String get inviteInvalidBody =>
      'افتح الرابط من رسالة الدعوة مجددًا، أو اطلب منّا رابطًا جديدًا.';

  @override
  String get supportEmailSubject => 'مساعدة بخصوص حسابي على Eventor';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String homeGreeting(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get homeComingSoon => 'يجري بناء شاشتك الرئيسية. أنت مسجّل الدخول.';

  @override
  String get homeProviderPendingTitle => 'ملفك قيد المراجعة';

  @override
  String get homeProviderPendingBody =>
      'يمكنك تصفح التطبيق. تُنشر خدماتك بعد قبول مستنداتك.';

  @override
  String get homeProviderRejectedTitle => 'بعض المستندات تحتاج انتباهك';

  @override
  String get homeUploadDocuments => 'رفع المستندات';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusDeclined => 'مرفوض';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get availabilityAvailable => 'متاح';

  @override
  String get availabilityUnavailable => 'غير متاح';

  @override
  String ratingLabel(String score) {
    return 'التقييم $score من 5';
  }

  @override
  String ratingWithCountLabel(String score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'التقييم $score من 5 من $count مراجعة',
      many: 'التقييم $score من 5 من $count مراجعة',
      few: 'التقييم $score من 5 من $count مراجعات',
      two: 'التقييم $score من 5 من مراجعتين',
      one: 'التقييم $score من 5 من مراجعة واحدة',
      zero: 'التقييم $score من 5 دون مراجعات',
    );
    return '$_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count مراجعة)',
      many: '($count مراجعة)',
      few: '($count مراجعات)',
      two: '(مراجعتان)',
      one: '(مراجعة واحدة)',
      zero: '(دون مراجعات)',
    );
    return '$_temp0';
  }

  @override
  String get priceFrom => 'ابتداءً من';

  @override
  String get requestAccept => 'قبول';

  @override
  String get requestDecline => 'رفض';

  @override
  String get searchHint => 'بحث';

  @override
  String get selectionNoMatch => 'لا توجد نتائج مطابقة.';

  @override
  String get selectionDone => 'تم';

  @override
  String selectionDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم · $count عنصر',
      many: 'تم · $count عنصرًا',
      few: 'تم · $count عناصر',
      two: 'تم · عنصران',
      one: 'تم · عنصر واحد',
      zero: 'تم',
    );
    return '$_temp0';
  }

  @override
  String get currencyDzd => 'دج';

  @override
  String get ratingNew => 'جديد';

  @override
  String get navProfile => 'الملف الشخصي';
}
