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
  String get priceOnQuote => 'حسب الطلب';

  @override
  String get ratingNew => 'جديد';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get stateErrorTitle => 'تعذّر تحميل هذا المحتوى';

  @override
  String get stateRetry => 'إعادة المحاولة';

  @override
  String get verifiedProvider => 'مقدّم خدمة موثّق';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get readLess => 'عرض أقل';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String seeAllCount(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get noLongerAvailable => 'لم يعد متاحًا';

  @override
  String get undo => 'تراجع';

  @override
  String get favouriteSave => 'حفظ';

  @override
  String get favouriteSaved => 'محفوظ';

  @override
  String get favouriteFailed => 'تعذّر تحديث المفضلة. حاول مرة أخرى.';

  @override
  String get favouriteRemoved => 'أُزيل من المفضلة';

  @override
  String get priceUnitPerEvent => 'للمناسبة';

  @override
  String get priceUnitPerHour => 'للساعة';

  @override
  String get priceUnitPerPerson => 'للشخص';

  @override
  String get priceUnitPerDay => 'لليوم';

  @override
  String get eventTypeWedding => 'زفاف';

  @override
  String get eventTypeEngagement => 'خطوبة';

  @override
  String get eventTypeHenna => 'حنّاء';

  @override
  String get eventTypeBirthday => 'عيد ميلاد';

  @override
  String get eventTypeCircumcision => 'ختان';

  @override
  String get eventTypeGraduation => 'تخرّج';

  @override
  String get eventTypeCorporate => 'مؤسسي';

  @override
  String get eventTypeConference => 'مؤتمر';

  @override
  String get eventTypeOther => 'أخرى';

  @override
  String get calendarSelected => 'المحدد';

  @override
  String get calendarAvailable => 'متاح';

  @override
  String get calendarBooked => 'محجوز بالكامل';

  @override
  String get calendarUnavailable => 'غير متاح';

  @override
  String get calendarPreviousMonth => 'الشهر السابق';

  @override
  String get calendarNextMonth => 'الشهر التالي';

  @override
  String calendarMinNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يجب الحجز قبل $count يوم على الأقل.',
      many: 'يجب الحجز قبل $count يومًا على الأقل.',
      few: 'يجب الحجز قبل $count أيام على الأقل.',
      two: 'يجب الحجز قبل يومين على الأقل.',
      one: 'يجب الحجز قبل يوم واحد على الأقل.',
      zero: 'يمكن الحجز ابتداءً من اليوم.',
    );
    return '$_temp0';
  }

  @override
  String get notAcceptingTitle => 'لا يقبل حجوزات جديدة حاليًا';

  @override
  String get notAcceptingBody => 'يمكنك مراسلته';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String get messageProvider => 'مراسلة مقدّم الخدمة';

  @override
  String get requestBooking => 'طلب حجز';

  @override
  String get requestPack => 'طلب الباقة';

  @override
  String get packSave => 'وفّر';

  @override
  String basedOnReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بناءً على $count مراجعة',
      many: 'بناءً على $count مراجعة',
      few: 'بناءً على $count مراجعات',
      two: 'بناءً على مراجعتين',
      one: 'بناءً على مراجعة واحدة',
      zero: 'لا توجد مراجعات',
    );
    return '$_temp0';
  }

  @override
  String bookedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُجز $count مرة',
      many: 'حُجز $count مرة',
      few: 'حُجز $count مرات',
      two: 'حُجز مرتين',
      one: 'حُجز مرة واحدة',
      zero: 'لم يُحجز بعد',
    );
    return '$_temp0';
  }

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      many: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا خدمات',
    );
    return '$_temp0';
  }

  @override
  String packBy(String name) {
    return 'من $name';
  }

  @override
  String photoCounterLabel(int index, int count) {
    return 'الصورة $index من $count';
  }

  @override
  String get backLabelOnPhoto => 'رجوع';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSearch => 'البحث';

  @override
  String get navBookings => 'الحجوزات';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get profileFavourites => 'المفضلة';

  @override
  String get profileMoreSoon => 'المزيد من الإعدادات قريبًا.';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'طاب يومك';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get chooseCity => 'اختر مدينتك';

  @override
  String get chooseCitySubtitle =>
      'نعرض الخدمات التي تغطيها. تظهر فقط الولايات المفتوحة على Eventor.';

  @override
  String get cityChangeFailed => 'تعذّر تغيير مدينتك. حاول مرة أخرى.';

  @override
  String get homeSearchHint => 'ابحث عن خدمة أو مقدّم خدمة';

  @override
  String get homeFiltersLabel => 'الفلاتر';

  @override
  String get homeNotificationsLabel => 'الإشعارات';

  @override
  String get homeNotificationsUnread => 'الإشعارات، غير مقروءة';

  @override
  String get homeYourBookings => 'حجوزاتك';

  @override
  String get homeYourBudget => 'ميزانيتك';

  @override
  String get budgetDetails => 'التفاصيل';

  @override
  String get budgetOf => 'من أصل';

  @override
  String get budgetPlanned => 'مخطّطة';

  @override
  String budgetBooked(int booked, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      many: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتين',
      one: 'خدمة واحدة',
      zero: '0 خدمات',
    );
    return '$booked من $_temp0 محجوزة';
  }

  @override
  String get budgetEmptyTitle => 'خطّط لميزانيتك';

  @override
  String get budgetEmptyBody =>
      'حدّد مبلغًا إجماليًا، ثم تابع التكلفة الفعلية لكل خدمة. أنت فقط من يراها.';

  @override
  String get budgetCreate => 'إنشاء ميزانية';

  @override
  String get homeReadyPacks => 'باقات جاهزة';

  @override
  String get homeServicesNearYou => 'خدمات بالقرب منك';

  @override
  String get filtersTitle => 'الفلاتر';

  @override
  String get filtersClose => 'إغلاق الفلاتر';

  @override
  String get filtersSortBy => 'الترتيب حسب';

  @override
  String get sortRelevance => 'الأكثر صلة';

  @override
  String get sortPriceLow => 'الأقل سعرًا';

  @override
  String get sortPriceHigh => 'الأعلى سعرًا';

  @override
  String get sortRating => 'الأعلى تقييمًا';

  @override
  String get sortPopular => 'الأكثر طلبًا';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get filtersCategory => 'الفئة';

  @override
  String get filtersWilaya => 'الولاية';

  @override
  String get filtersAllWilayas => 'كل الولايات';

  @override
  String get filtersBudget => 'الميزانية';

  @override
  String get filtersEventDate => 'تاريخ المناسبة';

  @override
  String get filtersEventDateAny => 'أي تاريخ';

  @override
  String get filtersEventDateHint =>
      'فقط مقدّمو الخدمات المتاحون في ذلك اليوم.';

  @override
  String get filtersEventDateClear => 'مسح التاريخ';

  @override
  String get filtersRating => 'التقييم';

  @override
  String get filtersRatingAny => 'الكل';

  @override
  String get filtersSaved => 'المحفوظات';

  @override
  String get filtersFavouritesOnly => 'المفضلة فقط';

  @override
  String get filtersClearAll => 'مسح الكل';

  @override
  String filtersShowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض $count خدمة',
      many: 'عرض $count خدمة',
      few: 'عرض $count خدمات',
      two: 'عرض خدمتين',
      one: 'عرض خدمة واحدة',
      zero: 'لا توجد خدمات',
    );
    return '$_temp0';
  }

  @override
  String get filtersShow => 'عرض الخدمات';

  @override
  String wilayaDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم · $count ولاية',
      many: 'تم · $count ولاية',
      few: 'تم · $count ولايات',
      two: 'تم · ولايتان',
      one: 'تم · ولاية واحدة',
      zero: 'تم',
    );
    return '$_temp0';
  }

  @override
  String get wilayaClear => 'مسح';

  @override
  String get eventDateSheetTitle => 'اختر تاريخ مناسبتك';

  @override
  String get searchRecent => 'عمليات البحث الأخيرة';

  @override
  String get searchClear => 'مسح';

  @override
  String searchRemoveRecent(String query) {
    return 'إزالة $query';
  }

  @override
  String get searchBrowseCategories => 'تصفّح الفئات';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      many: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا توجد خدمات',
    );
    return '$_temp0';
  }

  @override
  String resultsSortChip(String order) {
    return 'الترتيب · $order';
  }

  @override
  String resultsFiltersChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الفلاتر · $count',
      many: 'الفلاتر · $count',
      few: 'الفلاتر · $count',
      two: 'الفلاتر · 2',
      one: 'الفلاتر · 1',
      zero: 'الفلاتر',
    );
    return '$_temp0';
  }

  @override
  String get resultsAllServices => 'كل الخدمات';

  @override
  String get resultsEmptyTitle => 'لا شيء يطابق هذه الفلاتر';

  @override
  String get resultsEmptyBody =>
      'جرّب ميزانية أوسع أو ولاية أخرى أو فلاتر أقل.';

  @override
  String resultsEmptySearch(String query) {
    return 'لا توجد خدمات لـ «$query».';
  }

  @override
  String get resultsClearFilters => 'مسح كل الفلاتر';

  @override
  String get resultsLoadMoreFailed => 'تعذّر تحميل المزيد من النتائج.';

  @override
  String resultsRemoveFilter(String label) {
    return 'إزالة الفلتر $label';
  }

  @override
  String get filterChipFavourites => 'المفضلة';

  @override
  String get serviceAbout => 'عن هذه الخدمة';

  @override
  String get serviceGoodToKnow => 'معلومات مفيدة';

  @override
  String serviceCancellation(String policy) {
    return 'سياسة مقدّم الخدمة: $policy';
  }

  @override
  String get serviceExtras => 'إضافات';

  @override
  String get servicePickDate => 'اختر تاريخًا';

  @override
  String get selectedDateLabel => 'تاريخك';

  @override
  String get calendarConfirmNote => 'يؤكد مقدّم الخدمة الوقت بالضبط بعد طلبك.';

  @override
  String get monthLoadFailed => 'تعذّر تحميل هذا الشهر.';

  @override
  String get serviceReviews => 'المراجعات';

  @override
  String get serviceNoReviews => 'لا توجد مراجعات بعد';

  @override
  String get servicePacksFromProvider => 'باقات من مقدّم الخدمة هذا';

  @override
  String get serviceReport => 'الإبلاغ عن هذه الخدمة';

  @override
  String upToGuests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حتى $count ضيف',
      many: 'حتى $count ضيفًا',
      few: 'حتى $count ضيوف',
      two: 'حتى ضيفين',
      one: 'حتى ضيف واحد',
      zero: 'بدون ضيوف',
    );
    return '$_temp0';
  }

  @override
  String yearsInBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سنة في المجال',
      many: '$count سنة في المجال',
      few: '$count سنوات في المجال',
      two: 'سنتان في المجال',
      one: 'سنة واحدة في المجال',
      zero: 'أقل من سنة في المجال',
    );
    return '$_temp0';
  }

  @override
  String repliesIn(String time) {
    return 'يرد عادةً خلال $time';
  }

  @override
  String get detailGoneTitle => 'لم يعد هذا متاحًا';

  @override
  String get detailGoneBody => 'ربما أزاله مقدّم الخدمة.';

  @override
  String get detailGoneBack => 'رجوع';

  @override
  String get profileChecked => 'ما تحقّقنا منه';

  @override
  String get checkIdentity => 'الهوية موثّقة';

  @override
  String get checkRegistration => 'نشاط مسجّل';

  @override
  String get checkReplyTime => 'يرد بسرعة';

  @override
  String get profileAbout => 'نبذة';

  @override
  String get profileServices => 'الخدمات';

  @override
  String get profileWhereTheyWork => 'أين يعمل';

  @override
  String profileLanguages(String languages) {
    return 'يتحدث $languages';
  }

  @override
  String get profileMemberSince => 'عضو منذ';

  @override
  String get profileReport => 'الإبلاغ عن مقدّم الخدمة';

  @override
  String get langAr => 'العربية';

  @override
  String get langFr => 'الفرنسية';

  @override
  String get langEn => 'الإنجليزية';

  @override
  String statReviewsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مراجعة',
      many: 'مراجعة',
      few: 'مراجعات',
      two: 'مراجعتان',
      one: 'مراجعة',
      zero: 'مراجعات',
    );
    return '$_temp0';
  }

  @override
  String statCompletedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حجز مكتمل',
      many: 'حجزًا مكتملًا',
      few: 'حجوزات مكتملة',
      two: 'حجزان مكتملان',
      one: 'حجز مكتمل',
      zero: 'حجوزات مكتملة',
    );
    return '$_temp0';
  }

  @override
  String statYearsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سنة في المجال',
      many: 'سنة في المجال',
      few: 'سنوات في المجال',
      two: 'سنتان في المجال',
      one: 'سنة في المجال',
      zero: 'سنوات في المجال',
    );
    return '$_temp0';
  }

  @override
  String get packsSubtitle =>
      'باقات يجمعها مقدّم خدمة واحد — سعر واحد، كل شيء مشمول.';

  @override
  String get packsAll => 'الكل';

  @override
  String packsSortedBy(String order) {
    return 'مرتبة حسب $order';
  }

  @override
  String get packOrderSavings => 'أفضل توفير';

  @override
  String get packOrderPriceAsc => 'الأقل سعرًا';

  @override
  String get packOrderPriceDesc => 'الأعلى سعرًا';

  @override
  String get packOrderRating => 'الأعلى تقييمًا';

  @override
  String get packOrderPopular => 'الأكثر طلبًا';

  @override
  String get packsEmptyTitle => 'لا توجد باقات هنا بعد';

  @override
  String get packsEmptyBody => 'جرّب نوع مناسبة آخر.';

  @override
  String packBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'باقة جاهزة · $count خدمة',
      many: 'باقة جاهزة · $count خدمة',
      few: 'باقة جاهزة · $count خدمات',
      two: 'باقة جاهزة · خدمتان',
      one: 'باقة جاهزة · خدمة واحدة',
      zero: 'باقة جاهزة',
    );
    return '$_temp0';
  }

  @override
  String packBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُجزت $count مرة',
      many: 'حُجزت $count مرة',
      few: 'حُجزت $count مرات',
      two: 'حُجزت مرتين',
      one: 'حُجزت مرة واحدة',
      zero: 'لم تُحجز بعد',
    );
    return '$_temp0';
  }

  @override
  String get packVersus => 'مقارنة بالحجز المنفصل';

  @override
  String get packInside => 'ما تتضمنه الباقة';

  @override
  String get packBookedSeparately => 'عند الحجز المنفصل';

  @override
  String get packCalendarHint =>
      'فقط الأيام التي تكون فيها كل خدمات الباقة متاحة.';

  @override
  String get packAbout => 'عن هذه الباقة';

  @override
  String packAvailableIn(String wilayas) {
    return 'متاحة في $wilayas';
  }

  @override
  String packAllServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة مشمولة',
      many: '$count خدمة مشمولة',
      few: '$count خدمات مشمولة',
      two: 'خدمتان مشمولتان',
      one: 'خدمة واحدة مشمولة',
      zero: 'بدون خدمات',
    );
    return '$_temp0';
  }

  @override
  String get favouritesTitle => 'المفضلة';

  @override
  String get favouritesServices => 'الخدمات';

  @override
  String get favouritesPacks => 'الباقات';

  @override
  String get favouritesAll => 'الكل';

  @override
  String get favouritesEmptyServices => 'لا توجد خدمات محفوظة بعد';

  @override
  String get favouritesEmptyPacks => 'لا توجد باقات محفوظة بعد';

  @override
  String get favouritesEmptyBody =>
      'اضغط على القلب في أي خدمة أو باقة للاحتفاظ بها هنا.';

  @override
  String get favouritesExplore => 'استكشف';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج';

  @override
  String get offlineTitle => 'أنت غير متّصل';

  @override
  String get offlineRetry => 'إعادة المحاولة';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get messagesSearchHint => 'ابحث في المحادثات';

  @override
  String get messagesFilterAll => 'الكل';

  @override
  String get messagesFilterUnread => 'غير المقروءة';

  @override
  String get messagesFilterBookings => 'الحجوزات';

  @override
  String get messagesEmptyTitle => 'لا توجد رسائل بعد';

  @override
  String get messagesEmptyBody => 'عندما تراسل مقدّم خدمة، ستظهر محادثاتك هنا.';

  @override
  String get messagesEmptyAction => 'ابحث عن مقدّم خدمة';

  @override
  String get messagesUnreadEmpty => 'لا رسائل غير مقروءة';

  @override
  String get messagesBookingsEmpty => 'لا محادثات حجز بعد';

  @override
  String messagesNoMatch(String query) {
    return 'لا محادثات تطابق \"$query\"';
  }

  @override
  String get offlineMessagesBody =>
      'هذه آخر رسائلك. الجديدة تصل عند عودة الاتصال.';

  @override
  String chatDispute(String reference) {
    return 'نزاع · $reference';
  }

  @override
  String get chatDisputeNoRef => 'نزاع';

  @override
  String get chatSupport => 'دعم Eventor';

  @override
  String get chatDeletedAccount => 'حساب محذوف';

  @override
  String get chatPhoto => 'صورة';

  @override
  String get chatRemoved => 'حذفه Eventor';

  @override
  String get chatYesterday => 'أمس';

  @override
  String messagesUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسالة غير مقروءة',
      many: '$count رسالة غير مقروءة',
      few: '$count رسائل غير مقروءة',
      two: 'رسالتان غير مقروءتين',
      one: 'رسالة واحدة غير مقروءة',
      zero: 'لا رسائل غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get chatComposerHint => 'اكتب رسالة';

  @override
  String get chatComposerDisputeHint => 'اكتب إلى الطرفين';

  @override
  String get chatClosed =>
      'أغلق Eventor هذه المحادثة. لا يزال بإمكانك قراءتها.';

  @override
  String get chatOtherBlocked =>
      'هذا الحساب لم يعد نشطًا. لا يزال بإمكانك قراءة المحادثة.';

  @override
  String get chatMaskedNote => 'الرقم مخفي حتى قبول الحجز';

  @override
  String get chatNotSent => 'لم تُرسل · اضغط لإعادة المحاولة';

  @override
  String get chatNewMessages => 'رسائل جديدة';

  @override
  String chatSayHello(String name) {
    return 'قل مرحبًا لـ $name';
  }

  @override
  String get chatToday => 'اليوم';

  @override
  String chatGroupSubtitle(String name) {
    return 'أنت و$name ودعم Eventor';
  }

  @override
  String get chatViewProfile => 'عرض الملف';

  @override
  String chatReportUser(String name) {
    return 'الإبلاغ عن $name';
  }

  @override
  String get chatCopy => 'نسخ';

  @override
  String get chatReportMessage => 'إبلاغ';

  @override
  String get photoReload => 'اضغط لإعادة التحميل';

  @override
  String get reportTitle => 'إبلاغ';

  @override
  String get reportReasonInappropriate => 'غير لائق';

  @override
  String get reportReasonSpam => 'رسائل مزعجة';

  @override
  String get reportReasonContact => 'مشاركة بيانات الاتصال';

  @override
  String get reportReasonHarassment => 'تحرّش أو مضايقة';

  @override
  String get reportReasonFake => 'احتيال أو حساب مزيّف';

  @override
  String get reportReasonOther => 'سبب آخر';

  @override
  String get reportNoteHint => 'أضف ملاحظة (اختياري)';

  @override
  String get reportSend => 'إرسال البلاغ';

  @override
  String get chatSend => 'إرسال';

  @override
  String get chatAttach => 'إضافة صورة';

  @override
  String get chatMore => 'خيارات أخرى';

  @override
  String get chatRemoveAttachment => 'إزالة الصورة';

  @override
  String get chatSending => 'جارٍ الإرسال';

  @override
  String get chatOlderFailed => 'تعذّر تحميل الرسائل الأقدم';

  @override
  String get photoViewerClose => 'إغلاق';

  @override
  String get chatUnavailable => 'لم تعد هذه المحادثة متاحة';

  @override
  String get chatCopied => 'تم النسخ';

  @override
  String get chatPhotoNeedsText => 'أرسل رسالة أولًا';

  @override
  String photoTooLarge(int mb) {
    return 'هذه الصورة أكبر من $mb ميغابايت';
  }

  @override
  String get photoWrongType => 'استخدم صورة بصيغة JPEG أو PNG أو WebP أو HEIC';

  @override
  String get reportSent => 'شكرًا — سنراجع الأمر';

  @override
  String get reportAlready => 'سبق أن أبلغت عن هذا';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAll => 'تعليم الكل كمقروء';

  @override
  String get notificationsToday => 'اليوم';

  @override
  String get notificationsThisWeek => 'هذا الأسبوع';

  @override
  String get notificationsEarlier => 'أقدم';

  @override
  String get notificationsEmptyTitle => 'لا إشعارات بعد';

  @override
  String get notificationsEmptyBody =>
      'ستظهر هنا تحديثات الحجوزات والرسائل والتذكيرات.';

  @override
  String get notificationUnread => 'غير مقروء';

  @override
  String get offlineNotificationsBody =>
      'هذه آخر إشعاراتك. الجديدة تصل عند عودة الاتصال.';

  @override
  String get budgetTitle => 'الميزانية';

  @override
  String get budgetEdit => 'تعديل';

  @override
  String get budgetCreateIntroTitle => 'خطّط لميزانية مناسبتك';

  @override
  String get budgetEditIntroTitle => 'تعديل الميزانية';

  @override
  String get budgetEditIntroBody =>
      'تغيير الإجمالي لا يمسّ بنود المصاريف. أنت فقط من يراها.';

  @override
  String get budgetNameLabel => 'اسم الميزانية';

  @override
  String get budgetNameHint => 'مثال: زفافنا';

  @override
  String get budgetEventDateLabel => 'تاريخ المناسبة';

  @override
  String get budgetEventDateClear => 'إزالة التاريخ';

  @override
  String get optionalField => 'اختياري';

  @override
  String get budgetTotalLabel => 'الميزانية الإجمالية (دج)';

  @override
  String get amountFieldSuffix => '';

  @override
  String get budgetCreateAction => 'إنشاء الميزانية';

  @override
  String get budgetSaveChanges => 'حفظ التغييرات';

  @override
  String get budgetSpent => 'مصروفة';

  @override
  String budgetAllocatedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دج موزّعة على $count بند',
      many: 'دج موزّعة على $count بندًا',
      few: 'دج موزّعة على $count بنود',
      two: 'دج موزّعة على بندين',
      one: 'دج موزّعة على بند واحد',
      zero: 'دج موزّعة حتّى الآن',
    );
    return '$_temp0';
  }

  @override
  String get budgetRemaining => 'المتبقّي';

  @override
  String get budgetServicesBooked => 'الخدمات المحجوزة';

  @override
  String budgetBookedOf(int booked, int count) {
    return '$booked من $count';
  }

  @override
  String get budgetExpenseLines => 'بنود المصاريف';

  @override
  String get budgetActualVsPlanned => 'الفعلي مقابل المخطّط';

  @override
  String get budgetNotBookedYet => 'لم يُحجز بعد';

  @override
  String get budgetLineOnPlan => 'حسب الخطة';

  @override
  String get budgetLinePlanned => 'مخطّط';

  @override
  String get budgetNoLinesTitle => 'لا توجد بنود بعد';

  @override
  String get budgetNoLinesBody =>
      'أضف بندًا لكل خدمة تدفع مقابلها، وسيُحدّث المبلغ المتبقّي تلقائيًا.';

  @override
  String get budgetAddExpense => 'إضافة مصروف';

  @override
  String get budgetOverTitle => 'تجاوزت ميزانيتك';

  @override
  String get budgetOverBody =>
      'أنفقت أكثر من إجماليك. ارفع الميزانية أو قلّص أحد البنود.';

  @override
  String get expenseNewTitle => 'بند مصروف جديد';

  @override
  String get expenseNewBody =>
      'الاسم والمبلغ المخطّط يكفيان للبداية. الباقي يمكن أن ينتظر.';

  @override
  String get expenseLineTitle => 'بند مصروف';

  @override
  String get expenseEditBody =>
      'ربط الحجز يوضّح مع من هو ويحتسبه ضمن المحجوز. أمّا المبلغ المدفوع فتُدخله أنت.';

  @override
  String get expenseDelete => 'حذف';

  @override
  String get expenseCategoryLabel => 'الفئة';

  @override
  String get expenseCategoryPlaceholder => 'اختر فئة';

  @override
  String get expenseNoCategory => 'بدون فئة';

  @override
  String get expenseLabelLabel => 'الوصف';

  @override
  String get expenseLabelHint => 'مثال: كعكة الزفاف';

  @override
  String get expensePlannedLabel => 'المبلغ المخطّط (دج)';

  @override
  String get expenseSpentLabel => 'المصروف حتى الآن (دج)';

  @override
  String get expenseBookingLabel => 'الحجز المرتبط';

  @override
  String get expenseNotLinked => 'غير مرتبط';

  @override
  String get expenseAddLine => 'إضافة بند';

  @override
  String get expenseSaveLine => 'حفظ البند';

  @override
  String get expenseFullTitle => 'الميزانية ممتلئة';

  @override
  String get expenseFullBody =>
      'بلغت الحدّ الأقصى لعدد البنود. احذف بندًا لم تعد بحاجته، أو ادمج بندين في واحد.';

  @override
  String get expenseDeleteTitle => 'حذف هذا البند ؟';

  @override
  String get expenseDeleteBody =>
      'سيختفي من ميزانيتك وسيُعاد حساب المبلغ المتبقّي. الحجز المرتبط به لا يتأثّر.';

  @override
  String get expenseDeleteSpent => 'المصروف (دج)';

  @override
  String get expenseDeletePlanned => 'المخطّط (دج)';

  @override
  String get expenseDeleteConfirm => 'حذف البند';

  @override
  String get expenseDeleteKeep => 'الاحتفاظ به';

  @override
  String get linkBookingTitle => 'ربط حجز';

  @override
  String get linkBookingIntro =>
      'تظهر هنا حجوزاتك أنت فقط. ربط حجز يملأ اسم المزوّد ويحتسب هذا البند ضمن «الخدمات المحجوزة».';

  @override
  String get linkBookingNoneBody => 'هذا البند غير مرتبط بأي حجز';

  @override
  String linkBookingUsedOn(String label) {
    return 'مستعمل في «$label»';
  }

  @override
  String get linkBookingNote =>
      'الحجز المستعمل في بند آخر يظهر باهتًا، حتى لا يُحتسب المبلغ نفسه مرتين.';

  @override
  String get linkBookingAction => 'ربط الحجز';

  @override
  String get linkBookingEmptyTitle => 'لا توجد حجوزات بعد';

  @override
  String get linkBookingEmptyBody => 'بعد حجز خدمة، يمكنك ربطها بهذا البند.';

  @override
  String get discardTitle => 'تجاهل التغييرات ؟';

  @override
  String get discardBody => 'لن يتم حفظ ما غيّرته هنا.';

  @override
  String get discardConfirm => 'تجاهل';

  @override
  String get discardKeep => 'متابعة التعديل';

  @override
  String get navRequests => 'الطلبات';

  @override
  String get navServices => 'الخدمات';

  @override
  String get profileDocuments => 'وثائقي';

  @override
  String get providerAccepting => 'أقبل الحجوزات';

  @override
  String get providerPaused => 'الحجوزات متوقفة';

  @override
  String get providerAcceptingHint => 'يمكن للعملاء إرسال طلبات جديدة إليك.';

  @override
  String get providerPausedHint =>
      'لا طلبات جديدة حتى تعيد التفعيل. تبقى خدماتك ظاهرة.';

  @override
  String get providerAvailabilityTitle => 'توفّرك';

  @override
  String get providerAvailabilityBody => 'الإيقاف لا يمسّ حجوزاتك الحالية.';

  @override
  String get providerNowAccepting => 'أصبحت تقبل الحجوزات من جديد.';

  @override
  String get providerNowPaused => 'تم إيقاف الحجوزات الجديدة.';

  @override
  String get providerStatRequests => 'الطلبات';

  @override
  String get providerStatUpcoming => 'القادمة';

  @override
  String get providerStatServices => 'الخدمات';

  @override
  String get providerRequestsTitle => 'طلبات الحجز';

  @override
  String get providerNoRequestsTitle => 'لا طلبات جديدة';

  @override
  String providerNoRequestsBody(int hours) {
    return 'تظهر هنا طلبات الحجز الجديدة، ولديك $hours ساعة للردّ على كل طلب.';
  }

  @override
  String get providerNoRequestsPausedBody =>
      'حجوزاتك متوقفة، لذا لا يمكن للعملاء إرسال طلبات جديدة.';

  @override
  String providerReplyWithin(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'ردّ خلال $hours ساعة',
      zero: 'ردّ الآن',
    );
    return '$_temp0';
  }

  @override
  String providerAccepted(String name) {
    return 'تم قبول طلب $name.';
  }

  @override
  String get providerDeclined => 'تم رفض الطلب.';

  @override
  String get providerUpcomingTitle => 'الحجوزات القادمة';

  @override
  String get providerNoUpcoming => 'لا حجوزات مؤكدة قادمة بعد.';

  @override
  String get providerAvailabilityCalendar => 'تقويم التوفر';

  @override
  String get providerServicesTitle => 'خدماتك';

  @override
  String get providerManage => 'إدارة';

  @override
  String get providerAddService => 'إضافة خدمة';

  @override
  String get providerServicesAfterApproval => 'يتاح بعد الموافقة على ملفك.';

  @override
  String get serviceStatusPublished => 'منشورة';

  @override
  String get serviceStatusDraft => 'مسودة';

  @override
  String get serviceStatusHidden => 'مخفية';

  @override
  String get documentStateInReview => 'قيد المراجعة';

  @override
  String get documentStateApproved => 'مقبولة';

  @override
  String get documentStateRejected => 'مرفوضة';

  @override
  String get documentStateMissing => 'ناقص';

  @override
  String get documentRegisterShort => 'السجل التجاري أو بطاقة الحرفي';

  @override
  String get documentPhraseNationalId => 'بطاقة التعريف الوطنية';

  @override
  String get documentPhraseRegister => 'السجل التجاري أو بطاقة الحرفي';

  @override
  String get documentPhraseTaxCard => 'البطاقة الجبائية (NIF)';

  @override
  String get providerFinishTitle => 'أكمل التحقق';

  @override
  String providerMissingOne(String document) {
    return 'أرسل $document لنبدأ المراجعة. تستغرق عادةً يومًا إلى يومين.';
  }

  @override
  String providerMissingMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'أرسل الوثائق المتبقية ($count) لنبدأ المراجعة. تستغرق عادةً يومًا إلى يومين.',
      two: 'أرسل الوثيقتين المتبقيتين لنبدأ المراجعة. تستغرق عادةً يومًا إلى يومين.',
    );
    return '$_temp0';
  }

  @override
  String get providerReviewTitle => 'ملفك قيد المراجعة';

  @override
  String get providerReviewBody =>
      'نراجع وثائقك الآن. تستغرق المراجعة عادةً يومًا إلى يومين، وسنُعلمك بالنتيجة.';

  @override
  String get providerRejectedTitle => 'لم تتم الموافقة على الملف';

  @override
  String providerRejectedOne(String document) {
    return 'لم نقبل $document. أرسل نسخة جديدة لتعود إلى المراجعة.';
  }

  @override
  String providerRejectedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم نقبل $count وثائق. أرسل نسخًا جديدة لتعود إلى المراجعة.',
      two: 'لم نقبل وثيقتين. أرسل نسختين جديدتين لتعود إلى المراجعة.',
    );
    return '$_temp0';
  }

  @override
  String get providerStepAccount => 'تم إنشاء الحساب';

  @override
  String get providerStepDocuments => 'تم إرسال المستندات';

  @override
  String providerStepDocumentsCount(int sent, int total) {
    return 'المستندات المرسلة · $sent من $total';
  }

  @override
  String get providerStepUnderReview => 'قيد المراجعة';

  @override
  String get providerStepReviewed => 'تمت المراجعة';

  @override
  String get providerStepApproved => 'تمت الموافقة';

  @override
  String get providerStepNotApproved => 'لم تتم الموافقة';

  @override
  String get providerYourDocuments => 'وثائقك';

  @override
  String get providerResubmit => 'إعادة إرسال الوثائق';

  @override
  String get providerUploadNationalId => 'رفع بطاقة التعريف';

  @override
  String get providerUploadRegister => 'رفع السجل التجاري';

  @override
  String get providerUploadTaxCard => 'رفع البطاقة الجبائية';

  @override
  String get declineTitle => 'رفض هذا الطلب ؟';

  @override
  String declineBody(String name) {
    return 'سيُبلَّغ $name فورًا ويُحرَّر التاريخ في تقويمك. لا يمكن التراجع عن هذا — سيلزم إرسال طلب جديد.';
  }

  @override
  String get declineReasonLabel => 'لماذا ترفض الطلب ؟';

  @override
  String get declineReasonHint => 'مثال: لديّ حجز آخر في ذلك اليوم';

  @override
  String declineReasonHelper(String name) {
    return 'سيطّلع $name على هذا السبب.';
  }

  @override
  String get declineNote => 'يصبح التاريخ متاحًا لعملاء آخرين فور رفضك.';

  @override
  String get declineConfirm => 'رفض الطلب';

  @override
  String get declineGoBack => 'رجوع';

  @override
  String get resubmitTitle => 'مطلوب إجراء';

  @override
  String resubmitBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم تُقبل $count وثائق. أعد إرسالها لتعود خدماتك إلى المراجعة.',
      two: 'لم تُقبل وثيقتان. أعد إرسالهما لتعود خدماتك إلى المراجعة.',
      one: 'لم تُقبل إحدى الوثائق. أعد إرسالها لتعود خدماتك إلى المراجعة.',
    );
    return '$_temp0';
  }

  @override
  String resubmitMissingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ما زالت $count وثائق ناقصة. أرسلها ليدخل ملفك المراجعة.',
      two: 'ما زالت وثيقتان ناقصتين. أرسلهما ليدخل ملفك المراجعة.',
      one: 'ما زالت وثيقة واحدة ناقصة. أرسلها ليدخل ملفك المراجعة.',
    );
    return '$_temp0';
  }

  @override
  String get resubmitNothingBody =>
      'لا شيء يحتاج إلى تصحيح: وثائقك لدى المراجعين.';

  @override
  String resubmitRejectedOn(String date) {
    return 'مرفوضة في $date';
  }

  @override
  String get resubmitReasonGiven => 'السبب المذكور';

  @override
  String get resubmitNoReason => 'غير مقبولة';

  @override
  String get resubmitUploadNew => 'إرفاق ملف جديد';

  @override
  String resubmitHint(int mb) {
    return 'PDF أو صورة، $mb ميغابايت كحد أقصى';
  }

  @override
  String get resubmitChange => 'تغيير';

  @override
  String get resubmitRemove => 'إزالة هذا الملف';

  @override
  String get resubmitNotNow => 'ليس الآن';

  @override
  String get resubmitSent => 'تم إرسال الوثائق — سنراجعها خلال يوم أو يومين.';

  @override
  String get resubmitFailed =>
      'لم يُرسل أحد الملفات. لم يضع شيء آخر — أعد المحاولة.';

  @override
  String get messagesEmptyBodyProvider =>
      'عندما يراسلك عميل، تظهر المحادثة هنا.';

  @override
  String get budgetDelete => 'حذف الميزانية';

  @override
  String get budgetDeleteTitle => 'حذف هذه الميزانية ؟';

  @override
  String get budgetDeleteBody =>
      'ستُحذف ميزانيتك وكل بنودها نهائيًا. الحجوزات المرتبطة بها لا تتأثّر.';

  @override
  String get budgetDeleteConfirm => 'حذف الميزانية';

  @override
  String get budgetDeleted => 'تم حذف الميزانية.';

  @override
  String get budgetDeleteUnavailable => 'حذف الميزانية غير متاح بعد.';

  @override
  String messagesPreviewMine(String message) {
    return 'أنت: $message';
  }

  @override
  String get chatClosedPlain => 'هذه المحادثة مغلقة. لا يزال بإمكانك قراءتها.';

  @override
  String get notificationDeleted => 'تم حذف الإشعار';

  @override
  String get notificationDelete => 'حذف الإشعار';

  @override
  String get providerBlockedTitle => 'حسابك محظور';

  @override
  String get providerBlockedBody =>
      'لا يمكنك استقبال الطلبات أو الرد عليها ما دام الحظر قائمًا. حجوزاتك ورسائلك وسجلّك محفوظة.';

  @override
  String get providerBlockedServices =>
      'خدماتك مخفية عن العملاء ما دام الحساب محظورًا.';

  @override
  String loginBlockedUntil(String date) {
    return 'محظور حتى $date.';
  }

  @override
  String get bookingAddress => 'العنوان (اختياري)';

  @override
  String get bookingAddressHint => 'القاعة، الشارع…';

  @override
  String get bookingAddressLabel => 'العنوان';

  @override
  String get bookingCancelBooking => 'إلغاء الحجز';

  @override
  String get bookingCancelRequest => 'إلغاء الطلب';

  @override
  String get bookingCancellationPolicy => 'سياسة الإلغاء';

  @override
  String get bookingCommune => 'البلدية';

  @override
  String get bookingCommunePlaceholder => 'اختر البلدية (اختياري)';

  @override
  String get bookingContact => 'التواصل';

  @override
  String get bookingDate => 'التاريخ';

  @override
  String get bookingDateError => 'اختر يومًا متاحًا.';

  @override
  String get bookingDateRefused =>
      'لم يعد هذا اليوم متاحًا للحجز — اختر يومًا آخر.';

  @override
  String get bookingDateTime => 'التاريخ والوقت';

  @override
  String get bookingDetailTitle => 'الحجز';

  @override
  String get bookingEventType => 'نوع المناسبة';

  @override
  String get bookingEventTypeError => 'اختر نوع المناسبة.';

  @override
  String get bookingExtras => 'الإضافات';

  @override
  String get bookingFailedKept => 'لم يضِع شيء — كل ما أدخلته ما زال هنا.';

  @override
  String get bookingFailedOffline =>
      'يبدو أنك غير متصل. لم يضِع شيء — كل ما أدخلته ما زال هنا. اضغط «إعادة المحاولة» عند عودة الاتصال.';

  @override
  String get bookingFailedTitle => 'تعذّر إرسال طلبك';

  @override
  String get bookingFindSimilar => 'ابحث عن خدمات مشابهة';

  @override
  String get bookingFrom => 'من';

  @override
  String get bookingGuests => 'الضيوف';

  @override
  String get bookingGuestsError => 'أضف عدد الضيوف — السعر للفرد.';

  @override
  String get bookingGuestsHelper => 'يساعد مقدّم الخدمة على التحضير.';

  @override
  String get bookingLeaveReview => 'اترك تقييمًا';

  @override
  String get bookingNoCommune => 'غير محددة';

  @override
  String get bookingNoDate => 'لم يتم اختيار تاريخ — اختر يومًا متاحًا';

  @override
  String get bookingNoTime => 'بدون وقت';

  @override
  String get bookingNoWilayas => 'لا تذكر هذه الخدمة أي ولاية بعد.';

  @override
  String get bookingNotAcceptingBody =>
      'لا يستقبل طلبات حاليًا. كل ما أدخلته محفوظ، ويمكنك مراسلته في الأثناء.';

  @override
  String get bookingNote => 'ملاحظة لمقدّم الخدمة (اختياري)';

  @override
  String get bookingNoteHint => 'أي شيء يجب أن يعرفه';

  @override
  String get bookingPackSaving => 'توفير الباقة';

  @override
  String get bookingPackSection => 'الباقة';

  @override
  String get bookingPhoneHidden => 'مخفي';

  @override
  String get bookingPickNewDate => 'اختر تاريخًا جديدًا';

  @override
  String get bookingPrice => 'السعر';

  @override
  String get bookingProposeDate => 'اقترح تاريخًا جديدًا';

  @override
  String get bookingProviderConfirmsTime =>
      'يؤكد مقدّم الخدمة الوقت بالضبط بعد طلبك.';

  @override
  String get bookingReportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get bookingSearchCommune => 'ابحث عن بلدية';

  @override
  String get bookingSearchWilaya => 'ابحث عن ولاية';

  @override
  String get bookingSend => 'إرسال الطلب';

  @override
  String get bookingServiceSection => 'الخدمة';

  @override
  String get bookingTakenTitleUndated => 'حُجز هذا التاريخ للتو';

  @override
  String get bookingTime => 'الوقت';

  @override
  String get bookingTimeHelper => 'اختياري — يؤكد مقدّم الخدمة الوقت بالضبط.';

  @override
  String get bookingTimeHelperHourly => 'مطلوب: السعر بالساعة.';

  @override
  String get bookingTimeOverline => 'الوقت';

  @override
  String get bookingTo => 'إلى';

  @override
  String get bookingTooSoonBody =>
      'أصبحت التواريخ تتطلب مهلة أطول. كل ما أدخلته محفوظ — اختر يومًا لاحقًا.';

  @override
  String get bookingTooSoonTitle => 'أصبح هذا التاريخ قريبًا جدًا';

  @override
  String get bookingTotalCaption => 'المجموع';

  @override
  String get bookingTotalOnSite => 'المجموع · الدفع في الموقع';

  @override
  String get bookingTryAgain => 'إعادة المحاولة';

  @override
  String get bookingViewInvoice => 'عرض الفاتورة';

  @override
  String get bookingWhere => 'المكان';

  @override
  String get bookingWilaya => 'الولاية';

  @override
  String get bookingWilayaError => 'اختر مكان المناسبة.';

  @override
  String get bookingWilayaPlaceholder => 'اختر الولاية';

  @override
  String get bookingYourEvent => 'مناسبتك';

  @override
  String get bookingYourNote => 'ملاحظتك';

  @override
  String get bookingsEmptyCancelled => 'لا شيء ملغى';

  @override
  String get bookingsEmptyCancelledBody =>
      'تظهر هنا الحجوزات الملغاة والمرفوضة.';

  @override
  String get bookingsEmptyPast => 'لا توجد حجوزات سابقة بعد';

  @override
  String get bookingsEmptyPastBody =>
      'بعد انتهاء المناسبة، تنتقل إلى هنا مع فاتورتها.';

  @override
  String get bookingsEmptyPending => 'لا توجد طلبات قيد الانتظار';

  @override
  String get bookingsEmptyPendingBody =>
      'تنتظر هنا الطلبات التي ترسلها حتى يردّ مقدّم الخدمة.';

  @override
  String get bookingsEmptyUpcoming => 'لا توجد حجوزات قادمة';

  @override
  String get bookingsEmptyUpcomingBody =>
      'تظهر هنا الحجوزات المقبولة التي لم تحن مناسبتها بعد.';

  @override
  String get bookingsFindService => 'ابحث عن خدمة';

  @override
  String get bookingsTabCancelled => 'ملغاة';

  @override
  String get bookingsTabPast => 'سابقة';

  @override
  String get bookingsTabPending => 'قيد الانتظار';

  @override
  String get bookingsTabUpcoming => 'قادمة';

  @override
  String get bookingsTitle => 'حجوزاتي';

  @override
  String get cancelBookingConfirm => 'نعم، ألغِ الحجز';

  @override
  String get cancelBookingDone => 'تم إلغاء الحجز.';

  @override
  String get cancelBookingKeep => 'الإبقاء على حجزي';

  @override
  String get cancelBookingTitle => 'إلغاء هذا الحجز؟';

  @override
  String get cancelReasonHint => 'بضع كلمات لمقدّم الخدمة';

  @override
  String get cancelReasonLabel => 'لماذا تلغي؟';

  @override
  String get cancelRequestConfirm => 'نعم، ألغِ الطلب';

  @override
  String get cancelRequestDone => 'تم إلغاء الطلب.';

  @override
  String get cancelRequestKeep => 'الإبقاء على طلبي';

  @override
  String get cancelRequestTitle => 'إلغاء هذا الطلب؟';

  @override
  String get cancelNothingPaid =>
      'الدفع نقدًا يوم المناسبة، لذا لم يُدفع شيء عبر Eventor.';

  @override
  String get cancelledByOtherBody => 'لا تدين بشيء — لم يُدفع أي مبلغ.';

  @override
  String get cancelledByYouTitle => 'لقد ألغيت هذا الحجز';

  @override
  String get checkInAllGood => 'كل شيء على ما يرام';

  @override
  String get checkInAllGoodBody =>
      'تمت الخدمة كما اتُّفق. نُغلق الحجز ويمكنك ترك تقييم.';

  @override
  String get checkInCalloutAction => 'أخبرنا كيف جرى الأمر';

  @override
  String get checkInCalloutTitle => 'كيف جرى الأمر؟';

  @override
  String get checkInClosed => 'شكرًا — تم إغلاق الحجز.';

  @override
  String get checkInFootnote =>
      'إن لم يُبلَّغ عن أي مشكلة، يُغلق الحجز تلقائيًا بعد 3 أيام من المناسبة.';

  @override
  String get checkInHeading => 'كيف جرى الأمر؟';

  @override
  String get checkInNotNow => 'ليس الآن';

  @override
  String get checkInProblem => 'حدثت مشكلة';

  @override
  String get checkInProblemBody =>
      'عدم الحضور أو التأخر أو خدمة غير المتفق عليها. نفتح نزاعًا ويتدخّل الدعم.';

  @override
  String get checkInTitle => 'بعد المناسبة';

  @override
  String get contactNoteAccepted =>
      'تتم مشاركة أرقام الهاتف لأن هذا الحجز مقبول.';

  @override
  String get contactNoteCancelled =>
      'لم تعد أرقام الهاتف تُشارك في الحجوزات الملغاة.';

  @override
  String get contactNoteCompleted => 'تبقى أرقام الهاتف ظاهرة بعد المناسبة.';

  @override
  String get contactNoteDeclined =>
      'لا تُشارك أرقام الهاتف في الطلبات المرفوضة.';

  @override
  String get declinedBody => 'لم يُخصم أي مبلغ، ولا شيء محجوز لك.';

  @override
  String get disputeOpenBody => 'يدرس دعم Eventor الأمر وسيراسلك في الرسائل.';

  @override
  String get invoiceBackToBooking => 'العودة إلى الحجز';

  @override
  String get invoiceBilledTo => 'الفاتورة باسم';

  @override
  String get invoiceBooking => 'الحجز';

  @override
  String get invoiceDiscount => 'الخصم';

  @override
  String get invoiceDownload => 'تنزيل PDF';

  @override
  String get invoiceFrom => 'من';

  @override
  String get invoiceOverline => 'فاتورة';

  @override
  String get invoicePaidInCash => 'مدفوعة نقدًا';

  @override
  String get invoicePayOnTheDay => 'الدفع نقدًا يوم المناسبة';

  @override
  String get invoiceServiceBy => 'مقدّم الخدمة';

  @override
  String get invoiceSubtotal => 'المجموع الفرعي';

  @override
  String get invoiceTitle => 'الفاتورة';

  @override
  String get invoiceTotalPaid => 'المجموع المدفوع';

  @override
  String get invoiceTotalToPay => 'المجموع المستحق';

  @override
  String get invoiceVoidedBody => 'أُلغيت عند إلغاء الحجز. لا يُستحق أي مبلغ.';

  @override
  String get invoiceVoidedTitle => 'هذه الفاتورة ملغاة';

  @override
  String get packBookingContinue => 'متابعة';

  @override
  String get packBookingTitle => 'احجز هذه الباقة';

  @override
  String get packLegendBusy => 'خدمة غير متاحة';

  @override
  String get packLegendTooSoon => 'قريب جدًا / مضى';

  @override
  String get packPriceCaption => 'سعر الباقة';

  @override
  String get packReviewDatePlace => 'التاريخ والمكان';

  @override
  String get packReviewPackPrice => 'سعر الباقة';

  @override
  String get packReviewSend => 'إرسال طلب الباقة';

  @override
  String get packReviewTitle => 'راجع باقتك';

  @override
  String get packReviewYouSave => 'توفّر';

  @override
  String get problemBehaviour => 'السلوك';

  @override
  String get problemCancel => 'إلغاء';

  @override
  String get problemDamage => 'ضرر أو سلامة';

  @override
  String get problemDescriptionHelper =>
      'يطّلع دعم Eventor على هذا، مع محادثتك.';

  @override
  String get problemDescriptionHint => 'ماذا حدث ومتى';

  @override
  String get problemDescriptionLabel => 'ماذا حدث؟';

  @override
  String get problemDone =>
      'تم الإبلاغ عن المشكلة. سيتواصل معك دعم Eventor في الرسائل.';

  @override
  String get problemLate => 'تأخّر أو خدمة ناقصة';

  @override
  String get problemNoShow => 'لم يحضر مقدّم الخدمة';

  @override
  String get problemNotAsDescribed => 'ليست كما وُصفت';

  @override
  String get problemOther => 'أمر آخر';

  @override
  String get problemPrice => 'خلاف على السعر';

  @override
  String get problemSubmit => 'الإبلاغ عن المشكلة';

  @override
  String get problemTitle => 'ما الذي حدث؟';

  @override
  String get problemTypeLabel => 'ما هي المشكلة؟';

  @override
  String get proposalCurrent => 'الحالي';

  @override
  String get proposalDecline => 'رفض';

  @override
  String get proposalDeclined => 'احتفظت بالتاريخ الأصلي.';

  @override
  String get proposalProposed => 'المقترح';

  @override
  String get proposalWithdraw => 'سحب اقتراحي';

  @override
  String get proposalWithdrawn => 'تم سحب الاقتراح — يبقى التاريخ كما كان.';

  @override
  String get requestBookingTitle => 'طلب حجز';

  @override
  String get requestSentHeading => 'طلبك في الطريق';

  @override
  String get requestSentNext => 'ما الخطوات التالية';

  @override
  String get requestSentReference => 'المرجع';

  @override
  String get requestSentTitle => 'تم إرسال الطلب';

  @override
  String get requestSentViewBooking => 'عرض الحجز';

  @override
  String get requestSentStep2 => 'يقبل، أو يقترح تاريخًا آخر';

  @override
  String get requestSentStep2Body => 'يُشارك رقم هاتفه بعد القبول.';

  @override
  String get requestSentStep3 => 'تدفع يوم المناسبة';

  @override
  String get requestSentStep3Body =>
      'نقدًا، مباشرةً لمقدّم الخدمة. لا يتقاضى Eventor منك شيئًا.';

  @override
  String get rescheduleCurrentlyBooked => 'المحجوز حاليًا';

  @override
  String get rescheduleCurrentlyRequested => 'المطلوب حاليًا';

  @override
  String get rescheduleFailedTitle => 'تعذّر إرسال التاريخ الجديد';

  @override
  String get rescheduleLegendCurrent => 'الحجز الحالي';

  @override
  String get rescheduleMove => 'تغيير التاريخ';

  @override
  String get rescheduleMoved => 'تم تغيير التاريخ.';

  @override
  String get rescheduleNewDate => 'التاريخ والوقت الجديدان';

  @override
  String get rescheduleProposedCaption => 'مقترح';

  @override
  String get rescheduleReasonError => 'اذكر السبب — يقرأه مقدّم الخدمة أولًا.';

  @override
  String get rescheduleReasonHint => 'القاعة محجوزة مرتين…';

  @override
  String get rescheduleReasonLabel => 'لماذا التغيير؟';

  @override
  String get rescheduleSend => 'إرسال الاقتراح';

  @override
  String get rescheduleSent => 'تم إرسال الاقتراح. سنُعلمك عند الرد.';

  @override
  String get rescheduleTitle => 'اقترح تاريخًا جديدًا';

  @override
  String get rescheduleTitlePending => 'تغيير التاريخ';

  @override
  String get reviewBody => 'يساعد تقييمك العملاء الآخرين على الاختيار.';

  @override
  String get reviewCalloutTitle => 'كيف كانت التجربة؟';

  @override
  String get reviewCommentHelper => 'يُنشر في ملفه.';

  @override
  String get reviewCommentHint => 'ما الذي كان جيدًا، وما الذي يمكن تحسينه';

  @override
  String get reviewCommentLabel => 'تقييمك';

  @override
  String get reviewDone => 'شكرًا — تم نشر تقييمك.';

  @override
  String get reviewLater => 'لاحقًا';

  @override
  String get reviewSubmit => 'نشر التقييم';

  @override
  String get stepCancelledByYou => 'ألغيته أنت';

  @override
  String get stepCompleted => 'مكتمل';

  @override
  String get stepConfirmAfter => 'أكّد بعد المناسبة';

  @override
  String get stepEventDay => 'يوم المناسبة';

  @override
  String get stepHowDidItGo => 'أخبرنا كيف جرى الأمر';

  @override
  String get stepNewDateProposed => 'اقتُرح تاريخ جديد';

  @override
  String get stepNotApplicable => 'لا ينطبق';

  @override
  String get stepRequested => 'تم الطلب';

  @override
  String get stepWaitingForYou => 'بانتظارك';

  @override
  String get stepYouConfirmed => 'أكّدت أن كل شيء سار جيدًا';

  @override
  String get stepperLess => 'أقل';

  @override
  String get stepperMore => 'أكثر';

  @override
  String bookingBasePrice(String unit) {
    return 'السعر الأساسي · $unit';
  }

  @override
  String bookingBookAgain(String provider) {
    return 'احجز $provider مرة أخرى';
  }

  @override
  String bookingCallLabel(String provider) {
    return 'اتصل بـ $provider';
  }

  @override
  String bookingCashFootnote(String provider) {
    return 'الدفع نقدًا مباشرةً لـ $provider يوم المناسبة. لا يتقاضى Eventor منك شيئًا.';
  }

  @override
  String bookingCompletedOn(String date) {
    return 'اكتمل $date';
  }

  @override
  String bookingGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ضيف',
      many: '$count ضيفًا',
      few: '$count ضيوف',
      two: 'ضيفان',
      one: 'ضيف واحد',
    );
    return '$_temp0';
  }

  @override
  String bookingGuestsMax(int max) {
    return 'حتى $max ضيف.';
  }

  @override
  String bookingMessageProvider(String provider) {
    return 'راسل $provider';
  }

  @override
  String bookingNotAcceptingTitle(String provider) {
    return 'أوقف $provider الحجوزات الجديدة';
  }

  @override
  String bookingNoticeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يجب الحجز قبل $count يومًا على الأقل.',
      few: 'يجب الحجز قبل $count أيام على الأقل.',
      two: 'يجب الحجز قبل يومين على الأقل.',
      one: 'يجب الحجز قبل يوم واحد على الأقل.',
    );
    return '$_temp0';
  }

  @override
  String bookingPolicySetBy(String provider) {
    return 'حدّدها $provider';
  }

  @override
  String bookingRequestedOn(String date) {
    return 'طُلب في $date';
  }

  @override
  String bookingTakenBody(String provider) {
    return 'قبل $provider حجزًا آخر في ذلك التاريخ أثناء ملئك للطلب. كل ما أدخلته محفوظ — اختر تاريخًا آخر للمتابعة.';
  }

  @override
  String bookingTakenTitle(String date) {
    return 'حُجز يوم $date للتو';
  }

  @override
  String bookingWilayaSheetBody(String provider) {
    return 'حيث يعمل $provider.';
  }

  @override
  String cancelBodyShort(String provider) {
    return 'يُبلَّغ $provider فورًا ويُحرَّر الموعد.';
  }

  @override
  String cancelBookingBody(String provider) {
    return 'يُبلَّغ $provider فورًا ويُحرَّر الموعد. لا يمكن التراجع — سيتعيّن عليك طلب التاريخ من جديد.';
  }

  @override
  String cancelDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'يفصلك $days يومًا عن المناسبة.',
      few: 'يفصلك $days أيام عن المناسبة.',
      two: 'يفصلك يومان عن المناسبة.',
      one: 'مناسبتك غدًا.',
      zero: 'مناسبتك اليوم.',
    );
    return '$_temp0';
  }

  @override
  String cancelPolicyQuote(String provider, String policy) {
    return 'سياسة $provider: «$policy»';
  }

  @override
  String cancelReasonHelper(String provider) {
    return 'سيرى $provider هذا السبب.';
  }

  @override
  String cancelRequestBody(String provider) {
    return 'يُبلَّغ $provider فورًا ويُحرَّر التاريخ الذي حجزته.';
  }

  @override
  String cancelledByOtherTitle(String provider) {
    return 'ألغى $provider هذا الحجز';
  }

  @override
  String cancelledByYouBody(String provider) {
    return 'تم إبلاغ $provider. لا تدين بشيء — لم يُدفع أي مبلغ.';
  }

  @override
  String checkInBody(String date) {
    return 'كانت مناسبتك يوم $date. أخبرنا قبل أن نُغلق الحجز — يكفي نقرة واحدة.';
  }

  @override
  String checkInCalloutBody(String provider) {
    return 'أكّد أن $provider قدّم الخدمة كما اتُّفق، أو أبلغ عن مشكلة.';
  }

  @override
  String checkInWaiting(String provider) {
    return 'شكرًا! يُغلق الحجز بمجرد أن يؤكد $provider أيضًا.';
  }

  @override
  String contactNotePending(String provider) {
    return 'يظهر رقم الهاتف بمجرد أن يقبل $provider طلبك.';
  }

  @override
  String declinedTitle(String provider) {
    return 'رفض $provider هذا الطلب';
  }

  @override
  String disputeOpenTitle(String reference) {
    return 'تم الإبلاغ عن مشكلة · $reference';
  }

  @override
  String invoiceFootnote(String provider) {
    return 'صادرة عن Eventor لسجلاتك. يُدفع المبلغ مباشرةً إلى $provider.';
  }

  @override
  String invoiceIssued(String date) {
    return 'صدرت في $date';
  }

  @override
  String invoicePaidNote(String provider, String date) {
    return 'دُفعت نقدًا إلى $provider يوم $date. لم يُضَف شيء إلى مجموعك.';
  }

  @override
  String invoiceShareSubject(String number) {
    return 'فاتورة Eventor ‏$number';
  }

  @override
  String invoiceToPayNote(String provider, String date) {
    return 'تُدفع نقدًا إلى $provider يوم $date. لا يضيف Eventor شيئًا إلى مجموعك.';
  }

  @override
  String packBookingDaysIntro(int count) {
    return 'لا يمكن اختيار إلا الأيام التي تكون فيها كل خدمات الباقة ($count) متاحة.';
  }

  @override
  String packBookingSummary(int count, String provider, String wilaya) {
    return 'خدمات الباقة ($count) كلها من $provider · $wilaya';
  }

  @override
  String packLegendAllFree(int count) {
    return 'كلها متاحة ($count)';
  }

  @override
  String packReviewOneRequest(int count, String provider) {
    return 'كل الخدمات ($count) يقدّمها $provider. حجز الباقة يرسل طلبًا واحدًا لها جميعًا.';
  }

  @override
  String packReviewSum(int count) {
    return 'مجموع الخدمات ($count)';
  }

  @override
  String problemBody(String provider) {
    return 'أخبرنا بما حدث مع $provider. يتدخّل دعم Eventor؛ الدفع كان نقدًا، فلا توجد استرجاعات ولا رسوم.';
  }

  @override
  String problemDescriptionTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرفًا إضافيًا من فضلك.',
      few: '$count أحرف إضافية من فضلك.',
      two: 'حرفان إضافيان من فضلك.',
      one: 'حرف واحد إضافي من فضلك.',
    );
    return '$_temp0';
  }

  @override
  String proposalAccept(String date) {
    return 'قبول $date';
  }

  @override
  String proposalAccepted(String date) {
    return 'تم قبول التاريخ الجديد: $date.';
  }

  @override
  String proposalConsequence(String date, String provider) {
    return 'إن رفضت، يبقى حجز $date قائمًا وقد يلغيه $provider.';
  }

  @override
  String proposalMineBody(String provider) {
    return 'يبقى تاريخك الحالي محجوزًا حتى يردّ $provider.';
  }

  @override
  String proposalMineTitle(String date) {
    return 'اقترحت $date';
  }

  @override
  String proposalTitle(String provider) {
    return 'يقترح $provider تاريخًا جديدًا';
  }

  @override
  String reasonGiven(String reason) {
    return 'السبب المذكور: «$reason»';
  }

  @override
  String requestSentStep1(String provider) {
    return 'يراجع $provider طلبك';
  }

  @override
  String requestSentStep1Deadline(int hours) {
    return 'أمامه $hours ساعة للرد — سنُعلمك.';
  }

  @override
  String requestSentStep1Usually(String time) {
    return 'عادةً خلال $time — سنُعلمك.';
  }

  @override
  String rescheduleBookedDays(String provider) {
    return 'الأيام التي يكون فيها $provider محجوزًا مشطوبة.';
  }

  @override
  String rescheduleHoldNote(String date, String provider) {
    return 'يبقى موعدك في $date محجوزًا حتى يردّ $provider. إن رفض، يبقى الحجز الأصلي كما هو ولا يتغيّر السعر.';
  }

  @override
  String reschedulePendingNote(String provider) {
    return 'ينتقل طلبك إلى التاريخ الجديد فورًا؛ ويبقى على $provider قبوله.';
  }

  @override
  String rescheduleReasonHelper(String provider) {
    return 'سيقرأ $provider هذا.';
  }

  @override
  String rescheduleTakenBody(String provider) {
    return 'لم يعد $provider متاحًا في ذلك اليوم. اختر تاريخًا آخر.';
  }

  @override
  String reviewCalloutBody(String provider) {
    return 'يساعد تقييمك لـ $provider العملاء الآخرين على الاختيار.';
  }

  @override
  String reviewCommentTooShort(int count) {
    return '$count أحرف على الأقل.';
  }

  @override
  String reviewStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة',
      few: '$count نجوم',
      two: 'نجمتان',
      one: 'نجمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String reviewTitle(String provider) {
    return 'قيّم $provider';
  }

  @override
  String stepAcceptedBy(String provider) {
    return 'قبله $provider';
  }

  @override
  String stepCancelledBy(String provider) {
    return 'ألغاه $provider';
  }

  @override
  String stepDeclinedBy(String provider) {
    return 'رفضه $provider';
  }

  @override
  String stepRepliesWithinHours(int hours) {
    return 'يردّ خلال $hours ساعة';
  }

  @override
  String stepUsuallyReplies(String time) {
    return 'يردّ عادةً خلال $time';
  }

  @override
  String stepWaitingFor(String provider) {
    return 'بانتظار $provider';
  }

  @override
  String stepYouConfirmedWaiting(String provider) {
    return 'أكّدت · بانتظار $provider';
  }

  @override
  String get bookingNextDay => 'اليوم التالي';

  @override
  String get bookingNextDayMark => 'اليوم التالي';

  @override
  String get bookingDurationHalfHour => '30 دقيقة';

  @override
  String bookingDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتان',
      one: 'ساعة',
    );
    return '$_temp0';
  }

  @override
  String bookingDurationHoursHalf(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة و30 دقيقة',
      many: '$count ساعة و30 دقيقة',
      few: '$count ساعات و30 دقيقة',
      two: 'ساعتان و30 دقيقة',
      one: 'ساعة و30 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String bookingGuestsTooMany(int max) {
    return 'الحد الأقصى $max ضيف لهذا الحجز.';
  }

  @override
  String get invoiceShare => 'مشاركة';

  @override
  String get invoiceSavedToDownloads => 'حُفظت الفاتورة في التنزيلات.';

  @override
  String get invoiceSavedToFiles => 'حُفظت الفاتورة في الملفات › Eventor.';

  @override
  String get invoiceOpen => 'فتح';

  @override
  String get invoiceSaveFailed =>
      'تعذّر حفظ الفاتورة على هذا الهاتف. حاول مجددًا.';

  @override
  String get invoiceSaveDenied =>
      'اسمح بالوصول إلى مساحة التخزين لحفظ الفاتورة.';

  @override
  String get invoiceNoPdfApp => 'لا يوجد تطبيق على هذا الهاتف لفتح ملفات PDF.';

  @override
  String get downloadsChannelName => 'التنزيلات';

  @override
  String get invoiceDownloadNoticeText => 'اكتمل التنزيل · اضغط للفتح';

  @override
  String get availabilityTitle => 'التوفّر';

  @override
  String get availabilityLegendFree => 'متاح';

  @override
  String get availabilityLegendPartial => 'محجوب جزئيًا';

  @override
  String get availabilityLegendBlocked => 'محجوب';

  @override
  String get availabilityLegendHeld => 'طلب محجوز مؤقتًا';

  @override
  String get availabilityLegendBooked => 'محجوز';

  @override
  String get availabilityToday => 'اليوم';

  @override
  String availabilityNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يجب أن يحجز العملاء قبل $count يوم على الأقل.',
      many: 'يجب أن يحجز العملاء قبل $count يومًا على الأقل.',
      few: 'يجب أن يحجز العملاء قبل $count أيام على الأقل.',
      two: 'يجب أن يحجز العملاء قبل يومين على الأقل.',
      one: 'يجب أن يحجز العملاء قبل يوم واحد على الأقل.',
      zero: 'يمكن للعملاء الحجز لأي يوم.',
    );
    return '$_temp0';
  }

  @override
  String get availabilityTapHint => 'اضغط على يوم لمعرفة ما فيه أو لحجبه.';

  @override
  String get availabilityBlockDay => 'حجب يوم';

  @override
  String availabilityDaySummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوجد $count أمر في هذا اليوم.',
      many: 'يوجد $count أمرًا في هذا اليوم.',
      few: 'توجد $count أمور في هذا اليوم.',
      two: 'يوجد أمران في هذا اليوم.',
      one: 'يوجد أمر واحد في هذا اليوم.',
      zero: 'لا شيء في هذا اليوم بعد.',
    );
    return '$_temp0';
  }

  @override
  String get availabilityDayRemoveHint =>
      'يمكن إزالة الحجب الذي أضفته أنت فقط.';

  @override
  String get availabilityDayPast => 'مضى هذا اليوم ولا يمكن تغيير شيء فيه.';

  @override
  String get availabilityItemBlockedAllDay => 'محجوب طوال اليوم';

  @override
  String get availabilityItemBlockedSlot => 'محجوب';

  @override
  String availabilityItemBooked(String reference) {
    return 'محجوز — $reference';
  }

  @override
  String availabilityItemHeld(String reference) {
    return 'طلب محجوز مؤقتًا — $reference';
  }

  @override
  String get availabilityAllServices => 'كل الخدمات';

  @override
  String availabilityItemNote(String note) {
    return '«$note»';
  }

  @override
  String get availabilityRemove => 'إزالة';

  @override
  String get availabilityCannotRemove => 'لا يمكن إزالته';

  @override
  String get availabilityWhyBooked =>
      'حجز مقبول. يمكن إلغاؤه أو تغيير موعده من صفحة الحجز.';

  @override
  String get availabilityWhyHeld => 'طلب ينتظر ردّك يحجز هذا اليوم مؤقتًا.';

  @override
  String get availabilityBlockWholeDay => 'حجب اليوم كاملًا';

  @override
  String get availabilityBlockSlot => 'حجب فترة زمنية';

  @override
  String get availabilityBlockAnotherSlot => 'حجب فترة أخرى';

  @override
  String get availabilityClose => 'إغلاق';

  @override
  String get availabilityAlreadyBlocked =>
      'هذا اليوم محجوب بالفعل لكل الخدمات.';

  @override
  String get availabilityFullyBooked =>
      'هذا اليوم محجوز بالكامل، فلا يبقى فيه ما يُحجب.';

  @override
  String availabilityBlockDayTitle(String day) {
    return 'حجب $day';
  }

  @override
  String availabilityBlockSlotTitle(String day) {
    return 'حجب جزء من $day';
  }

  @override
  String get availabilityBlockDayBody =>
      'لن يتمكن العملاء من حجز هذا اليوم. يمكنك إزالة الحجب في أي وقت.';

  @override
  String get availabilityBlockSlotBody =>
      'يظل بإمكان العملاء حجز بقية اليوم. يمكنك إزالة الحجب في أي وقت.';

  @override
  String get availabilityModeWholeDay => 'اليوم كامل';

  @override
  String get availabilityModeSlot => 'فترة زمنية';

  @override
  String get availabilityModeSelected => 'محدّد';

  @override
  String get availabilityServicesLabel => 'الخدمات المشمولة';

  @override
  String get availabilityServicesSubtitle =>
      'احجب كل الخدمات أو خدمة واحدة فقط.';

  @override
  String get availabilityServicesFailed => 'تعذّر تحميل خدماتك. حاول مرة أخرى.';

  @override
  String get availabilityNoteLabel => 'ملاحظة (تراها أنت فقط)';

  @override
  String get availabilityNoteHint => 'مثال: زفاف عائلي';

  @override
  String get availabilityConfirmDay => 'احجب اليوم';

  @override
  String get availabilityConfirmSlot => 'احجب الفترة';

  @override
  String get availabilityCancel => 'إلغاء';

  @override
  String get availabilitySlotHelper =>
      'يظل بإمكان العملاء الحجز خارج هذه الساعات.';

  @override
  String get availabilityTimesMissing => 'اختر بداية الفترة ونهايتها.';

  @override
  String get availabilityHeldWarning =>
      'يوجد طلب ينتظر ردّك في هذا اليوم. الحجب لا يرفض الطلب.';

  @override
  String get availabilityBookedWarning =>
      'يوجد حجز مقبول في هذا اليوم. الحجب لا يلغي الحجز.';

  @override
  String get availabilityErrorDatePast => 'مضى هذا اليوم. اختر يومًا آخر.';

  @override
  String get availabilityErrorServiceInvalid =>
      'لم يعد بالإمكان حجب هذه الخدمة. اختر خدمة أخرى أو احجب كل الخدمات.';

  @override
  String get availabilityErrorNotRemovable =>
      'لم يعد بالإمكان إزالة هذا الحجب. تم تحديث التقويم.';

  @override
  String get availabilityErrorNotFound =>
      'تمت إزالة هذا الحجب مسبقًا. تم تحديث التقويم.';

  @override
  String availabilityBlockedDayToast(String day) {
    return 'تم حجب $day.';
  }

  @override
  String availabilityBlockedSlotToast(String day) {
    return 'تم حجب جزء من $day.';
  }

  @override
  String get availabilityRemovedToast => 'تمت إزالة الحجب.';

  @override
  String get availabilityRestoredToast => 'تمت إعادة الحجب.';

  @override
  String get providerRequestsTabTitle => 'الطلبات';

  @override
  String get providerRequestsChipRequests => 'الطلبات';

  @override
  String get providerRequestsChipUpcoming => 'القادمة';

  @override
  String get providerRequestsChipPast => 'السابقة';

  @override
  String get providerRequestsEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String providerRequestsEmptyBody(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
    );
    return 'عندما يطلب عميل حجز إحدى خدماتك، يصلك الطلب هنا. أمامك $_temp0 لقبوله أو رفضه قبل أن تنتهي صلاحيته.';
  }

  @override
  String get providerRequestsEmptyUpcomingTitle => 'لا حجوزات قادمة';

  @override
  String get providerRequestsEmptyUpcomingBody =>
      'تظهر هنا الطلبات التي تقبلها حتى يوم المناسبة.';

  @override
  String get providerRequestsEmptyPastTitle => 'لا توجد حجوزات سابقة بعد';

  @override
  String get providerRequestsEmptyPastBody =>
      'بعد انتهاء المناسبة، ينتقل الحجز إلى هنا مع فاتورته.';

  @override
  String get providerRequestsReviewBody =>
      'نراجع مستنداتك حاليًا. تبقى خدماتك غير منشورة حتى ذلك الحين، فلا يستطيع العملاء إرسال طلبات إليك بعد.';

  @override
  String get providerRequestsRejectedBody =>
      'لم تُقبل بعض مستنداتك. تبقى خدماتك غير منشورة حتى تتم الموافقة على ملفك، فلا يستطيع العملاء إرسال طلبات إليك بعد.';

  @override
  String get providerRequestsSeeDocuments => 'عرض مستنداتي';

  @override
  String providerRequestsReplyWithin(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'أجب خلال $hours ساعة',
      few: 'أجب خلال $hours ساعات',
      two: 'أجب خلال ساعتين',
      one: 'أجب خلال ساعة',
      zero: 'أجب الآن',
    );
    return '$_temp0';
  }

  @override
  String providerRequestsAccepted(String name) {
    return 'تم قبول طلب $name — تجده الآن ضمن القادمة.';
  }

  @override
  String get providerBookingTitleRequest => 'الطلب';

  @override
  String providerBookingStepRequestedBy(String client) {
    return 'طلب من $client';
  }

  @override
  String get providerBookingStepYourReply => 'ردّك';

  @override
  String get providerBookingStepYouAccepted => 'قبلت الطلب';

  @override
  String get providerBookingStepYouDeclined => 'رفضت الطلب';

  @override
  String providerBookingStepCancelledBy(String client) {
    return 'أُلغي من طرف $client';
  }

  @override
  String get providerBookingStepCancelledByEventor => 'أُلغي من طرف Eventor';

  @override
  String get providerBookingStepConfirmEvent => 'أكّد المناسبة';

  @override
  String get providerBookingStepWaitingBoth => 'في انتظار تأكيدكما';

  @override
  String providerBookingStepYouConfirmed(String client) {
    return 'أكّدت · في انتظار $client';
  }

  @override
  String providerBookingStepClientConfirmed(String client) {
    return 'تأكيد من $client · في انتظار تأكيدك';
  }

  @override
  String get providerBookingStepBothConfirmed => 'أكّدتما كلاكما';

  @override
  String providerBookingStepClientProposed(String client) {
    return 'موعد جديد مقترح من $client';
  }

  @override
  String get providerBookingStepYouProposed => 'اقترحت موعدًا جديدًا';

  @override
  String providerBookingStepWaitingFor(String client) {
    return 'في انتظار $client';
  }

  @override
  String providerBookingYourService(String category) {
    return 'خدمتك · $category';
  }

  @override
  String get providerBookingYourPack => 'باقتك';

  @override
  String get providerBookingTheEvent => 'المناسبة';

  @override
  String get providerBookingClientNote => 'ملاحظة العميل';

  @override
  String get providerBookingTotalOnSite => 'المجموع · يدفعه العميل في المكان';

  @override
  String get providerBookingCashNote =>
      'يدفع لك العميل نقدًا يوم المناسبة. لا يُقتطع أي مبلغ عبر Eventor.';

  @override
  String get providerBookingClientSection => 'العميل';

  @override
  String get providerBookingContactHidden => 'مخفي حتى تقبل الطلب';

  @override
  String get providerBookingContactNotShared => 'غير مُشارَك';

  @override
  String providerBookingContactPending(String client) {
    return 'يظهر هنا رقم الهاتف والبريد الإلكتروني لـ$client فور قبولك الطلب.';
  }

  @override
  String providerBookingContactAccepted(String client) {
    return 'يظهر رقم الهاتف والبريد الإلكتروني لـ$client لأنك قبلت هذا الحجز.';
  }

  @override
  String providerBookingContactUntilClosed(String client) {
    return 'يبقى رقم الهاتف والبريد الإلكتروني لـ$client ظاهرين حتى يُغلق الحجز.';
  }

  @override
  String get providerBookingContactDeclined =>
      'لا تُشارَك بيانات التواصل أبدًا في طلب رفضته.';

  @override
  String get providerBookingContactHistory =>
      'تبقى بيانات التواصل ظاهرة ما دام هذا الحجز ضمن سجلّك.';

  @override
  String get providerBookingContactWithdrawn =>
      'لا تُشارَك بيانات التواصل في طلب أُلغي.';

  @override
  String get providerBookingPolicySetByYou => 'أنت من حدّدها';

  @override
  String providerBookingMessageClient(String client) {
    return 'مراسلة $client';
  }

  @override
  String get providerBookingAcceptRequest => 'قبول الطلب';

  @override
  String get providerBookingConfirmEvent => 'أكّد المناسبة';

  @override
  String get providerBookingDeclinedTitle => 'لقد رفضت هذا الطلب';

  @override
  String providerBookingDeclinedBody(String client) {
    return 'أصبح التاريخ متاحًا من جديد في تقويمك، وتم إبلاغ $client.';
  }

  @override
  String providerBookingCancelledByClientTitle(String client) {
    return 'أُلغي هذا الحجز من طرف $client';
  }

  @override
  String get providerBookingCancelledByClientBody =>
      'أصبح التاريخ متاحًا من جديد في تقويمك، وأُلغيت الفاتورة.';

  @override
  String providerBookingCancelledByYouBody(String client) {
    return 'تم إبلاغ $client، وأصبح التاريخ متاحًا من جديد في تقويمك، وأُلغيت الفاتورة.';
  }

  @override
  String get providerBookingCancelledByEventorTitle =>
      'أُلغي هذا الحجز من طرف Eventor';

  @override
  String providerBookingRequestWithdrawnTitle(String client) {
    return 'أُلغي هذا الطلب من طرف $client';
  }

  @override
  String get providerBookingRequestWithdrawnBody =>
      'أصبح التاريخ متاحًا من جديد في تقويمك.';

  @override
  String providerBookingReviewTitle(String client) {
    return 'يمكن لـ$client تقييم هذا الحجز';
  }

  @override
  String get providerBookingReviewBody =>
      'يظهر التقييم في قسم التقييمات، حيث يمكنك الردّ عليه مرة واحدة. أمام العملاء 60 يومًا بعد المناسبة لكتابة تقييم.';

  @override
  String providerBookingProposalTitle(String client) {
    return 'موعد جديد مقترح من $client';
  }

  @override
  String providerBookingProposalHelper(String date, String client) {
    return 'إذا رفضت، يبقى حجز $date قائمًا وقد يُلغى من طرف $client.';
  }

  @override
  String providerBookingProposalSentTitle(String date) {
    return 'تم إرسال الاقتراح: $date';
  }

  @override
  String providerBookingProposalSentBody(String date, String client) {
    return 'يبقى الحجز في $date حتى يصل ردّ $client.';
  }

  @override
  String get providerBookingWithdraw => 'سحب';

  @override
  String providerBookingProposalSentToast(String client) {
    return 'تم إرسال الاقتراح. سيُبلَّغ $client.';
  }

  @override
  String providerBookingCancelBody(String client) {
    return 'سيُبلَّغ $client فورًا، وسيُحرَّر التاريخ في تقويمك وتُلغى الفاتورة. لا يمكن التراجع عن هذا.';
  }

  @override
  String get providerBookingCancelReasonHint =>
      'مثال: القاعة مغلقة للصيانة في ذلك اليوم';

  @override
  String get providerBookingCancelNote =>
      'يعتمد عليك العملاء: لا تُلغِ إلا إذا لم يكن هناك حل آخر. اقتراح موعد جديد غالبًا ما يكون أفضل.';

  @override
  String get providerBookingCancelKeep => 'الإبقاء على الحجز';

  @override
  String get providerBookingDeclineTitle => 'رفض هذا الطلب؟';

  @override
  String get providerBookingDeclineReasonLabel => 'لماذا ترفض الطلب؟';

  @override
  String get providerBookingProblemClientNoShow => 'لم يحضر العميل';

  @override
  String get providerBookingProblemCancellation => 'خلاف حول الإلغاء';

  @override
  String get providerBookingLegendFree => 'متاح';

  @override
  String get providerBookingLegendBlocked => 'محجوب من طرفك';

  @override
  String get providerBookingRescheduleFootnote =>
      'تظهر الأيام المحجوزة أو المحجوبة من طرفك بلون باهت.';

  @override
  String get providerBookingTimeHelper =>
      'الأوقات التي طلبها العميل، ما لم تغيّرها.';

  @override
  String get providerBookingRescheduleReasonHint =>
      'مثال: القاعة متاحة فقط في الأسبوع التالي';

  @override
  String providerBookingRescheduleReasonError(String client) {
    return 'اذكر السبب — يطّلع عليه $client أولًا.';
  }

  @override
  String providerBookingRescheduleHold(String date, String client) {
    return 'يبقى حجز $date كما هو حتى يصل ردّ $client. وإذا رُفض الاقتراح، لا يتغيّر شيء ويبقى السعر نفسه.';
  }

  @override
  String providerBookingReschedulePendingNote(String client) {
    return 'ينتقل الطلب إلى التاريخ الجديد فورًا ويُبلَّغ $client. ويمكنك بعدها قبوله.';
  }

  @override
  String get providerBookingRescheduleTakenBody =>
      'لم تعد متاحًا في ذلك اليوم. اختر تاريخًا آخر.';

  @override
  String providerBookingCheckInBody(String client, String date) {
    return 'أقيمت المناسبة مع $client يوم $date. أكّد قبل أن نغلق الحجز — الأمر لا يستغرق سوى نقرة واحدة.';
  }

  @override
  String providerBookingAllGoodBody(String client) {
    return 'جرت المناسبة كما هو متفق عليه. نغلق الحجز ويمكن لـ$client كتابة تقييم.';
  }

  @override
  String get providerBookingProblemBody =>
      'لم يحضر العميل، أو حدث خطأ آخر. نفتح نزاعًا ويتدخّل فريق الدعم.';

  @override
  String get providerBookingRemindTomorrow => 'ذكّرني غدًا';

  @override
  String get providerBookingCheckInFootnote =>
      'إذا لم يردّ أي منكما، يُغلق الحجز تلقائيًا بعد 72 ساعة من المناسبة.';

  @override
  String providerBookingCheckInWaiting(String client) {
    return 'شكرًا! يُغلق الحجز فور وصول تأكيد $client أيضًا.';
  }

  @override
  String get providerBookingCheckInNothing =>
      'لا يوجد ما يستدعي التأكيد في هذا الحجز الآن.';

  @override
  String get providerBookingOpen => 'عرض الحجز';

  @override
  String get providerServiceTabTitle => 'خدماتي';

  @override
  String get providerPackTabTitle => 'باقاتي';

  @override
  String get providerServiceChipServices => 'خدماتي';

  @override
  String get providerServiceChipPacks => 'الباقات';

  @override
  String get providerServiceEmptyTitle => 'لا توجد خدمات بعد';

  @override
  String get providerServiceEmptyBody =>
      'الخدمة هي ما يجده العملاء ويحجزونه — باقة أو جلسة أو تأجير. أضف واحدة، ثم انشرها عندما تصبح جاهزة.';

  @override
  String providerServiceRatingLine(int count, String rating) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating · $count تقييم',
      many: '$rating · $count تقييمًا',
      few: '$rating · $count تقييمات',
      two: '$rating · تقييمان',
      one: '$rating · تقييم واحد',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceNoReviews => 'لا تقييمات بعد';

  @override
  String get providerServiceNotPublishedYet => 'لم تُنشر بعد';

  @override
  String providerServiceHiddenOn(String date) {
    return 'أُخفيت في $date';
  }

  @override
  String providerServicePhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صورة',
      many: '$count صورة',
      few: '$count صور',
      two: 'صورتان',
      one: 'صورة واحدة',
      zero: 'بلا صور',
    );
    return '$_temp0';
  }

  @override
  String providerServiceBookingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حجز',
      many: '$count حجزًا',
      few: '$count حجوزات',
      two: 'حجزان',
      one: 'حجز واحد',
      zero: 'بلا حجوزات',
    );
    return '$_temp0';
  }

  @override
  String providerServiceMissingNote(String items) {
    return 'ناقص قبل النشر: $items';
  }

  @override
  String get providerServiceMissingTitleEn => 'العنوان بالإنجليزية';

  @override
  String get providerServiceMissingTitleAr => 'العنوان بالعربية';

  @override
  String get providerServiceMissingDescriptionEn => 'الوصف بالإنجليزية';

  @override
  String get providerServiceMissingDescriptionAr => 'الوصف بالعربية';

  @override
  String get providerServiceMissingPrice => 'سعر أساسي';

  @override
  String get providerServiceMissingPhotos => 'صورة';

  @override
  String get providerServiceMissingCategory => 'فئة';

  @override
  String get providerServiceMissingWilayas => 'ولاية مفتوحة';

  @override
  String get providerServiceListSeparator => '، ';

  @override
  String providerServiceNotVisibleClosed(int count, String wilayas) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'غير ظاهرة للعملاء — $wilayas مغلقة على Eventor حاليًا',
      one: 'غير ظاهرة للعملاء — $wilayas مغلقة على Eventor حاليًا',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceNotVisibleNoWilaya =>
      'غير ظاهرة للعملاء — لا تغطي أي ولاية مفتوحة على Eventor';

  @override
  String get providerServiceNotVisibleReview =>
      'غير ظاهرة للعملاء — ملفك قيد المراجعة';

  @override
  String get providerServiceNotVisibleBlocked =>
      'غير ظاهرة للعملاء — حسابك محظور';

  @override
  String get providerServiceHiddenFinal =>
      'أخفت Eventor هذه الخدمة. لا يراها العملاء ولا يمكنك نشرها من جديد، لكن تعديلاتك تُحفظ.';

  @override
  String get providerServiceHiddenReviewable =>
      'أخفت Eventor هذه الخدمة ولا يراها العملاء. أصلحها ثم تواصل مع الدعم لمراجعتها من جديد، وتعديلاتك تُحفظ.';

  @override
  String providerServiceHiddenMessage(String message) {
    return 'ملاحظة Eventor: «$message»';
  }

  @override
  String get providerServiceUnpublish => 'إلغاء النشر';

  @override
  String get providerServiceEdit => 'تعديل';

  @override
  String get providerServicePublish => 'نشر';

  @override
  String get providerServicePublished => 'نُشرت — يمكن للعملاء إيجادها الآن';

  @override
  String get providerServiceUnpublished => 'أُلغي النشر — عادت مسودة';

  @override
  String get providerServiceDraftSaved => 'حُفظت المسودة';

  @override
  String get providerServiceChangesSaved => 'حُفظت التغييرات';

  @override
  String get providerServiceDeleted => 'حُذفت الخدمة';

  @override
  String get providerServiceUnpublishTitle => 'إلغاء نشر هذه الخدمة؟';

  @override
  String get providerServiceUnpublishBody =>
      'تخرج من نتائج البحث ومن ملفك فورًا وتعود إلى مسوداتك. تبقى الحجوزات المقبولة كما هي.';

  @override
  String get providerServiceKeepPublished => 'الإبقاء عليها منشورة';

  @override
  String get providerServiceDeleteTitle => 'حذف هذه الخدمة؟';

  @override
  String get providerServiceDeleteBody =>
      'الحذف نهائي، وتُلغى الطلبات التي ما زالت تنتظر ردك عليها.';

  @override
  String get providerServiceDeleteConfirm => 'حذف';

  @override
  String get providerServiceDeleteKeep => 'الإبقاء عليها';

  @override
  String get providerServiceDeleteButton => 'حذف هذه الخدمة';

  @override
  String get providerServiceDeleteCaption =>
      'الحذف نهائي، ويُرفض ما دامت الخدمة مرتبطة بحجوزات قادمة أو مُدرجة في باقة.';

  @override
  String get providerServiceDeleteRefusedTitle => 'لا يمكن حذف هذه الخدمة بعد';

  @override
  String get providerServiceDeleteRefusedBody =>
      'الحذف محجوب ما دام هذا قائمًا. يمكنك إلغاء النشر الآن فتخرج من نتائج البحث فورًا.';

  @override
  String get providerServiceDeleteRefusedBodyPlain =>
      'الحذف محجوب ما دام هذا قائمًا.';

  @override
  String providerServiceBlockerBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'هناك $count حجز مقبول لم يحن بعد',
      many: 'هناك $count حجزًا مقبولًا لم يحن بعد',
      few: 'هناك $count حجوزات مقبولة لم تحن بعد',
      two: 'هناك حجزان مقبولان لم يحينا بعد',
      one: 'هناك حجز مقبول لم يحن بعد',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceBlockerBookingsUncounted =>
      'هناك حجوزات مقبولة لم تحن بعد';

  @override
  String providerServiceBlockerPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إنها ضمن $count من باقاتك',
      many: 'إنها ضمن $count من باقاتك',
      few: 'إنها ضمن $count من باقاتك',
      two: 'إنها ضمن باقتين من باقاتك',
      one: 'إنها ضمن إحدى باقاتك',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceBlockerPacksUncounted => 'ما زالت ضمن إحدى باقاتك';

  @override
  String get providerServiceUnpublishInstead => 'إلغاء النشر بدلًا من ذلك';

  @override
  String get providerServiceCancel => 'إلغاء';

  @override
  String get providerServiceEditTitle => 'تعديل الخدمة';

  @override
  String get providerServiceLangEnglish => 'English';

  @override
  String get providerServiceLangArabic => 'عربي';

  @override
  String providerServiceLangArabicMissing(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'both': 'ما زالت النسخة العربية تحتاج عنوانًا ووصفًا. كلاهما مطلوب قبل النشر.',
      'title': 'ما زالت النسخة العربية تحتاج عنوانًا، وهو مطلوب قبل النشر.',
      'other': 'ما زالت النسخة العربية تحتاج وصفًا، وهو مطلوب قبل النشر.',
    });
    return '$_temp0';
  }

  @override
  String providerServiceLangEnglishMissing(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'both': 'ما زالت النسخة الإنجليزية تحتاج عنوانًا ووصفًا. كلاهما مطلوب قبل النشر.',
      'title': 'ما زالت النسخة الإنجليزية تحتاج عنوانًا، وهو مطلوب قبل النشر.',
      'other': 'ما زالت النسخة الإنجليزية تحتاج وصفًا، وهو مطلوب قبل النشر.',
    });
    return '$_temp0';
  }

  @override
  String get providerServiceLangComplete =>
      'النسختان الإنجليزية والعربية مكتملتان.';

  @override
  String get providerServiceLangCompleteLive =>
      'النسختان الإنجليزية والعربية مكتملتان. هذه الخدمة منشورة، لذا تظهر التعديلات للعملاء فورًا.';

  @override
  String get providerServiceBasics => 'الأساسيات';

  @override
  String get providerServicePricing => 'التسعير';

  @override
  String get providerServiceCapacity => 'السعة';

  @override
  String get providerServiceIncluded => 'ما تشمله الخدمة';

  @override
  String get providerServiceExtras => 'الإضافات';

  @override
  String get providerServiceWilayas => 'الولايات المغطّاة';

  @override
  String get providerServicePolicy => 'سياسة الإلغاء';

  @override
  String get providerServicePhotos => 'الصور';

  @override
  String get providerServiceCategory => 'الفئة';

  @override
  String get providerServiceChoose => 'اختر';

  @override
  String providerServiceTitleLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'العنوان (بالعربية)',
      'other': 'العنوان (بالإنجليزية)',
    });
    return '$_temp0';
  }

  @override
  String providerServiceDescriptionLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'الوصف (بالعربية)',
      'other': 'الوصف (بالإنجليزية)',
    });
    return '$_temp0';
  }

  @override
  String providerServicePolicyLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'تظهر للعملاء قبل الحجز (بالعربية)',
      'other': 'تظهر للعملاء قبل الحجز (بالإنجليزية)',
    });
    return '$_temp0';
  }

  @override
  String get providerServiceBasePriceLabel => 'السعر الأساسي (دج)';

  @override
  String get providerServiceBasePriceHelper => 'السعر الابتدائي قبل أي إضافات.';

  @override
  String get providerServiceStartingPriceLabel => 'السعر الابتدائي (دج)';

  @override
  String get providerServiceStartingPriceHelper =>
      'يرى العملاء «حسب الطلب». هذا المبلغ هو ما تحتسبه الباقة لها.';

  @override
  String get providerServicePriceTypeLabel => 'نوع السعر';

  @override
  String providerServicePriceTypeOption(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'per_event': 'للمناسبة',
      'per_hour': 'للساعة',
      'per_person': 'للشخص',
      'per_day': 'لليوم',
      'other': 'حسب الطلب',
    });
    return '$_temp0';
  }

  @override
  String get providerServiceMaxEventsLabel => 'أقصى عدد مناسبات في اليوم';

  @override
  String get providerServiceMaxGuestsLabel => 'أقصى عدد ضيوف';

  @override
  String get providerServiceMaxGuestsNone => 'اتركه فارغًا إن لم يكن هناك حد';

  @override
  String providerServiceRange(int min, int max) {
    return 'بين $min و$max';
  }

  @override
  String get providerServiceFieldRequired => 'مطلوب';

  @override
  String get providerServiceAddFact => 'إضافة معلومة';

  @override
  String get providerServiceEditFact => 'تعديل معلومة';

  @override
  String get providerServiceNoFacts => 'لا شيء بعد — المدة، الفريق، التسليم…';

  @override
  String get providerServiceFactSheetBody =>
      'يقرأها العملاء بلغتهم، لذا نحتاج اللغتين.';

  @override
  String get providerServiceFactLabelEn => 'التسمية (بالإنجليزية)';

  @override
  String get providerServiceFactValueEn => 'القيمة (بالإنجليزية)';

  @override
  String get providerServiceFactLabelAr => 'التسمية (بالعربية)';

  @override
  String get providerServiceFactValueAr => 'القيمة (بالعربية)';

  @override
  String get providerServiceSheetSave => 'حفظ';

  @override
  String get providerServiceRemove => 'إزالة';

  @override
  String get providerServiceAddExtra => 'إضافة خدمة إضافية';

  @override
  String get providerServiceEditExtra => 'تعديل خدمة إضافية';

  @override
  String get providerServiceNoExtras => 'لا إضافات بعد';

  @override
  String get providerServiceExtraSheetBody =>
      'خيار مدفوع يمكن للعملاء إضافته إلى حجزهم.';

  @override
  String get providerServiceExtraNameEn => 'الاسم (بالإنجليزية)';

  @override
  String get providerServiceExtraNameAr => 'الاسم (بالعربية)';

  @override
  String get providerServiceExtraNameArHelper =>
      'إلى أن تضيفه، يرى من يقرأ بالعربية الاسم الإنجليزي.';

  @override
  String get providerServiceExtraPrice => 'السعر (دج)';

  @override
  String get providerServiceAddWilaya => '+ إضافة ولاية';

  @override
  String get providerServiceWilayaPickerBody =>
      'تظهر الولايات المفتوحة على Eventor فقط.';

  @override
  String providerServiceRemoveWilaya(String name) {
    return 'إزالة $name';
  }

  @override
  String get providerServiceNoWilayas =>
      'أضف ولاية مفتوحة واحدة على الأقل قبل النشر.';

  @override
  String providerServicePhotosAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مضافة',
      many: '$count مضافة',
      few: '$count مضافة',
      two: 'صورتان',
      one: 'صورة واحدة',
      zero: 'لا توجد بعد',
    );
    return '$_temp0';
  }

  @override
  String get providerServicePhotosNeedDraft =>
      'لإضافة الصور، حدّد أولًا الفئة والعنوان بالإنجليزية والسعر الأساسي ونوع السعر.';

  @override
  String get providerServiceDraftSavedForPhotos =>
      'حُفظت المسودة — أضف صورك الآن';

  @override
  String get providerServiceSaveDraft => 'حفظ كمسودة';

  @override
  String get providerServiceSave => 'حفظ';

  @override
  String get providerServiceSaveChanges => 'حفظ التغييرات';

  @override
  String get providerServiceFixFields => 'أكمل الحقول المحددة بالأحمر.';

  @override
  String get providerServiceNotVerifiedTitle => 'يُتاح النشر بعد الموافقة';

  @override
  String get providerServiceNotVerifiedBody =>
      'ما زالت وثائقك قيد المراجعة. مسودتك محفوظة — انشرها فور الموافقة على ملفك.';

  @override
  String get providerServiceGotIt => 'حسنًا';

  @override
  String get providerServiceChecklistTitle => 'غير جاهزة للنشر بعد';

  @override
  String get providerServiceChecklistBody =>
      'لن يرى العملاء هذه الخدمة حتى تكتمل كل النقاط أدناه. مسودتك محفوظة بالفعل.';

  @override
  String get providerServiceCheckEnglish => 'العنوان والوصف بالإنجليزية';

  @override
  String get providerServiceCheckArabic => 'العنوان والوصف بالعربية';

  @override
  String get providerServiceCheckPrice => 'سعر أساسي';

  @override
  String get providerServiceCheckPhotos => 'صورة واحدة على الأقل';

  @override
  String get providerServiceCheckCategory => 'فئة يمكن للعملاء تصفحها';

  @override
  String get providerServiceCheckWilayas => 'ولاية مفتوحة واحدة على الأقل';

  @override
  String get providerServiceCheckDone => 'مكتمل';

  @override
  String get providerServiceCheckMissing => 'ناقص';

  @override
  String get providerServiceFixEnglish => 'أضف النص الإنجليزي';

  @override
  String get providerServiceFixArabic => 'أضف النص العربي';

  @override
  String get providerServiceFixPrice => 'أضف سعرًا';

  @override
  String get providerServiceFixPhotos => 'أضف صورًا';

  @override
  String get providerServiceFixCategory => 'اختر فئة';

  @override
  String get providerServiceFixWilayas => 'أضف ولاية';

  @override
  String get providerServiceKeepDraft => 'الإبقاء كمسودة';

  @override
  String get providerServicePhotosHelper =>
      'الصورة الأولى هي الغلاف الذي يراه العملاء. اضغط على صورة لجعلها الغلاف أو نقلها أو إزالتها.';

  @override
  String get providerPackPhotosHelper =>
      'الصورة الأولى هي الغلاف الذي يظهر في نتائج البحث. اضغط على صورة لجعلها الغلاف أو نقلها أو إزالتها.';

  @override
  String providerServicePhotosCounter(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count من $max صورة',
      few: '$count من $max صور',
    );
    return '$_temp0';
  }

  @override
  String get providerServicePhotoCover => 'الغلاف';

  @override
  String get providerServicePhotoProcessing => 'قيد المعالجة';

  @override
  String get providerServicePhotoFailed => 'تعذّرت المعالجة';

  @override
  String get providerServicePhotoUploading => 'جارٍ الرفع';

  @override
  String get providerServicePhotoUploadFailed => 'لم تُرسل';

  @override
  String get providerServicePhotoRetry => 'إعادة';

  @override
  String get providerServiceAddPhoto => 'إضافة صورة';

  @override
  String providerServicePhotosFull(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'هذا أقصى ما يتسع له المعرض — $max صورة. أزل صورة لإضافة أخرى.',
      few: 'هذا أقصى ما يتسع له المعرض — $max صور. أزل صورة لإضافة أخرى.',
    );
    return '$_temp0';
  }

  @override
  String get providerServicePhotosEmpty =>
      'لا صور بعد — أول صورة تضيفها تصبح الغلاف.';

  @override
  String get providerServicePhotoActionsTitle => 'هذه الصورة';

  @override
  String get providerServicePhotoMakeCover => 'اجعلها الغلاف';

  @override
  String get providerServicePhotoMoveEarlier => 'انقلها إلى الأمام';

  @override
  String get providerServicePhotoMoveLater => 'انقلها إلى الخلف';

  @override
  String get providerServicePhotoRemoveTitle => 'إزالة هذه الصورة؟';

  @override
  String get providerServicePhotoRemoveBody => 'ستُحذف من المعرض نهائيًا.';

  @override
  String get providerServicePhotoLastRefused =>
      'الخدمة المنشورة تحتاج صورة واحدة على الأقل. ألغِ نشرها أولًا لإزالة الأخيرة.';

  @override
  String providerServicePhotoLabel(int index) {
    return 'الصورة $index';
  }

  @override
  String get providerPackEmptyTitle => 'لا توجد باقات بعد';

  @override
  String get providerPackEmptyBody =>
      'الباقة تجمع خدمتين منشورتين أو أكثر بسعر أقل من مجموعها — للعملاء الذين يخططون لمناسبة كاملة.';

  @override
  String providerPackEmptyNeedsServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الباقة تجمع خدمتين منشورتين أو أكثر بسعر أقل من مجموعها.',
      one: 'الباقة تجمع خدمتين منشورتين أو أكثر بسعر أقل من مجموعها. لديك خدمة منشورة واحدة، فلا يوجد ما يُجمع بعد.',
      zero: 'الباقة تجمع خدمتين منشورتين أو أكثر بسعر أقل من مجموعها. ليس لديك خدمة منشورة بعد، فلا يوجد ما يُجمع.',
    );
    return '$_temp0';
  }

  @override
  String get providerPackCreate => 'إنشاء باقة';

  @override
  String get providerPackPublishAnother => 'انشر خدمة أخرى';

  @override
  String get providerPackStatusUnpublished => 'غير منشورة';

  @override
  String providerPackServicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      many: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get providerPackSaves => 'يوفّر';

  @override
  String get providerPackSumOfItems => 'مجموع العناصر';

  @override
  String providerPackAttentionItem(String service) {
    return 'تحتاج انتباهك — لم تعد «$service» منشورة، لذا لا يستطيع العملاء حجز هذه الباقة';
  }

  @override
  String get providerPackAttentionDeleted =>
      'تحتاج انتباهك — حُذفت خدمة منها، لذا لا يستطيع العملاء حجز هذه الباقة';

  @override
  String get providerPackAttentionProfile =>
      'تحتاج انتباهك — لا يستطيع العملاء حجزها ما دام ملفك غير معتمد';

  @override
  String get providerPackPriceRule =>
      'يجب أن يكون سعر الباقة أقل من مجموع خدماتها قبل النشر';

  @override
  String get providerPackUnpublishTitle => 'إلغاء نشر هذه الباقة؟';

  @override
  String get providerPackUnpublishBody =>
      'لن يجدها العملاء ولن يحجزوها بعد الآن. تبقى الحجوزات المقبولة كما هي.';

  @override
  String get providerPackPublished => 'نُشرت الباقة — يمكن للعملاء حجزها الآن';

  @override
  String get providerPackUnpublished => 'أُلغي نشر الباقة';

  @override
  String get providerPackDeleted => 'حُذفت الباقة';

  @override
  String get providerPackCreateTitle => 'إنشاء باقة';

  @override
  String get providerPackEditTitle => 'تعديل الباقة';

  @override
  String get providerPackLangArabicMissing =>
      'ما زال الاسم بالعربية ناقصًا، وهو مطلوب قبل النشر.';

  @override
  String get providerPackLangEnglishMissing =>
      'ما زال الاسم بالإنجليزية ناقصًا، وهو مطلوب للحفظ.';

  @override
  String get providerPackLangCompleteLive =>
      'النسختان الإنجليزية والعربية مكتملتان. هذه الباقة منشورة، لذا تظهر التعديلات للعملاء فورًا.';

  @override
  String providerPackNameLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'اسم الباقة (بالعربية)',
      'other': 'اسم الباقة (بالإنجليزية)',
    });
    return '$_temp0';
  }

  @override
  String get providerPackServicesSection => 'خدمات هذه الباقة';

  @override
  String get providerPackEditServices => 'إضافة خدمات أو إزالتها';

  @override
  String get providerPackNoServices =>
      'اختر من خدمتين إلى ست من خدماتك المنشورة.';

  @override
  String providerPackSumCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مجموع الخدمات الـ$count',
      many: 'مجموع الخدمات الـ$count',
      few: 'مجموع الخدمات الـ$count',
      two: 'مجموع الخدمتين',
      one: 'مجموع الخدمة',
    );
    return '$_temp0';
  }

  @override
  String providerPackItemNotCovering(String wilaya) {
    return 'لا تغطي $wilaya';
  }

  @override
  String get providerPackItemDraft => 'غير منشورة — لا يمكن للعملاء حجز الباقة';

  @override
  String get providerPackItemHidden =>
      'أخفتها Eventor — لا يمكن للعملاء حجز الباقة';

  @override
  String get providerPackPriceLabel => 'سعر الباقة (دج)';

  @override
  String get providerPackPriceHelper => 'يجب أن يكون أقل من مجموع العناصر.';

  @override
  String get providerPackPriceNotBelow =>
      'هذا ليس أقل من مجموع العناصر — سيدفع العملاء مثل حجزها منفردة أو أكثر.';

  @override
  String get providerPackClientsSave => 'يوفّر العملاء';

  @override
  String providerPackSavingPercent(int percent) {
    return '· $percent٪';
  }

  @override
  String get providerPackEventPlace => 'المناسبة والمكان';

  @override
  String get providerPackEventType => 'نوع المناسبة';

  @override
  String get providerPackWilaya => 'الولاية';

  @override
  String get providerPackWilayaPickerBody => 'يجب أن تغطيها كل خدمات الباقة.';

  @override
  String providerPackWilayaCovering(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تغطيها $count خدمة',
      many: 'تغطيها $count خدمة',
      few: 'تغطيها $count خدمات',
      two: 'تغطيها خدمتان',
      one: 'تغطيها خدمة واحدة',
      zero: 'لا تغطيها أي خدمة',
    );
    return '$_temp0';
  }

  @override
  String get providerPackPhotosTitle => 'صور الباقة';

  @override
  String get providerPackDeleteButton => 'حذف هذه الباقة';

  @override
  String get providerPackDeleteCaption =>
      'الحذف نهائي ويُرفض ما دامت الباقة مرتبطة بحجوزات قادمة. لا تتأثر الخدمات التي بداخلها.';

  @override
  String get providerPackDeleteTitle => 'حذف هذه الباقة؟';

  @override
  String get providerPackDeleteBody =>
      'الحذف نهائي، ولا تتأثر الخدمات التي بداخلها.';

  @override
  String get providerPackDeleteRefusedTitle => 'لا يمكن حذف هذه الباقة بعد';

  @override
  String get providerPackServicesRange => 'اختر من خدمتين إلى ست خدمات.';

  @override
  String get providerPackPhotosNeedDraft =>
      'لإضافة الصور، حدّد أولًا اسم الباقة بالإنجليزية ومن خدمتين إلى ست خدمات والسعر ونوع المناسبة والولاية.';

  @override
  String get providerPackChecklistBody =>
      'لن يرى العملاء هذه الباقة حتى تكتمل كل النقاط أدناه. مسودتك محفوظة بالفعل.';

  @override
  String get providerPackCheckEnglish => 'الاسم بالإنجليزية';

  @override
  String get providerPackCheckArabic => 'الاسم بالعربية';

  @override
  String get providerPackCheckServices => 'خدمتان منشورتان على الأقل';

  @override
  String get providerPackCheckPrice => 'سعر أقل من مجموع العناصر';

  @override
  String get providerPackCheckWilaya => 'ولاية تغطيها كل الخدمات';

  @override
  String get providerPackCheckProfile => 'ملف معتمد';

  @override
  String providerPackFixThese(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أصلح هذه الأمور',
      many: 'أصلح هذه الأمور',
      few: 'أصلح هذه الأمور',
      two: 'أصلح هذين الأمرين',
      one: 'أصلح هذا الأمر',
    );
    return '$_temp0';
  }

  @override
  String get providerPackChooseTitle => 'اختر الخدمات';

  @override
  String get providerPackChooseRule =>
      'اختر من خدمتين إلى ست من خدماتك المنشورة. لا يمكن إدراج المسودات أو الخدمات المخفية في باقة.';

  @override
  String providerPackChosenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مختارة',
      many: '$count مختارة',
      few: '$count مختارة',
      two: 'خدمتان مختارتان',
      one: 'خدمة واحدة مختارة',
      zero: 'لا شيء مختار',
    );
    return '$_temp0';
  }

  @override
  String get providerPackChosenSum => 'المجموع';

  @override
  String providerPackChooseDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم · $count مختارة',
      many: 'تم · $count مختارة',
      few: 'تم · $count مختارة',
      two: 'تم · خدمتان',
      one: 'تم · خدمة واحدة',
      zero: 'تم',
    );
    return '$_temp0';
  }

  @override
  String get providerPackReasonDraft => 'مسودة — لا يمكن إدراجها في باقة';

  @override
  String get providerPackReasonHidden => 'مخفية — لا يمكن إدراجها في باقة';

  @override
  String get providerPackReasonNotCoveringAny => 'لا تغطي ولاية الباقة';

  @override
  String get providerPackChooseFull => 'تضم الباقة ست خدمات على الأكثر.';

  @override
  String get providerPackChooseMin => 'اختر خدمتين على الأقل.';

  @override
  String get providerPackChooseEmpty => 'ليس لديك خدمات بعد.';
}
