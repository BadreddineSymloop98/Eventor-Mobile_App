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
  String get loginTitle => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لتكمل من حيث توقّفت.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور ؟';

  @override
  String get loginNewPrompt => 'جديد على Eventor ؟';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get splashTagline => 'كل ما تحتاجه مناسبتك في مكان واحد';

  @override
  String get splashByline => 'من SYMLOOP';

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
  String get rolePlannerTitle => 'أخطّط لمناسبة';

  @override
  String get rolePlannerDescription => 'أجد فريق مناسبتي وأحجزه';

  @override
  String get roleProviderTitle => 'أقدّم خدمة';

  @override
  String get roleProviderDescription => 'أعرض خدماتي وأدير الحجوزات';

  @override
  String get roleInstitutionTitle => 'أمثّل مؤسسة';

  @override
  String get roleInstitutionDescription => 'أقدّم طلبات المناسبات وأتابعها';

  @override
  String get continueAction => 'متابعة';

  @override
  String get backLabel => 'رجوع';

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle =>
      'بعض المعلومات فقط، ثم يمكنك البدء بحجز فريق مناسبتك.';

  @override
  String get registerSubtitleProvider =>
      'بعض المعلومات ووثائقك، ثم يمكنك عرض خدماتك.';

  @override
  String get registerSubtitleInstitution =>
      'بعض المعلومات ووثائقك، ثم يمكنك تقديم طلبات المناسبات.';

  @override
  String get registerDocumentsTitle => 'وثائق التحقق';

  @override
  String get registerDocumentsProviderNote => 'نراجعها قبل نشر خدماتك.';

  @override
  String get registerDocumentsInstitutionNote =>
      'نراجعها قبل الموافقة على أول طلب لك.';

  @override
  String get registerCreateAccount => 'إنشاء الحساب';

  @override
  String get registerSuccess => 'تم إنشاء الحساب بنجاح';

  @override
  String get registerTermsPrefix => 'بالمتابعة، أنت توافق على ';

  @override
  String get registerTermsLink => 'الشروط وسياسة الخصوصية';

  @override
  String get registerHasAccountPrompt => 'لديك حساب بالفعل ؟';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get nameLabel => 'الاسم الكامل';

  @override
  String get phoneLabel => 'رقم الهاتف';

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
  String get phoneRequired => 'أدخل رقم هاتفك.';

  @override
  String phoneInvalid(int count, String leadingDigit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أدخل $count رقم يبدأ بـ $leadingDigit.',
      many: 'أدخل $count رقمًا تبدأ بـ $leadingDigit.',
      few: 'أدخل $count أرقام تبدأ بـ $leadingDigit.',
      two: 'أدخل رقمين يبدآن بـ $leadingDigit.',
      one: 'أدخل رقمًا واحدًا يبدأ بـ $leadingDigit.',
      zero: 'أدخل رقم هاتفك.',
    );
    return '$_temp0';
  }

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل البريد الإلكتروني المرتبط بحسابك وسنرسل لك رابط إعادة التعيين.';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get backToLogIn => 'العودة إلى تسجيل الدخول';

  @override
  String get verifyCodeTitle => 'تحقّق من رقم هاتفك';

  @override
  String verifyCodeSubtitle(String destination) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $destination';
  }

  @override
  String get verifyCodeDestinationFallback => 'رقمك';

  @override
  String get verificationCodeLabel => 'رمز التحقق';

  @override
  String get verifyAction => 'تأكيد';

  @override
  String get verifyNoCodePrompt => 'لم يصلك الرمز ؟';

  @override
  String verifyResendCountdown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يمكنك إعادة الإرسال بعد $count ثانية.',
      many: 'يمكنك إعادة الإرسال بعد $count ثانية.',
      few: 'يمكنك إعادة الإرسال بعد $count ثوانٍ.',
      two: 'يمكنك إعادة الإرسال بعد ثانيتين.',
      one: 'يمكنك إعادة الإرسال بعد ثانية واحدة.',
      zero: 'يمكنك إعادة الإرسال الآن.',
    );
    return '$_temp0';
  }

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String get verifyCodeResent => 'تم إرسال رمز جديد';

  @override
  String get languageSwitchLabel => 'اللغة';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String sectionProgress(int current, int total) {
    return 'القسم $current من $total';
  }

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get institutionLabel => 'المؤسسة';

  @override
  String institutionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرف على الأقل، كما يظهر في اعتمادك.',
      many: '$count حرفًا على الأقل، كما يظهر في اعتمادك.',
      few: '$count أحرف على الأقل، كما يظهر في اعتمادك.',
      two: 'حرفان على الأقل، كما يظهر في اعتمادك.',
      one: 'حرف واحد على الأقل، كما يظهر في اعتمادك.',
      zero: 'كما يظهر في اعتمادك.',
    );
    return '$_temp0';
  }

  @override
  String get institutionRequired => 'أدخل اسم المؤسسة التي تمثّلها.';

  @override
  String institutionTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استخدم $count حرف على الأقل.',
      many: 'استخدم $count حرفًا على الأقل.',
      few: 'استخدم $count أحرف على الأقل.',
      two: 'استخدم حرفين على الأقل.',
      one: 'استخدم حرفًا واحدًا على الأقل.',
      zero: 'أدخل اسم المؤسسة.',
    );
    return '$_temp0';
  }

  @override
  String get documentUploadAction => 'إرفاق ملف';

  @override
  String get documentMissing => 'أرفق هذه الوثيقة.';

  @override
  String get documentReplace => 'اختيار ملف آخر';

  @override
  String get documentRemove => 'إزالة الملف';

  @override
  String documentTooLarge(int count) {
    return 'هذا الملف يتجاوز $count ميغابايت. أرفق ملفًا أصغر.';
  }

  @override
  String get documentWrongType => 'أرفق ملف PDF أو صورة.';

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
  String get documentAccreditation => 'الاعتماد';

  @override
  String get documentAccreditationHint => 'الاعتماد الممنوح لجمعيتك أو ناديك';

  @override
  String get documentAuthorisationLetter => 'تفويض بالتمثيل';

  @override
  String get documentAuthorisationLetterHint =>
      'إثبات موقّع بأنك تمثّل المؤسسة';

  @override
  String get documentAssociationStatutes => 'القانون الأساسي (اختياري)';

  @override
  String get documentAssociationStatutesHint => 'مطلوب للجمعيات والنوادي';

  @override
  String nameHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرف على الأقل، بدون أرقام أو رموز.',
      many: '$count حرفًا على الأقل، بدون أرقام أو رموز.',
      few: '$count أحرف على الأقل، بدون أرقام أو رموز.',
      two: 'حرفان على الأقل، بدون أرقام أو رموز.',
      one: 'حرف واحد على الأقل، بدون أرقام أو رموز.',
      zero: 'بدون أرقام أو رموز.',
    );
    return '$_temp0';
  }

  @override
  String phoneHint(int count, String leadingDigit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رقم يبدأ بـ $leadingDigit.',
      many: '$count رقمًا تبدأ بـ $leadingDigit.',
      few: '$count أرقام تبدأ بـ $leadingDigit.',
      two: 'رقمان يبدآن بـ $leadingDigit.',
      one: 'رقم واحد يبدأ بـ $leadingDigit.',
      zero: 'أرقام تبدأ بـ $leadingDigit.',
    );
    return '$_temp0';
  }

  @override
  String get namePlaceholder => 'أمينة بن علي';

  @override
  String get institutionPlaceholder => 'جامعة الجزائر 1';

  @override
  String get emailPlaceholder => 'name@example.com';

  @override
  String get phonePlaceholder => '0X XX XX XX XX';

  @override
  String get emailHint => 'بدون مسافات، وعلامة @ واحدة.';

  @override
  String passwordHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرف على الأقل، بدون مسافات.',
      many: '$count حرفًا على الأقل، بدون مسافات.',
      few: '$count أحرف على الأقل، بدون مسافات.',
      two: 'حرفان على الأقل، بدون مسافات.',
      one: 'حرف واحد على الأقل، بدون مسافات.',
      zero: 'بدون مسافات.',
    );
    return '$_temp0';
  }

  @override
  String get emailRequired => 'أدخل بريدك الإلكتروني.';

  @override
  String get emailInvalid =>
      'أدخل بريدًا إلكترونيًا صالحًا، مثل name@example.com.';

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
  String get unknownRouteTitle => 'الصفحة غير موجودة';

  @override
  String unknownRouteMessage(String routeName) {
    return 'لا يوجد مسار معرّف لـ \"$routeName\".';
  }

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  String get errorStorage => 'تعذّر حفظ التغييرات على هذا الجهاز.';
}
