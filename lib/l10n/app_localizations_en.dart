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
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to pick up where you left off.';

  @override
  String get forgotPassword => 'Forgot password ?';

  @override
  String get loginNewPrompt => 'New to Eventor ?';

  @override
  String get homeTitle => 'Home';

  @override
  String get splashTagline => 'Everything your event needs, in one place';

  @override
  String get splashByline => 'by SYMLOOP';

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
  String get rolePlannerTitle => 'I\'m planning an event';

  @override
  String get rolePlannerDescription => 'Find and book my event team';

  @override
  String get roleProviderTitle => 'I offer a service';

  @override
  String get roleProviderDescription => 'List my services and manage bookings';

  @override
  String get roleInstitutionTitle => 'I represent an institution';

  @override
  String get roleInstitutionDescription => 'Submit and track event requests';

  @override
  String get continueAction => 'Continue';

  @override
  String get backLabel => 'Back';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Just a few details, then you can start booking your event team.';

  @override
  String get registerSubtitleProvider =>
      'A few details and your documents, then you can list your services.';

  @override
  String get registerSubtitleInstitution =>
      'A few details and your documents, then you can submit event requests.';

  @override
  String get registerDocumentsTitle => 'Verification documents';

  @override
  String get registerDocumentsProviderNote =>
      'We review these before your services go live.';

  @override
  String get registerDocumentsInstitutionNote =>
      'We review these before your first request is approved.';

  @override
  String get registerCreateAccount => 'Create account';

  @override
  String get registerSuccess => 'Account creation successful';

  @override
  String get registerTermsPrefix => 'By continuing you agree to our ';

  @override
  String get registerTermsLink => 'Terms and Privacy Policy';

  @override
  String get registerHasAccountPrompt => 'Already have an account ?';

  @override
  String get logIn => 'Log in';

  @override
  String get nameLabel => 'Full name';

  @override
  String get phoneLabel => 'Phone';

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
  String get phoneRequired => 'Enter your phone number.';

  @override
  String phoneInvalid(int count, String leadingDigit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enter $count digits, starting with $leadingDigit.',
      one: 'Enter $count digit, starting with $leadingDigit.',
    );
    return '$_temp0';
  }

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the email on your account and we will send you a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToLogIn => 'Back to log in';

  @override
  String get verifyCodeTitle => 'Verify your number';

  @override
  String verifyCodeSubtitle(String destination) {
    return 'We sent a 6-digit code to $destination.';
  }

  @override
  String get verifyCodeDestinationFallback => 'your number';

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verifyAction => 'Verify';

  @override
  String get verifyNoCodePrompt => 'Didn\'t get the code ?';

  @override
  String verifyResendCountdown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can resend after $count seconds.',
      one: 'You can resend after $count second.',
    );
    return '$_temp0';
  }

  @override
  String get resend => 'Resend';

  @override
  String get verifyCodeResent => 'A new code is on its way';

  @override
  String get languageSwitchLabel => 'Language';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String sectionProgress(int current, int total) {
    return 'Section $current of $total';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get institutionLabel => 'Institution';

  @override
  String institutionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count characters, as it appears on your accreditation.',
      one: 'At least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get institutionRequired => 'Enter the institution you represent.';

  @override
  String institutionTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use at least $count characters.',
      one: 'Use at least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get documentUploadAction => 'Upload file';

  @override
  String get documentMissing => 'Attach this document.';

  @override
  String get documentReplace => 'Choose a different file';

  @override
  String get documentRemove => 'Remove file';

  @override
  String documentTooLarge(int count) {
    return 'This file is over $count MB. Attach a smaller one.';
  }

  @override
  String get documentWrongType => 'Attach a PDF or an image.';

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
  String get documentAccreditation => 'Accreditation';

  @override
  String get documentAccreditationHint =>
      'The agrément issued to your association or club';

  @override
  String get documentAuthorisationLetter => 'Letter of authorisation';

  @override
  String get documentAuthorisationLetterHint =>
      'Signed proof that you represent the institution';

  @override
  String get documentAssociationStatutes => 'Association statutes (optional)';

  @override
  String get documentAssociationStatutesHint =>
      'Required for associations and clubs';

  @override
  String nameHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count letters, no digits or symbols.',
      one: 'At least $count letter, no digits or symbols.',
    );
    return '$_temp0';
  }

  @override
  String phoneHint(int count, String leadingDigit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count digits, starting with $leadingDigit.',
      one: '$count digit, starting with $leadingDigit.',
    );
    return '$_temp0';
  }

  @override
  String get namePlaceholder => 'Amina Benali';

  @override
  String get institutionPlaceholder => 'Université d\'Alger 1';

  @override
  String get emailPlaceholder => 'name@example.com';

  @override
  String get phonePlaceholder => '0X XX XX XX XX';

  @override
  String get emailHint => 'No spaces, and one @.';

  @override
  String passwordHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count characters, no spaces.',
      one: 'At least $count character, no spaces.',
    );
    return '$_temp0';
  }

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid =>
      'Enter a valid email address, like name@example.com.';

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
  String get unknownRouteTitle => 'Page not found';

  @override
  String unknownRouteMessage(String routeName) {
    return 'No route defined for \"$routeName\".';
  }

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorStorage => 'Could not save your changes on this device.';
}
