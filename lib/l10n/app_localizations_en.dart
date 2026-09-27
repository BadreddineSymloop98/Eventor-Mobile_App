// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Eventor';

  @override
  String get backLabel => 'Back';

  @override
  String get languageSwitchLabel => 'Language';

  @override
  String get continueAction => 'Continue';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get unknownRouteTitle => 'Page not found';

  @override
  String unknownRouteMessage(String routeName) {
    return 'No route defined for \"$routeName\".';
  }

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorStorage => 'Could not save your changes on this device.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has ended. Log in again to continue.';

  @override
  String get sessionExpiredTitle => 'Your session has ended';

  @override
  String get sessionExpiredBody =>
      'Log in again to continue where you left off.';

  @override
  String get splashTagline => 'Everything your event needs, in one place';

  @override
  String get splashByline => 'by SYMLOOP';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String sectionProgress(int current, int total) {
    return 'Section $current of $total';
  }

  @override
  String get onboardingServicesTitle => 'Every service your event needs';

  @override
  String get onboardingServicesDescription =>
      'Photographers, venues, caterers, DJs, florists and decorators, all in one place.';

  @override
  String get onboardingCompareTitle => 'Compare, then book with confidence';

  @override
  String get onboardingCompareDescription =>
      'Real reviews, clear prices and open dates. Message a provider before you commit.';

  @override
  String get onboardingTrackTitle => 'Keep the whole event on track';

  @override
  String get onboardingTrackDescription =>
      'Follow every booking and watch your budget as the day comes together.';

  @override
  String get welcomeTitle => 'Let’s get started';

  @override
  String get welcomeSubtitle =>
      'Create an account to start booking or log in if you have been here before.';

  @override
  String get createAccount => 'Create an account';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get roleSelectionTitle => 'How will you use Eventor ?';

  @override
  String get roleSelectionSubtitle =>
      'This shapes your whole experience in the app. It cannot be changed later.';

  @override
  String get roleClientTitle => 'I\'m planning an event';

  @override
  String get roleClientDescription => 'Find and book my event team';

  @override
  String get roleProviderTitle => 'I offer a service';

  @override
  String get roleProviderDescription => 'List my services and manage bookings';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Just a few details, then you can start booking your event team.';

  @override
  String get registerSubtitleProvider =>
      'Tell us about you and your business. You\'ll add your documents next.';

  @override
  String get registerBusinessTitle => 'Your business';

  @override
  String get registerBusinessNote => 'Shown to clients on your profile.';

  @override
  String get registerCreateAccount => 'Create account';

  @override
  String get registerTermsPrefix => 'By continuing you agree to our ';

  @override
  String get registerTermsLink => 'Terms and Privacy Policy';

  @override
  String get registerTermsSuffix => '.';

  @override
  String get registerHasAccountPrompt => 'Already have an account ?';

  @override
  String get registerEmailTakenTitle => 'This email already has an account';

  @override
  String get registerEmailTakenBody =>
      'Log in instead, or sign up with a different address.';

  @override
  String get logIn => 'Log in';

  @override
  String get nameLabel => 'Full name';

  @override
  String get namePlaceholder => 'Amina Benali';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailPlaceholder => 'name@example.com';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phonePlaceholder => '0555 12 34 56';

  @override
  String get phoneHint => '10 digits starting with 0, or +213.';

  @override
  String get passwordLabel => 'Password';

  @override
  String passwordHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count characters, with a letter and a digit.',
      one: 'At least $count character, with a letter and a digit.',
    );
    return '$_temp0';
  }

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get businessNameLabel => 'Business name';

  @override
  String get businessNamePlaceholder => 'Studio Lumière';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryPlaceholder => 'Choose a category';

  @override
  String get categorySheetTitle => 'Choose your category';

  @override
  String get wilayaOptionalLabel => 'Wilaya (optional)';

  @override
  String get wilayaPlaceholder => 'Choose a wilaya';

  @override
  String get wilayaSheetTitle => 'Choose your wilaya';

  @override
  String get wilayaSearchHint => 'Find a wilaya';

  @override
  String get wilayasServedLabel => 'Wilayas served';

  @override
  String get wilayasServedPlaceholder => 'Choose where you work';

  @override
  String get wilayasServedSheetTitle => 'Where do you work ?';

  @override
  String get referenceLoadFailed =>
      'Could not load the list. Tap to try again.';

  @override
  String get nameRequired => 'Enter your full name.';

  @override
  String nameTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use at least $count characters.',
      one: 'Use at least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get businessNameRequired => 'Enter your business name.';

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid =>
      'Enter a valid email address, like name@example.com.';

  @override
  String get emailTaken => 'This email already has an account.';

  @override
  String get phoneRequired => 'Enter your phone number.';

  @override
  String get phoneInvalid =>
      'Enter 10 digits starting with 0, or a +213 number.';

  @override
  String get phoneTaken => 'This phone number already has an account.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String passwordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use at least $count characters.',
      one: 'Use at least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get passwordNeedsLetterAndDigit =>
      'Use at least one letter and one digit.';

  @override
  String get passwordWeak =>
      'This password is too easy to guess. Choose another.';

  @override
  String get passwordMismatch => 'The two passwords do not match.';

  @override
  String get categoryRequired => 'Choose your category.';

  @override
  String get wilayasRequired => 'Choose at least one wilaya.';

  @override
  String get verifyEmailTitle => 'Confirm your email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Enter the code we sent to $email to activate your account.';
  }

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verifyAction => 'Verify';

  @override
  String get verifyNoCodePrompt => 'Didn\'t get the code ?';

  @override
  String get resend => 'Resend';

  @override
  String resendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get verifyCodeResent => 'A new code is on its way';

  @override
  String get codeInvalidTitle => 'That code is not right';

  @override
  String get codeInvalidBody => 'Check the six digits and try again.';

  @override
  String mockCodeHint(String code) {
    return 'Mock mode — the code is always $code.';
  }

  @override
  String get codeExpiredTitle => 'That code has expired';

  @override
  String get codeExpiredBody =>
      'Codes last 15 minutes. Ask for a new one and we will send it straight away.';

  @override
  String get documentsTitle => 'Verify your business';

  @override
  String get documentsSubtitle =>
      'Upload these three documents. We review them in one to two days.';

  @override
  String get documentsSectionTitle => 'Verification documents';

  @override
  String get documentsSectionNote =>
      'We review these before your services go live.';

  @override
  String get documentsSubmit => 'Submit for review';

  @override
  String get documentsLater => 'I\'ll do it later';

  @override
  String get documentsSubmitted =>
      'Documents sent. We review them in one to two days.';

  @override
  String get documentUploadAction => 'Upload file';

  @override
  String get documentUploading => 'Uploading…';

  @override
  String get documentUploaded => 'Received';

  @override
  String get documentUnderReview => 'Under review';

  @override
  String get documentApproved => 'Approved';

  @override
  String get documentReplace => 'Choose a different file';

  @override
  String get documentRemove => 'Remove file';

  @override
  String get documentMissing => 'Attach this document.';

  @override
  String documentTooLarge(int count) {
    return 'This file is over $count MB. Attach a smaller one.';
  }

  @override
  String get documentWrongType => 'Attach a PDF or an image.';

  @override
  String get documentUploadFailed => 'Upload failed. Tap to try again.';

  @override
  String get documentIdentityCard => 'National ID card';

  @override
  String get documentIdentityCardHint => 'Front and back, in one file';

  @override
  String get documentCommercialRegister =>
      'Commercial register or artisan card';

  @override
  String get documentCommercialRegisterHint =>
      'Whichever body you are registered with';

  @override
  String get documentTaxRegistration => 'Tax registration card (NIF)';

  @override
  String get documentTaxRegistrationHint =>
      'Shows your fiscal identification number';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to pick up where you left off.';

  @override
  String get forgotPassword => 'Forgot password ?';

  @override
  String get loginNewPrompt => 'New to Eventor ?';

  @override
  String get loginWrongTitle => 'Email or password is incorrect';

  @override
  String get loginWrongBody =>
      'Check the address and try again — passwords are case sensitive.';

  @override
  String get loginUnverifiedTitle => 'Confirm your email first';

  @override
  String loginUnverifiedBody(String email) {
    return 'We sent a 6-digit code to $email when you signed up. It is still waiting.';
  }

  @override
  String get loginSendNewCode => 'Send a new code';

  @override
  String get loginLockedTitle => 'Too many failed attempts';

  @override
  String loginLockedBody(String time) {
    return 'This account is locked for a while to keep it safe. You can try again at $time, or reset your password now.';
  }

  @override
  String loginTryAgainAt(String time) {
    return 'Try again at $time';
  }

  @override
  String get loginBlockedTitle => 'This account is blocked';

  @override
  String get loginNotAllowedTitle => 'This account can\'t use the app';

  @override
  String get passwordResetDone =>
      'Password updated. Log in with your new password.';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the email on your account and we will send you a 6-digit code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get backToLogIn => 'Back to log in';

  @override
  String get resetCodeTitle => 'Check your email';

  @override
  String resetCodeSubtitle(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get resetPasswordSubtitle =>
      'Your new password must be different from the one you used before.';

  @override
  String get resetPasswordAction => 'Reset password';

  @override
  String get setPasswordTitle => 'Set your password';

  @override
  String get setPasswordSubtitle =>
      'Your Eventor account is ready. Choose a password and you are signed in.';

  @override
  String get setPasswordAction => 'Set password and sign in';

  @override
  String get needHelpContactSupport => 'Need help ? Contact support';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get inviteExpiredTitle => 'This invite link has expired';

  @override
  String get inviteExpiredBody =>
      'Invite links last 7 days and can only be used once. Ask us for a fresh one and it will arrive in a moment.';

  @override
  String get inviteInvalidTitle => 'This invite link does not work';

  @override
  String get inviteInvalidBody =>
      'Open the link from your invitation email again, or ask us for a new one.';

  @override
  String get supportEmailSubject => 'Help with my Eventor account';

  @override
  String get homeTitle => 'Home';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeComingSoon =>
      'Your home screen is being built. You are signed in.';

  @override
  String get homeProviderPendingTitle => 'Your profile is under review';

  @override
  String get homeProviderPendingBody =>
      'You can browse the app. Services go live once your documents are approved.';

  @override
  String get homeProviderRejectedTitle => 'Some documents need your attention';

  @override
  String get homeUploadDocuments => 'Upload documents';

  @override
  String get logOut => 'Log out';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get availabilityAvailable => 'Available';

  @override
  String get availabilityUnavailable => 'Unavailable';

  @override
  String ratingLabel(String score) {
    return 'Rated $score out of 5';
  }

  @override
  String ratingWithCountLabel(String score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rated $score out of 5 from $count reviews',
      one: 'Rated $score out of 5 from $count review',
    );
    return '$_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count reviews)',
      one: '($count review)',
    );
    return '$_temp0';
  }

  @override
  String get priceFrom => 'From';

  @override
  String get requestAccept => 'Accept';

  @override
  String get requestDecline => 'Decline';

  @override
  String get searchHint => 'Search';

  @override
  String get selectionNoMatch => 'Nothing matches that search.';

  @override
  String get selectionDone => 'Done';

  @override
  String selectionDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done · $count selected',
      one: 'Done · $count selected',
    );
    return '$_temp0';
  }

  @override
  String get currencyDzd => 'DA';

  @override
  String get ratingNew => 'New';

  @override
  String get navProfile => 'Profile';
}
