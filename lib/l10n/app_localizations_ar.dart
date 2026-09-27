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
  String get tabComingSoonTitle => 'قريبًا';

  @override
  String get tabComingSoonBody => 'هذا القسم من Eventor قيد التحضير.';

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
}
