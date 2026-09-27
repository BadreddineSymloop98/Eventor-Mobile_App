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

  /// The name of the app, shown in the task switcher and in app bars.
  ///
  /// In en, this message translates to:
  /// **'Eventor'**
  String get appName;

  /// Screen-reader label for the back chevron.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// Screen-reader label for the EN / عربي switch.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitchLabel;

  /// Generic continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Screen-reader label for the eye toggle when the password is hidden.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Screen-reader label for the eye toggle when the password is shown.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Title of the fallback screen for an unknown route.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get unknownRouteTitle;

  /// Body of the fallback screen for an unknown route.
  ///
  /// In en, this message translates to:
  /// **'No route defined for \"{routeName}\".'**
  String unknownRouteMessage(String routeName);

  /// Generic fallback error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// Writing to on-device storage failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes on this device.'**
  String get errorStorage;

  /// The request got no answer: offline, timeout.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// Shown when an action fails because the session could not be renewed.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Log in again to continue.'**
  String get errorSessionExpired;

  /// Info banner title on Login after a session died mid-use.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended'**
  String get sessionExpiredTitle;

  /// Info banner body on Login after a session died mid-use.
  ///
  /// In en, this message translates to:
  /// **'Log in again to continue where you left off.'**
  String get sessionExpiredBody;

  /// Tagline under the logo on the splash.
  ///
  /// In en, this message translates to:
  /// **'Everything your event needs, in one place'**
  String get splashTagline;

  /// Studio credit at the bottom of the splash.
  ///
  /// In en, this message translates to:
  /// **'by SYMLOOP'**
  String get splashByline;

  /// Skips onboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Advances onboarding one section.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Last onboarding button.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// Screen-reader label for the onboarding page dots.
  ///
  /// In en, this message translates to:
  /// **'Section {current} of {total}'**
  String sectionProgress(int current, int total);

  /// Onboarding 1 title.
  ///
  /// In en, this message translates to:
  /// **'Every service your event needs'**
  String get onboardingServicesTitle;

  /// Onboarding 1 body.
  ///
  /// In en, this message translates to:
  /// **'Photographers, venues, caterers, DJs, florists and decorators, all in one place.'**
  String get onboardingServicesDescription;

  /// Onboarding 2 title.
  ///
  /// In en, this message translates to:
  /// **'Compare, then book with confidence'**
  String get onboardingCompareTitle;

  /// Onboarding 2 body.
  ///
  /// In en, this message translates to:
  /// **'Real reviews, clear prices and open dates. Message a provider before you commit.'**
  String get onboardingCompareDescription;

  /// Onboarding 3 title.
  ///
  /// In en, this message translates to:
  /// **'Keep the whole event on track'**
  String get onboardingTrackTitle;

  /// Onboarding 3 body.
  ///
  /// In en, this message translates to:
  /// **'Follow every booking and watch your budget as the day comes together.'**
  String get onboardingTrackDescription;

  /// Welcome title.
  ///
  /// In en, this message translates to:
  /// **'Let’s get started'**
  String get welcomeTitle;

  /// Welcome body.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start booking or log in if you have been here before.'**
  String get welcomeSubtitle;

  /// Leads to sign-up, on Welcome and Login.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// Leads to login from Welcome.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeHaveAccount;

  /// Role selection title. Note the house-style space before the question mark.
  ///
  /// In en, this message translates to:
  /// **'How will you use Eventor ?'**
  String get roleSelectionTitle;

  /// Role selection body.
  ///
  /// In en, this message translates to:
  /// **'This shapes your whole experience in the app. It cannot be changed later.'**
  String get roleSelectionSubtitle;

  /// Client role card title.
  ///
  /// In en, this message translates to:
  /// **'I\'m planning an event'**
  String get roleClientTitle;

  /// Client role card description.
  ///
  /// In en, this message translates to:
  /// **'Find and book my event team'**
  String get roleClientDescription;

  /// Provider role card title.
  ///
  /// In en, this message translates to:
  /// **'I offer a service'**
  String get roleProviderTitle;

  /// Provider role card description.
  ///
  /// In en, this message translates to:
  /// **'List my services and manage bookings'**
  String get roleProviderDescription;

  /// Register title.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// Register body for a client.
  ///
  /// In en, this message translates to:
  /// **'Just a few details, then you can start booking your event team.'**
  String get registerSubtitle;

  /// Register body for a provider.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you and your business. You\'ll add your documents next.'**
  String get registerSubtitleProvider;

  /// Section title over the provider-only fields.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get registerBusinessTitle;

  /// Note under the business section title.
  ///
  /// In en, this message translates to:
  /// **'Shown to clients on your profile.'**
  String get registerBusinessNote;

  /// Register submit button.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerCreateAccount;

  /// First half of the terms line; the link follows it.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our '**
  String get registerTermsPrefix;

  /// The linked half of the terms line.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Policy'**
  String get registerTermsLink;

  /// Closes the terms sentence after the link.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get registerTermsSuffix;

  /// Prompt before the Log in link on Register.
  ///
  /// In en, this message translates to:
  /// **'Already have an account ?'**
  String get registerHasAccountPrompt;

  /// 08b banner title.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account'**
  String get registerEmailTakenTitle;

  /// 08b banner body.
  ///
  /// In en, this message translates to:
  /// **'Log in instead, or sign up with a different address.'**
  String get registerEmailTakenBody;

  /// Log in button and link.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Full name field label.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get nameLabel;

  /// Example shown in the empty name field.
  ///
  /// In en, this message translates to:
  /// **'Amina Benali'**
  String get namePlaceholder;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Example shown in the empty email field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailPlaceholder;

  /// Phone field label.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Example shown in the empty phone field.
  ///
  /// In en, this message translates to:
  /// **'0555 12 34 56'**
  String get phonePlaceholder;

  /// Helper under the phone field.
  ///
  /// In en, this message translates to:
  /// **'10 digits starting with 0, or +213.'**
  String get phoneHint;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Helper under a new-password field stating the server rule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{At least {count} character, with a letter and a digit.} other{At least {count} characters, with a letter and a digit.}}'**
  String passwordHint(int count);

  /// New password field label.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// Confirm password field label.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// Business name field label.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessNameLabel;

  /// Example shown in the empty business name field.
  ///
  /// In en, this message translates to:
  /// **'Studio Lumière'**
  String get businessNamePlaceholder;

  /// Provider category select label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Empty category select.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get categoryPlaceholder;

  /// Title of the category picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose your category'**
  String get categorySheetTitle;

  /// Client wilaya select label.
  ///
  /// In en, this message translates to:
  /// **'Wilaya (optional)'**
  String get wilayaOptionalLabel;

  /// Empty wilaya select.
  ///
  /// In en, this message translates to:
  /// **'Choose a wilaya'**
  String get wilayaPlaceholder;

  /// Title of the wilaya picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose your wilaya'**
  String get wilayaSheetTitle;

  /// Search field hint in the wilaya picker.
  ///
  /// In en, this message translates to:
  /// **'Find a wilaya'**
  String get wilayaSearchHint;

  /// Provider wilayas select label.
  ///
  /// In en, this message translates to:
  /// **'Wilayas served'**
  String get wilayasServedLabel;

  /// Empty wilayas-served select.
  ///
  /// In en, this message translates to:
  /// **'Choose where you work'**
  String get wilayasServedPlaceholder;

  /// Title of the wilayas-served picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Where do you work ?'**
  String get wilayasServedSheetTitle;

  /// Shown when wilayas or categories failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the list. Tap to try again.'**
  String get referenceLoadFailed;

  /// Name left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get nameRequired;

  /// Name below the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use at least {count} character.} other{Use at least {count} characters.}}'**
  String nameTooShort(int count);

  /// Business name left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name.'**
  String get businessNameRequired;

  /// Email left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get emailRequired;

  /// Email does not look like an address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address, like name@example.com.'**
  String get emailInvalid;

  /// Email already used by another account.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account.'**
  String get emailTaken;

  /// Phone left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get phoneRequired;

  /// Phone is not a whole Algerian number.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 digits starting with 0, or a +213 number.'**
  String get phoneInvalid;

  /// Phone already used by another account.
  ///
  /// In en, this message translates to:
  /// **'This phone number already has an account.'**
  String get phoneTaken;

  /// Password left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// Password below the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use at least {count} character.} other{Use at least {count} characters.}}'**
  String passwordTooShort(int count);

  /// Password lacks a letter or a digit.
  ///
  /// In en, this message translates to:
  /// **'Use at least one letter and one digit.'**
  String get passwordNeedsLetterAndDigit;

  /// Server refused the password as too common.
  ///
  /// In en, this message translates to:
  /// **'This password is too easy to guess. Choose another.'**
  String get passwordWeak;

  /// Confirmation differs from the password.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get passwordMismatch;

  /// Provider category not picked.
  ///
  /// In en, this message translates to:
  /// **'Choose your category.'**
  String get categoryRequired;

  /// No wilaya served picked.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one wilaya.'**
  String get wilayasRequired;

  /// 10b title.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyEmailTitle;

  /// 10b body.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {email} to activate your account.'**
  String verifyEmailSubtitle(String email);

  /// Label over the code boxes.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeLabel;

  /// Submits a code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyAction;

  /// Prompt before Resend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code ?'**
  String get verifyNoCodePrompt;

  /// Asks for a new code.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Resend while the cooldown runs; time is m:ss.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String resendIn(String time);

  /// Toast after a code was resent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way'**
  String get verifyCodeResent;

  /// 10c banner title.
  ///
  /// In en, this message translates to:
  /// **'That code is not right'**
  String get codeInvalidTitle;

  /// 10c banner body. The design adds an attempts count the API does not provide.
  ///
  /// In en, this message translates to:
  /// **'Check the six digits and try again.'**
  String get codeInvalidBody;

  /// Under the code boxes in mock builds only: no email is sent there, so the tester is told the code.
  ///
  /// In en, this message translates to:
  /// **'Mock mode — the code is always {code}.'**
  String mockCodeHint(String code);

  /// 10d banner title.
  ///
  /// In en, this message translates to:
  /// **'That code has expired'**
  String get codeExpiredTitle;

  /// 10d banner body.
  ///
  /// In en, this message translates to:
  /// **'Codes last 15 minutes. Ask for a new one and we will send it straight away.'**
  String get codeExpiredBody;

  /// 08e title.
  ///
  /// In en, this message translates to:
  /// **'Verify your business'**
  String get documentsTitle;

  /// 08e body.
  ///
  /// In en, this message translates to:
  /// **'Upload these three documents. We review them in one to two days.'**
  String get documentsSubtitle;

  /// 08e section title.
  ///
  /// In en, this message translates to:
  /// **'Verification documents'**
  String get documentsSectionTitle;

  /// 08e section note.
  ///
  /// In en, this message translates to:
  /// **'We review these before your services go live.'**
  String get documentsSectionNote;

  /// 08e primary button.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get documentsSubmit;

  /// 08e ghost button.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do it later'**
  String get documentsLater;

  /// Toast after submitting for review.
  ///
  /// In en, this message translates to:
  /// **'Documents sent. We review them in one to two days.'**
  String get documentsSubmitted;

  /// Empty document field.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get documentUploadAction;

  /// Helper while a document uploads.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get documentUploading;

  /// Helper once a document is on the server.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get documentUploaded;

  /// Helper for a document awaiting review.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get documentUnderReview;

  /// Helper for an approved document.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get documentApproved;

  /// Document actions sheet: replace.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file'**
  String get documentReplace;

  /// Document actions sheet: remove.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get documentRemove;

  /// Document left empty.
  ///
  /// In en, this message translates to:
  /// **'Attach this document.'**
  String get documentMissing;

  /// File above the size cap.
  ///
  /// In en, this message translates to:
  /// **'This file is over {count} MB. Attach a smaller one.'**
  String documentTooLarge(int count);

  /// File of a refused type.
  ///
  /// In en, this message translates to:
  /// **'Attach a PDF or an image.'**
  String get documentWrongType;

  /// Upload did not go through.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Tap to try again.'**
  String get documentUploadFailed;

  /// Document label.
  ///
  /// In en, this message translates to:
  /// **'National ID card'**
  String get documentIdentityCard;

  /// Document helper.
  ///
  /// In en, this message translates to:
  /// **'Front and back, in one file'**
  String get documentIdentityCardHint;

  /// Document label.
  ///
  /// In en, this message translates to:
  /// **'Commercial register or artisan card'**
  String get documentCommercialRegister;

  /// Document helper.
  ///
  /// In en, this message translates to:
  /// **'Whichever body you are registered with'**
  String get documentCommercialRegisterHint;

  /// Document label.
  ///
  /// In en, this message translates to:
  /// **'Tax registration card (NIF)'**
  String get documentTaxRegistration;

  /// Document helper.
  ///
  /// In en, this message translates to:
  /// **'Shows your fiscal identification number'**
  String get documentTaxRegistrationHint;

  /// Login title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// Login body.
  ///
  /// In en, this message translates to:
  /// **'Log in to pick up where you left off.'**
  String get loginSubtitle;

  /// Link to the reset flow.
  ///
  /// In en, this message translates to:
  /// **'Forgot password ?'**
  String get forgotPassword;

  /// Prompt before Create an account on Login.
  ///
  /// In en, this message translates to:
  /// **'New to Eventor ?'**
  String get loginNewPrompt;

  /// 07b banner title.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get loginWrongTitle;

  /// 07b banner body.
  ///
  /// In en, this message translates to:
  /// **'Check the address and try again — passwords are case sensitive.'**
  String get loginWrongBody;

  /// 07c banner title.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first'**
  String get loginUnverifiedTitle;

  /// 07c banner body.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email} when you signed up. It is still waiting.'**
  String loginUnverifiedBody(String email);

  /// 07c banner link.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get loginSendNewCode;

  /// 07d banner title.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts'**
  String get loginLockedTitle;

  /// 07d banner body; time is the clock time the lock ends.
  ///
  /// In en, this message translates to:
  /// **'This account is locked for a while to keep it safe. You can try again at {time}, or reset your password now.'**
  String loginLockedBody(String time);

  /// 07d disabled button; time is a clock time.
  ///
  /// In en, this message translates to:
  /// **'Try again at {time}'**
  String loginTryAgainAt(String time);

  /// Banner title when the account is blocked; the body is the server message.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked'**
  String get loginBlockedTitle;

  /// Banner title for an admin account.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t use the app'**
  String get loginNotAllowedTitle;

  /// Toast on Login after a reset.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Log in with your new password.'**
  String get passwordResetDone;

  /// 09 title.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// 09 body.
  ///
  /// In en, this message translates to:
  /// **'Enter the email on your account and we will send you a 6-digit code.'**
  String get forgotPasswordSubtitle;

  /// 09 button.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Ghost button back to Login.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get backToLogIn;

  /// 10 title.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get resetCodeTitle;

  /// 10 body.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String resetCodeSubtitle(String email);

  /// 10a title.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetPasswordTitle;

  /// 10a body.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from the one you used before.'**
  String get resetPasswordSubtitle;

  /// 10a button.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordAction;

  /// 10f title.
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get setPasswordTitle;

  /// 10f body.
  ///
  /// In en, this message translates to:
  /// **'Your Eventor account is ready. Choose a password and you are signed in.'**
  String get setPasswordSubtitle;

  /// 10f button.
  ///
  /// In en, this message translates to:
  /// **'Set password and sign in'**
  String get setPasswordAction;

  /// 10f/10g ghost button.
  ///
  /// In en, this message translates to:
  /// **'Need help ? Contact support'**
  String get needHelpContactSupport;

  /// 10g primary button, replacing Request a new link.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// 10g banner title.
  ///
  /// In en, this message translates to:
  /// **'This invite link has expired'**
  String get inviteExpiredTitle;

  /// 10g banner body.
  ///
  /// In en, this message translates to:
  /// **'Invite links last 7 days and can only be used once. Ask us for a fresh one and it will arrive in a moment.'**
  String get inviteExpiredBody;

  /// Banner title when the invite token is invalid or missing.
  ///
  /// In en, this message translates to:
  /// **'This invite link does not work'**
  String get inviteInvalidTitle;

  /// Banner body when the invite token is invalid or missing.
  ///
  /// In en, this message translates to:
  /// **'Open the link from your invitation email again, or ask us for a new one.'**
  String get inviteInvalidBody;

  /// Subject of the support email opened from 10g.
  ///
  /// In en, this message translates to:
  /// **'Help with my Eventor account'**
  String get supportEmailSubject;

  /// Leads to 08e from home.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get homeUploadDocuments;

  /// Signs out.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Status badge.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Status badge.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// Status badge.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// Status badge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Status badge.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Availability badge.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availabilityAvailable;

  /// Availability badge.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get availabilityUnavailable;

  /// Screen-reader label for a rating without count.
  ///
  /// In en, this message translates to:
  /// **'Rated {score} out of 5'**
  String ratingLabel(String score);

  /// Screen-reader label for a rating with its count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Rated {score} out of 5 from {count} review} other{Rated {score} out of 5 from {count} reviews}}'**
  String ratingWithCountLabel(String score, int count);

  /// Review count beside a rating.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{({count} review)} other{({count} reviews)}}'**
  String reviewCount(int count);

  /// Above a starting price.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get priceFrom;

  /// Accept a booking request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get requestAccept;

  /// Decline a booking request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get requestDecline;

  /// Default search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// Empty state of a filtered picker.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that search.'**
  String get selectionNoMatch;

  /// Closes a multi-select picker with nothing chosen.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get selectionDone;

  /// Closes a multi-select picker, stating how many are chosen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Done · {count} selected} other{Done · {count} selected}}'**
  String selectionDoneCount(int count);

  /// The Algerian dinar, after an amount: 45 000 DA.
  ///
  /// In en, this message translates to:
  /// **'DA'**
  String get currencyDzd;

  /// Shown instead of a price for a service priced on quote.
  ///
  /// In en, this message translates to:
  /// **'On quote'**
  String get priceOnQuote;

  /// Shown instead of a star score for something nobody has reviewed yet.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get ratingNew;

  /// Toast for a link to a screen that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Title of the error card shown when a list or detail fails to load.
  ///
  /// In en, this message translates to:
  /// **'We could not load this'**
  String get stateErrorTitle;

  /// Button on the error card that reloads.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get stateRetry;

  /// Badge on a provider whose documents Eventor checked.
  ///
  /// In en, this message translates to:
  /// **'Verified provider'**
  String get verifiedProvider;

  /// Expands a long description.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// Collapses an expanded description.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// Link beside a section title that opens the full list.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Link that opens a full list, with its size.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String seeAllCount(int count);

  /// On a saved item whose service or pack is no longer listed.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get noLongerAvailable;

  /// Toast action that reverses the last change.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Screen-reader label of an empty heart: saves the item to favourites.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get favouriteSave;

  /// Screen-reader label of a filled heart: the item is in favourites.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get favouriteSaved;

  /// Toast when saving or un-saving a favourite fails.
  ///
  /// In en, this message translates to:
  /// **'We could not update your favourites. Try again.'**
  String get favouriteFailed;

  /// Toast after removing an item on the Favorites screen, with Undo.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get favouriteRemoved;

  /// Price unit: the price covers one event.
  ///
  /// In en, this message translates to:
  /// **'per event'**
  String get priceUnitPerEvent;

  /// Price unit: charged by the hour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get priceUnitPerHour;

  /// Price unit: charged per guest.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get priceUnitPerPerson;

  /// Price unit: charged by the day.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get priceUnitPerDay;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get eventTypeWedding;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get eventTypeEngagement;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Henna'**
  String get eventTypeHenna;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventTypeBirthday;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Circumcision'**
  String get eventTypeCircumcision;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Graduation'**
  String get eventTypeGraduation;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get eventTypeCorporate;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Conference'**
  String get eventTypeConference;

  /// Event type chip.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get eventTypeOther;

  /// Calendar legend: the chosen day.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get calendarSelected;

  /// Calendar legend: a day that can be requested.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get calendarAvailable;

  /// Calendar legend: a day with no capacity left.
  ///
  /// In en, this message translates to:
  /// **'Fully booked'**
  String get calendarBooked;

  /// Calendar legend: a day the provider does not offer, or too soon.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get calendarUnavailable;

  /// Screen-reader label of the calendar's back arrow.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// Screen-reader label of the calendar's forward arrow.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// Under a calendar: the minimum notice, from the app config.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Dates need at least {count} day\'s notice.} other{Dates need at least {count} days\' notice.}}'**
  String calendarMinNotice(int count);

  /// Action bar when the provider paused bookings.
  ///
  /// In en, this message translates to:
  /// **'Not taking new bookings'**
  String get notAcceptingTitle;

  /// Under 'Not taking new bookings': messaging still works.
  ///
  /// In en, this message translates to:
  /// **'Messages are still open'**
  String get notAcceptingBody;

  /// Button that opens a chat with the provider.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get sendMessage;

  /// Screen-reader label of the message icon button.
  ///
  /// In en, this message translates to:
  /// **'Message the provider'**
  String get messageProvider;

  /// Primary button on a service.
  ///
  /// In en, this message translates to:
  /// **'Request booking'**
  String get requestBooking;

  /// Primary button on a pack.
  ///
  /// In en, this message translates to:
  /// **'Request pack'**
  String get requestPack;

  /// Before a pack's saving amount: 'Save 45 000 DA'.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get packSave;

  /// Under the big rating on a detail screen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Based on {count} review} other{Based on {count} reviews}}'**
  String basedOnReviews(int count);

  /// How often a service was booked, on a result card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not booked yet} one{Booked once} other{Booked {count} times}}'**
  String bookedTimes(int count);

  /// A count of services.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} service} other{{count} services}}'**
  String servicesCount(int count);

  /// The provider behind a pack.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String packBy(String name);

  /// Screen-reader label of a photo carousel's position.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {count}'**
  String photoCounterLabel(int index, int count);

  /// Screen-reader label of the round Back button over a photo.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabelOnPhoto;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Title on a tab whose screens are not built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get tabComingSoonTitle;

  /// Body on a tab whose screens are not built yet.
  ///
  /// In en, this message translates to:
  /// **'This part of Eventor is on its way.'**
  String get tabComingSoonBody;

  /// Row on the Profile tab that opens the saved services and packs.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileFavourites;

  /// Note under the Profile tab's rows while the full profile is not built.
  ///
  /// In en, this message translates to:
  /// **'More settings are coming soon.'**
  String get profileMoreSoon;

  /// Home greeting, 05:00–11:59.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// Home greeting, 12:00–17:59.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// Home greeting, 18:00–04:59.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// Home's city pill when the client has none, and the title of the city sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get chooseCity;

  /// Under the city sheet's title.
  ///
  /// In en, this message translates to:
  /// **'We show services that cover it. Only wilayas open on Eventor are listed.'**
  String get chooseCitySubtitle;

  /// Toast when saving the chosen city fails.
  ///
  /// In en, this message translates to:
  /// **'We could not change your city. Try again.'**
  String get cityChangeFailed;

  /// Placeholder of Home's search field.
  ///
  /// In en, this message translates to:
  /// **'Search a service or a provider'**
  String get homeSearchHint;

  /// Screen-reader label of Home's filter button.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get homeFiltersLabel;

  /// Screen-reader label of Home's bell.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotificationsLabel;

  /// Screen-reader label of Home's bell when something is unread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, unread'**
  String get homeNotificationsUnread;

  /// Home section title.
  ///
  /// In en, this message translates to:
  /// **'Your bookings'**
  String get homeYourBookings;

  /// Home section title.
  ///
  /// In en, this message translates to:
  /// **'Your budget'**
  String get homeYourBudget;

  /// Link beside 'Your budget'.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get budgetDetails;

  /// Between the spent and the planned amounts: '180 000 DA of 400 000 DA planned'.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get budgetOf;

  /// After the planned amount on Home's budget card.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get budgetPlanned;

  /// Under the budget bar.
  ///
  /// In en, this message translates to:
  /// **'{booked} of {count, plural, one{{count} service} other{{count} services}} booked'**
  String budgetBooked(int booked, int count);

  /// Home's budget card when there is none (11c).
  ///
  /// In en, this message translates to:
  /// **'Plan your budget'**
  String get budgetEmptyTitle;

  /// Body of the 11c budget card.
  ///
  /// In en, this message translates to:
  /// **'Set a total, then track what each service really costs. Only you can see it.'**
  String get budgetEmptyBody;

  /// Button on the 11c budget card.
  ///
  /// In en, this message translates to:
  /// **'Create a budget'**
  String get budgetCreate;

  /// Home section title, and the title of screen 19.
  ///
  /// In en, this message translates to:
  /// **'Ready Packs'**
  String get homeReadyPacks;

  /// Home's last section: the best-rated services in the client's city.
  ///
  /// In en, this message translates to:
  /// **'Services near you'**
  String get homeServicesNearYou;

  /// Title of the filters drawer (11a).
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// Screen-reader label of the drawer's close button.
  ///
  /// In en, this message translates to:
  /// **'Close filters'**
  String get filtersClose;

  /// Filters group label.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filtersSortBy;

  /// Sort order.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// Sort order.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get sortPriceLow;

  /// Sort order.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get sortPriceHigh;

  /// Sort order.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get sortRating;

  /// Sort order.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get sortPopular;

  /// Sort order.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// Filters group label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filtersCategory;

  /// Filters group label, and the drill-in's title.
  ///
  /// In en, this message translates to:
  /// **'Wilaya'**
  String get filtersWilaya;

  /// Chip that opens the full wilaya list.
  ///
  /// In en, this message translates to:
  /// **'All wilayas'**
  String get filtersAllWilayas;

  /// Filters group label.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get filtersBudget;

  /// Filters group label.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get filtersEventDate;

  /// The event date field when no date is set.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get filtersEventDateAny;

  /// Under the event date field.
  ///
  /// In en, this message translates to:
  /// **'Only providers free on that day.'**
  String get filtersEventDateHint;

  /// Screen-reader label of the button that clears the event date.
  ///
  /// In en, this message translates to:
  /// **'Clear the date'**
  String get filtersEventDateClear;

  /// Filters group label.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filtersRating;

  /// Rating chip: no minimum.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filtersRatingAny;

  /// Filters group label.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get filtersSaved;

  /// Switch that keeps only saved services.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get filtersFavouritesOnly;

  /// Resets every filter.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filtersClearAll;

  /// The drawer's primary button, with the live result count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No services} one{Show {count} service} other{Show {count} services}}'**
  String filtersShowCount(int count);

  /// The drawer's primary button while the count is loading or unknown.
  ///
  /// In en, this message translates to:
  /// **'Show services'**
  String get filtersShow;

  /// The wilaya drill-in's primary button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Done} one{Done · {count} selected} other{Done · {count} selected}}'**
  String wilayaDoneCount(int count);

  /// The wilaya drill-in's secondary button.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wilayaClear;

  /// Title of the sheet that picks the filters' event date.
  ///
  /// In en, this message translates to:
  /// **'Pick your event date'**
  String get eventDateSheetTitle;

  /// S1 section title.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// Link that empties the recent searches.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// Screen-reader label of a recent search's remove button.
  ///
  /// In en, this message translates to:
  /// **'Remove {query}'**
  String searchRemoveRecent(String query);

  /// S1 section title.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get searchBrowseCategories;

  /// How many results S2 found.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No services} one{{count} service} other{{count} services}}'**
  String resultsCount(int count);

  /// S2 chip that opens the sort choices.
  ///
  /// In en, this message translates to:
  /// **'Sort · {order}'**
  String resultsSortChip(String order);

  /// S2 chip that opens the filters drawer, with how many are on.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Filters} other{Filters · {count}}}'**
  String resultsFiltersChip(int count);

  /// S2 title when there is neither a search nor a category.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get resultsAllServices;

  /// S2b title.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches those filters'**
  String get resultsEmptyTitle;

  /// S2b body.
  ///
  /// In en, this message translates to:
  /// **'Try a wider budget, another wilaya or fewer filters.'**
  String get resultsEmptyBody;

  /// S2b line naming the search that found nothing.
  ///
  /// In en, this message translates to:
  /// **'No services for “{query}”.'**
  String resultsEmptySearch(String query);

  /// S2b button.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get resultsClearFilters;

  /// Under the list when the next page fails.
  ///
  /// In en, this message translates to:
  /// **'We could not load more results.'**
  String get resultsLoadMoreFailed;

  /// Screen-reader label of a removable filter chip.
  ///
  /// In en, this message translates to:
  /// **'Remove filter {label}'**
  String resultsRemoveFilter(String label);

  /// Removable chip for the favourites-only filter.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filterChipFavourites;

  /// Section title on 12.
  ///
  /// In en, this message translates to:
  /// **'About this service'**
  String get serviceAbout;

  /// Card title on 12 and 20.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get serviceGoodToKnow;

  /// The provider's own cancellation policy, quoted.
  ///
  /// In en, this message translates to:
  /// **'Provider\'s policy: {policy}'**
  String serviceCancellation(String policy);

  /// Section title on 12: paid add-ons.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get serviceExtras;

  /// Section title above the calendar on 12 and 20.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get servicePickDate;

  /// Before the chosen day under the calendar.
  ///
  /// In en, this message translates to:
  /// **'Your date'**
  String get selectedDateLabel;

  /// Under the calendar on 12.
  ///
  /// In en, this message translates to:
  /// **'The provider confirms the exact time after your request.'**
  String get calendarConfirmNote;

  /// In place of the calendar when a month fails to load.
  ///
  /// In en, this message translates to:
  /// **'We could not load this month.'**
  String get monthLoadFailed;

  /// Section title on 12, 13 and 20.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get serviceReviews;

  /// In the reviews section when there are none.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get serviceNoReviews;

  /// Section title on 12.
  ///
  /// In en, this message translates to:
  /// **'Packs from this provider'**
  String get servicePacksFromProvider;

  /// Link at the foot of 12.
  ///
  /// In en, this message translates to:
  /// **'Report this service'**
  String get serviceReport;

  /// A capacity line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Up to {count} guest} other{Up to {count} guests}}'**
  String upToGuests(int count);

  /// On the provider mini-card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} year in business} other{{count} years in business}}'**
  String yearsInBusiness(int count);

  /// Reply time, from the API ('2 h').
  ///
  /// In en, this message translates to:
  /// **'Usually replies in {time}'**
  String repliesIn(String time);

  /// When a service, provider or pack was removed.
  ///
  /// In en, this message translates to:
  /// **'This is no longer available'**
  String get detailGoneTitle;

  /// Under 'This is no longer available'.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed by the provider.'**
  String get detailGoneBody;

  /// Button on the no-longer-available card.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get detailGoneBack;

  /// Section title on 13.
  ///
  /// In en, this message translates to:
  /// **'What we checked'**
  String get profileChecked;

  /// A check on 13: national ID checked by Eventor.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get checkIdentity;

  /// A check on 13: commercial register or artisan card verified.
  ///
  /// In en, this message translates to:
  /// **'Registered activity'**
  String get checkRegistration;

  /// A check on 13: measured over the last 30 days.
  ///
  /// In en, this message translates to:
  /// **'Replies quickly'**
  String get checkReplyTime;

  /// Section title on 13.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// Section title on 13.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get profileServices;

  /// Section title on 13.
  ///
  /// In en, this message translates to:
  /// **'Where they work'**
  String get profileWhereTheyWork;

  /// Languages the provider speaks.
  ///
  /// In en, this message translates to:
  /// **'Speaks {languages}'**
  String profileLanguages(String languages);

  /// Before the month and year the provider joined.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profileMemberSince;

  /// Link at the foot of 13.
  ///
  /// In en, this message translates to:
  /// **'Report this provider'**
  String get profileReport;

  /// A language name.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langAr;

  /// A language name.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFr;

  /// A language name.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// Under the rating in 13's stat strip (the number is shown above it).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{review} other{reviews}}'**
  String statReviewsLabel(int count);

  /// Under the completed count in 13's stat strip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{booking completed} other{bookings completed}}'**
  String statCompletedLabel(int count);

  /// Under the years count in 13's stat strip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{year in business} other{years in business}}'**
  String statYearsLabel(int count);

  /// Under the title of 19.
  ///
  /// In en, this message translates to:
  /// **'Bundles put together by one provider — a single price, everything included.'**
  String get packsSubtitle;

  /// Event type chip on 19: no filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get packsAll;

  /// The sort row on 19.
  ///
  /// In en, this message translates to:
  /// **'Sorted by {order}'**
  String packsSortedBy(String order);

  /// Pack sort order, inside 'Sorted by …'.
  ///
  /// In en, this message translates to:
  /// **'best savings'**
  String get packOrderSavings;

  /// Pack sort order, inside 'Sorted by …'.
  ///
  /// In en, this message translates to:
  /// **'lowest price'**
  String get packOrderPriceAsc;

  /// Pack sort order, inside 'Sorted by …'.
  ///
  /// In en, this message translates to:
  /// **'highest price'**
  String get packOrderPriceDesc;

  /// Pack sort order, inside 'Sorted by …'.
  ///
  /// In en, this message translates to:
  /// **'top rated'**
  String get packOrderRating;

  /// Pack sort order, inside 'Sorted by …'.
  ///
  /// In en, this message translates to:
  /// **'most popular'**
  String get packOrderPopular;

  /// 19 when an event type has no packs.
  ///
  /// In en, this message translates to:
  /// **'No packs here yet'**
  String get packsEmptyTitle;

  /// Under 'No packs here yet'.
  ///
  /// In en, this message translates to:
  /// **'Try another event type.'**
  String get packsEmptyBody;

  /// Badge above a pack's name on 20.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Ready Pack · {count} service} other{Ready Pack · {count} services}}'**
  String packBadge(int count);

  /// How often a pack was booked, on 20.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not booked yet} one{Booked once} other{Booked {count} times}}'**
  String packBookings(int count);

  /// Beside the saving on 20's price card.
  ///
  /// In en, this message translates to:
  /// **'versus booking separately'**
  String get packVersus;

  /// Section title on 20.
  ///
  /// In en, this message translates to:
  /// **'What is inside'**
  String get packInside;

  /// The total row under a pack's items.
  ///
  /// In en, this message translates to:
  /// **'Booked separately'**
  String get packBookedSeparately;

  /// Under the calendar on 20.
  ///
  /// In en, this message translates to:
  /// **'Only days when every service in the pack is free.'**
  String get packCalendarHint;

  /// Section title on 20.
  ///
  /// In en, this message translates to:
  /// **'About this pack'**
  String get packAbout;

  /// Where every service in the pack works.
  ///
  /// In en, this message translates to:
  /// **'Available in {wilayas}'**
  String packAvailableIn(String wilayas);

  /// Under the price in 20's sticky bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} service included} other{all {count} services}}'**
  String packAllServices(int count);

  /// Title of screen 17.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favouritesTitle;

  /// Tab on 17.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get favouritesServices;

  /// Tab on 17.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get favouritesPacks;

  /// Category chip on 17: every category.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get favouritesAll;

  /// 17's Services tab when empty.
  ///
  /// In en, this message translates to:
  /// **'No saved services yet'**
  String get favouritesEmptyServices;

  /// 17's Packs tab when empty.
  ///
  /// In en, this message translates to:
  /// **'No saved packs yet'**
  String get favouritesEmptyPacks;

  /// Under 17's empty title.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a service or a pack to keep it here.'**
  String get favouritesEmptyBody;

  /// 17's empty-state button: opens Search.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get favouritesExplore;

  /// Toast on Home after the first Back press; a second press within two seconds closes the app.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// Title of the offline banner.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineTitle;

  /// The action on the offline banner.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get offlineRetry;

  /// Screen 14 title.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// Search field hint on screen 14.
  ///
  /// In en, this message translates to:
  /// **'Search a conversation'**
  String get messagesSearchHint;

  /// Screen 14 chip: every conversation.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get messagesFilterAll;

  /// Screen 14 chip: conversations with unread messages.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get messagesFilterUnread;

  /// Screen 14 chip: conversations attached to a booking.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get messagesFilterBookings;

  /// Screen 14 empty state title.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get messagesEmptyTitle;

  /// Screen 14 empty state body.
  ///
  /// In en, this message translates to:
  /// **'When you write to a provider, your conversations appear here.'**
  String get messagesEmptyBody;

  /// Screen 14 empty state button to the Search tab.
  ///
  /// In en, this message translates to:
  /// **'Find a provider'**
  String get messagesEmptyAction;

  /// Screen 14 empty state under the Unread chip.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get messagesUnreadEmpty;

  /// Screen 14 empty state under the Bookings chip.
  ///
  /// In en, this message translates to:
  /// **'No booking conversations yet'**
  String get messagesBookingsEmpty;

  /// Screen 14 empty search result.
  ///
  /// In en, this message translates to:
  /// **'No conversations match \"{query}\"'**
  String messagesNoMatch(String query);

  /// Offline banner body on screen 14.
  ///
  /// In en, this message translates to:
  /// **'These are your last messages. New ones arrive when you reconnect.'**
  String get offlineMessagesBody;

  /// Name of a dispute conversation; reference is a booking reference like EVT-2041.
  ///
  /// In en, this message translates to:
  /// **'Dispute · {reference}'**
  String chatDispute(String reference);

  /// Name of a dispute conversation with no booking reference.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get chatDisputeNoRef;

  /// Name of the Eventor support conversation.
  ///
  /// In en, this message translates to:
  /// **'Eventor support'**
  String get chatSupport;

  /// Name shown when the other person's account was deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted account'**
  String get chatDeletedAccount;

  /// Preview of a conversation whose last message is a photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhoto;

  /// A message Eventor removed (bubble and preview).
  ///
  /// In en, this message translates to:
  /// **'Removed by Eventor'**
  String get chatRemoved;

  /// Time ladder: a message from yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// Screen-reader label for a conversation's unread badge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String messagesUnreadCount(int count);

  /// Chat composer placeholder.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chatComposerHint;

  /// Chat composer placeholder in a dispute chat.
  ///
  /// In en, this message translates to:
  /// **'Write to both parties'**
  String get chatComposerDisputeHint;

  /// Shown in place of the composer when a chat is closed.
  ///
  /// In en, this message translates to:
  /// **'This conversation was closed by Eventor. You can still read it.'**
  String get chatClosed;

  /// Shown in place of the composer when the other account is blocked or deleted.
  ///
  /// In en, this message translates to:
  /// **'This account is no longer active. You can still read the conversation.'**
  String get chatOtherBlocked;

  /// Caption under a message whose contact details were hidden.
  ///
  /// In en, this message translates to:
  /// **'Number hidden until the booking is accepted'**
  String get chatMaskedNote;

  /// Under a message that failed to send.
  ///
  /// In en, this message translates to:
  /// **'Not sent · Tap to retry'**
  String get chatNotSent;

  /// Pill that jumps to new messages below.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get chatNewMessages;

  /// Empty draft chat hint.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name}'**
  String chatSayHello(String name);

  /// Date pill for today's messages.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// Subtitle of a dispute chat; name is the provider.
  ///
  /// In en, this message translates to:
  /// **'You, {name} and Eventor support'**
  String chatGroupSubtitle(String name);

  /// Chat ⋯ menu: open the provider's profile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get chatViewProfile;

  /// Chat ⋯ menu: report the other person.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String chatReportUser(String name);

  /// Message long-press menu: copy the text.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// Message long-press menu: report the message.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get chatReportMessage;

  /// On a chat photo that failed to load.
  ///
  /// In en, this message translates to:
  /// **'Tap to reload'**
  String get photoReload;

  /// Report sheet title.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get reportReasonInappropriate;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Sharing contact details'**
  String get reportReasonContact;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Fake or scam'**
  String get reportReasonFake;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// Report sheet note hint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get reportNoteHint;

  /// Report sheet button.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// Send button label.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// The composer's + button.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get chatAttach;

  /// The chat's ⋯ button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get chatMore;

  /// The ✕ on the attached photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get chatRemoveAttachment;

  /// Screen-reader label for a message still sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get chatSending;

  /// Top of the thread when older messages failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load older messages'**
  String get chatOlderFailed;

  /// Photo viewer close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get photoViewerClose;

  /// Chat that is gone or not yours.
  ///
  /// In en, this message translates to:
  /// **'This conversation is no longer available'**
  String get chatUnavailable;

  /// Toast after copying a message.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get chatCopied;

  /// Toast when attaching a photo in a new chat.
  ///
  /// In en, this message translates to:
  /// **'Send a message first'**
  String get chatPhotoNeedsText;

  /// Toast for a photo over the size limit.
  ///
  /// In en, this message translates to:
  /// **'This photo is larger than {mb} MB'**
  String photoTooLarge(int mb);

  /// Toast for an unsupported photo type.
  ///
  /// In en, this message translates to:
  /// **'Use a JPEG, PNG, WebP or HEIC photo'**
  String get photoWrongType;

  /// Toast after a report.
  ///
  /// In en, this message translates to:
  /// **'Thanks — we\'ll look into it'**
  String get reportSent;

  /// Toast when the same thing was reported before.
  ///
  /// In en, this message translates to:
  /// **'You already reported this'**
  String get reportAlready;

  /// Screen 16 title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Screen 16 action.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAll;

  /// Screen 16 group label.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsToday;

  /// Screen 16 group label.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get notificationsThisWeek;

  /// Screen 16 group label.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsEarlier;

  /// Screen 16 empty state title.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// Screen 16 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Booking updates, messages and reminders will show up here.'**
  String get notificationsEmptyBody;

  /// Screen-reader suffix for an unread notification.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// Offline banner body on screen 16.
  ///
  /// In en, this message translates to:
  /// **'These are your last notifications. New ones arrive when you reconnect.'**
  String get offlineNotificationsBody;

  /// Top bar of 18, 18a and 18f.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// 18's top-bar action, opening 18f.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get budgetEdit;

  /// Heading of 18a Create.
  ///
  /// In en, this message translates to:
  /// **'Plan your event budget'**
  String get budgetCreateIntroTitle;

  /// Heading of 18f Edit.
  ///
  /// In en, this message translates to:
  /// **'Edit your budget'**
  String get budgetEditIntroTitle;

  /// Under the 18f heading.
  ///
  /// In en, this message translates to:
  /// **'Changing the total leaves your expense lines untouched. Only you can see this.'**
  String get budgetEditIntroBody;

  /// Field label on 18a/18f.
  ///
  /// In en, this message translates to:
  /// **'Budget name'**
  String get budgetNameLabel;

  /// Placeholder of the budget name.
  ///
  /// In en, this message translates to:
  /// **'e.g. Our wedding'**
  String get budgetNameHint;

  /// Field label on 18a/18f, and the date sheet title.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get budgetEventDateLabel;

  /// Date sheet button that clears the optional event date.
  ///
  /// In en, this message translates to:
  /// **'Remove the date'**
  String get budgetEventDateClear;

  /// Placeholder of an optional picker field.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalField;

  /// Field label on 18a/18f. Arabic carries the currency in the label, as drawn.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get budgetTotalLabel;

  /// Unit inside an amount field. Empty in Arabic, whose labels carry (دج) instead.
  ///
  /// In en, this message translates to:
  /// **'DA'**
  String get amountFieldSuffix;

  /// Button on 18a.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get budgetCreateAction;

  /// Button on 18f.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get budgetSaveChanges;

  /// After the big amount on 18's summary.
  ///
  /// In en, this message translates to:
  /// **'spent'**
  String get budgetSpent;

  /// After the planned total on 18: "380 000 DA allocated across 6 lines". The amount is a separate token before it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{DA allocated across 0 lines} =1{DA allocated across 1 line} other{DA allocated across {count} lines}}'**
  String budgetAllocatedLines(int count);

  /// 18's stat label.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetRemaining;

  /// 18's stat label.
  ///
  /// In en, this message translates to:
  /// **'Services booked'**
  String get budgetServicesBooked;

  /// "3 of 6" under Services booked on 18.
  ///
  /// In en, this message translates to:
  /// **'{booked} of {count}'**
  String budgetBookedOf(int booked, int count);

  /// 18's list heading.
  ///
  /// In en, this message translates to:
  /// **'Expense lines'**
  String get budgetExpenseLines;

  /// Beside 18's list heading.
  ///
  /// In en, this message translates to:
  /// **'Actual vs planned'**
  String get budgetActualVsPlanned;

  /// A line with no linked booking.
  ///
  /// In en, this message translates to:
  /// **'Not booked yet'**
  String get budgetNotBookedYet;

  /// Under a line whose spent amount equals its plan.
  ///
  /// In en, this message translates to:
  /// **'on plan'**
  String get budgetLineOnPlan;

  /// Under a line with nothing spent yet, after its planned amount.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get budgetLinePlanned;

  /// 18c empty card title.
  ///
  /// In en, this message translates to:
  /// **'No expense lines yet'**
  String get budgetNoLinesTitle;

  /// 18c empty card body.
  ///
  /// In en, this message translates to:
  /// **'Add a line for each service you are paying for, and the remaining amount keeps itself up to date.'**
  String get budgetNoLinesBody;

  /// 18's button, and 18d's title.
  ///
  /// In en, this message translates to:
  /// **'Add an expense'**
  String get budgetAddExpense;

  /// 18g banner title.
  ///
  /// In en, this message translates to:
  /// **'You are over your budget'**
  String get budgetOverTitle;

  /// 18g banner body.
  ///
  /// In en, this message translates to:
  /// **'You have spent more than your total. Raise the budget, or trim a line.'**
  String get budgetOverBody;

  /// 18d heading.
  ///
  /// In en, this message translates to:
  /// **'New expense line'**
  String get expenseNewTitle;

  /// Under the 18d heading.
  ///
  /// In en, this message translates to:
  /// **'A name and a planned amount are enough to start. Everything else can wait.'**
  String get expenseNewBody;

  /// 18b top bar.
  ///
  /// In en, this message translates to:
  /// **'Expense line'**
  String get expenseLineTitle;

  /// Under the 18b heading.
  ///
  /// In en, this message translates to:
  /// **'Linking a booking shows who it is with and counts it as booked. You still enter what you actually paid.'**
  String get expenseEditBody;

  /// 18b's top-bar action, opening 18e.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get expenseDelete;

  /// Field label on 18d/18b, and the category sheet title.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategoryLabel;

  /// Category field before one is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get expenseCategoryPlaceholder;

  /// First row of the category sheet, to clear it.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get expenseNoCategory;

  /// Field label on 18d/18b.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get expenseLabelLabel;

  /// Placeholder of the line label.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wedding cake'**
  String get expenseLabelHint;

  /// Field label on 18d/18b.
  ///
  /// In en, this message translates to:
  /// **'Planned amount'**
  String get expensePlannedLabel;

  /// Field label on 18d/18b.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get expenseSpentLabel;

  /// Field label on 18d/18b.
  ///
  /// In en, this message translates to:
  /// **'Linked booking'**
  String get expenseBookingLabel;

  /// Linked booking field with none, and the first row of 18h.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get expenseNotLinked;

  /// Button on 18d.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get expenseAddLine;

  /// Button on 18b.
  ///
  /// In en, this message translates to:
  /// **'Save line'**
  String get expenseSaveLine;

  /// 18i banner title.
  ///
  /// In en, this message translates to:
  /// **'This budget is full'**
  String get expenseFullTitle;

  /// 18i banner body.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum number of expense lines. Delete one you no longer need, or merge two into a single line.'**
  String get expenseFullBody;

  /// 18e sheet title. Space before ? per the copy rule.
  ///
  /// In en, this message translates to:
  /// **'Delete this line ?'**
  String get expenseDeleteTitle;

  /// 18e sheet body.
  ///
  /// In en, this message translates to:
  /// **'It disappears from your budget and the remaining amount is recalculated. The booking it is linked to is not touched.'**
  String get expenseDeleteBody;

  /// 18e recap row.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get expenseDeleteSpent;

  /// 18e recap row.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get expenseDeletePlanned;

  /// 18e destructive button.
  ///
  /// In en, this message translates to:
  /// **'Delete line'**
  String get expenseDeleteConfirm;

  /// 18e cancel button.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get expenseDeleteKeep;

  /// 18h top bar.
  ///
  /// In en, this message translates to:
  /// **'Link a booking'**
  String get linkBookingTitle;

  /// 18h intro.
  ///
  /// In en, this message translates to:
  /// **'Only your own bookings appear here. Linking one fills in the provider and counts this line in “services booked”.'**
  String get linkBookingIntro;

  /// Under 18h's Not linked row.
  ///
  /// In en, this message translates to:
  /// **'This line is not tied to any booking'**
  String get linkBookingNoneBody;

  /// On a booking already linked to another line of the budget.
  ///
  /// In en, this message translates to:
  /// **'On “{label}”'**
  String linkBookingUsedOn(String label);

  /// Under the 18h list.
  ///
  /// In en, this message translates to:
  /// **'A booking already used on another line is shown greyed out, so the same amount is never counted twice.'**
  String get linkBookingNote;

  /// Button on 18h.
  ///
  /// In en, this message translates to:
  /// **'Link booking'**
  String get linkBookingAction;

  /// 18h with nothing to link.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get linkBookingEmptyTitle;

  /// 18h with nothing to link.
  ///
  /// In en, this message translates to:
  /// **'Once you book a service, you can link it to this line.'**
  String get linkBookingEmptyBody;

  /// Sheet when leaving a form with unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes ?'**
  String get discardTitle;

  /// Sheet when leaving a form with unsaved edits.
  ///
  /// In en, this message translates to:
  /// **'What you changed here will not be saved.'**
  String get discardBody;

  /// Destructive button of the discard sheet.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardConfirm;

  /// Cancel button of the discard sheet.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardKeep;

  /// The provider's second tab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// The provider's third tab.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// Row on the provider's Profile tab.
  ///
  /// In en, this message translates to:
  /// **'My documents'**
  String get profileDocuments;

  /// 21's availability pill, and its first choice.
  ///
  /// In en, this message translates to:
  /// **'Accepting bookings'**
  String get providerAccepting;

  /// 21's availability pill when paused, and its second choice.
  ///
  /// In en, this message translates to:
  /// **'Bookings paused'**
  String get providerPaused;

  /// Under the Accepting choice.
  ///
  /// In en, this message translates to:
  /// **'Clients can send you new requests.'**
  String get providerAcceptingHint;

  /// Under the Paused choice.
  ///
  /// In en, this message translates to:
  /// **'No new requests until you turn it back on. Your services stay visible.'**
  String get providerPausedHint;

  /// Title of the availability sheet on 21.
  ///
  /// In en, this message translates to:
  /// **'Your availability'**
  String get providerAvailabilityTitle;

  /// Subtitle of the availability sheet.
  ///
  /// In en, this message translates to:
  /// **'Pausing keeps the bookings you already have.'**
  String get providerAvailabilityBody;

  /// Toast after turning bookings back on.
  ///
  /// In en, this message translates to:
  /// **'You are accepting bookings again.'**
  String get providerNowAccepting;

  /// Toast after pausing bookings.
  ///
  /// In en, this message translates to:
  /// **'New bookings are paused.'**
  String get providerNowPaused;

  /// 21's counter.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get providerStatRequests;

  /// 21's counter.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get providerStatUpcoming;

  /// 21's counter.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get providerStatServices;

  /// 21's section.
  ///
  /// In en, this message translates to:
  /// **'Booking requests'**
  String get providerRequestsTitle;

  /// 21 with no pending request.
  ///
  /// In en, this message translates to:
  /// **'No new requests'**
  String get providerNoRequestsTitle;

  /// 21 with no pending request.
  ///
  /// In en, this message translates to:
  /// **'New booking requests show up here, and you have {hours} h to answer each one.'**
  String providerNoRequestsBody(int hours);

  /// 21 with no request while paused.
  ///
  /// In en, this message translates to:
  /// **'Your bookings are paused, so clients cannot send new requests.'**
  String get providerNoRequestsPausedBody;

  /// End of a request row's meta line on 21.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =0{reply now} other{reply within {hours} h}}'**
  String providerReplyWithin(int hours);

  /// Toast after Accept.
  ///
  /// In en, this message translates to:
  /// **'Request from {name} accepted.'**
  String providerAccepted(String name);

  /// Toast after P3.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get providerDeclined;

  /// 21's section.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get providerUpcomingTitle;

  /// 21's upcoming section when empty.
  ///
  /// In en, this message translates to:
  /// **'No confirmed bookings ahead yet.'**
  String get providerNoUpcoming;

  /// 21's button.
  ///
  /// In en, this message translates to:
  /// **'Availability calendar'**
  String get providerAvailabilityCalendar;

  /// 21's section.
  ///
  /// In en, this message translates to:
  /// **'Your services'**
  String get providerServicesTitle;

  /// 21's link beside Your services.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get providerManage;

  /// 21's button.
  ///
  /// In en, this message translates to:
  /// **'Add a service'**
  String get providerAddService;

  /// Under the disabled Add a service on 21a/21b.
  ///
  /// In en, this message translates to:
  /// **'Available once your profile is approved.'**
  String get providerServicesAfterApproval;

  /// Service status badge.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get serviceStatusPublished;

  /// Service status badge.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get serviceStatusDraft;

  /// Service status badge.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get serviceStatusHidden;

  /// Document status pill.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get documentStateInReview;

  /// Document status pill.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get documentStateApproved;

  /// Document status pill.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get documentStateRejected;

  /// Document status pill.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get documentStateMissing;

  /// The register document in lists (21a/21b/08d).
  ///
  /// In en, this message translates to:
  /// **'Register or artisan card'**
  String get documentRegisterShort;

  /// The ID card inside a sentence.
  ///
  /// In en, this message translates to:
  /// **'national ID card'**
  String get documentPhraseNationalId;

  /// The register inside a sentence.
  ///
  /// In en, this message translates to:
  /// **'register or artisan card'**
  String get documentPhraseRegister;

  /// The tax card inside a sentence.
  ///
  /// In en, this message translates to:
  /// **'tax card (NIF)'**
  String get documentPhraseTaxCard;

  /// 21a title while documents are missing.
  ///
  /// In en, this message translates to:
  /// **'Finish your verification'**
  String get providerFinishTitle;

  /// 21a body with one document missing.
  ///
  /// In en, this message translates to:
  /// **'Send your {document} so we can start the review. It usually takes one to two days.'**
  String providerMissingOne(String document);

  /// 21a body with several missing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Send your remaining {count} documents so we can start the review. It usually takes one to two days.}}'**
  String providerMissingMany(int count);

  /// 21a title once everything is sent.
  ///
  /// In en, this message translates to:
  /// **'Profile under review'**
  String get providerReviewTitle;

  /// 21a body once everything is sent.
  ///
  /// In en, this message translates to:
  /// **'We are checking your documents. It usually takes one to two days — we will let you know.'**
  String get providerReviewBody;

  /// 21b title.
  ///
  /// In en, this message translates to:
  /// **'Profile not approved'**
  String get providerRejectedTitle;

  /// 21b body, one refused document.
  ///
  /// In en, this message translates to:
  /// **'Your {document} was not accepted. Send a new one to go back into review.'**
  String providerRejectedOne(String document);

  /// 21b body, several refused.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} documents were not accepted. Send new ones to go back into review.}}'**
  String providerRejectedMany(int count);

  /// Verification step.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get providerStepAccount;

  /// Verification step.
  ///
  /// In en, this message translates to:
  /// **'Documents sent'**
  String get providerStepDocuments;

  /// Verification step while some are missing.
  ///
  /// In en, this message translates to:
  /// **'Documents sent · {sent} of {total}'**
  String providerStepDocumentsCount(int sent, int total);

  /// Verification step.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get providerStepUnderReview;

  /// Verification step on 21b.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get providerStepReviewed;

  /// Verification step.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get providerStepApproved;

  /// Verification step on 21b.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get providerStepNotApproved;

  /// Heading on 21a/21b/08d.
  ///
  /// In en, this message translates to:
  /// **'Your documents'**
  String get providerYourDocuments;

  /// 21b and 08d button.
  ///
  /// In en, this message translates to:
  /// **'Resubmit documents'**
  String get providerResubmit;

  /// 21a button, ID card missing.
  ///
  /// In en, this message translates to:
  /// **'Upload ID card'**
  String get providerUploadNationalId;

  /// 21a button, register missing.
  ///
  /// In en, this message translates to:
  /// **'Upload register card'**
  String get providerUploadRegister;

  /// 21a button, tax card missing.
  ///
  /// In en, this message translates to:
  /// **'Upload tax card'**
  String get providerUploadTaxCard;

  /// P3 title.
  ///
  /// In en, this message translates to:
  /// **'Decline this request ?'**
  String get declineTitle;

  /// P3 body.
  ///
  /// In en, this message translates to:
  /// **'{name} is told straight away and the date is released on your calendar. You cannot undo this — a new request would be needed.'**
  String declineBody(String name);

  /// P3 field label.
  ///
  /// In en, this message translates to:
  /// **'Why are you declining ?'**
  String get declineReasonLabel;

  /// P3 field placeholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Already booked that day'**
  String get declineReasonHint;

  /// Under the P3 field.
  ///
  /// In en, this message translates to:
  /// **'{name} will see this reason.'**
  String declineReasonHelper(String name);

  /// P3 note.
  ///
  /// In en, this message translates to:
  /// **'The date opens up for other clients as soon as you decline.'**
  String get declineNote;

  /// P3 destructive button.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get declineConfirm;

  /// P3 cancel button.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get declineGoBack;

  /// 08d title.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get resubmitTitle;

  /// 08d body.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One document was not accepted. Upload it again and your services go back for review.} other{{count} documents were not accepted. Upload them again and your services go back for review.}}'**
  String resubmitBody(int count);

  /// 08d body when nothing was refused, only missing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One document is still missing. Send it and your profile goes into review.} other{{count} documents are still missing. Send them and your profile goes into review.}}'**
  String resubmitMissingBody(int count);

  /// 08d when nothing needs sending.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix: your documents are with the reviewers.'**
  String get resubmitNothingBody;

  /// 08d reason card badge.
  ///
  /// In en, this message translates to:
  /// **'Rejected {date}'**
  String resubmitRejectedOn(String date);

  /// 08d reason card label.
  ///
  /// In en, this message translates to:
  /// **'Reason given'**
  String get resubmitReasonGiven;

  /// 08d reason card when the reviewer gave no reason.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get resubmitNoReason;

  /// 08d upload slot.
  ///
  /// In en, this message translates to:
  /// **'Upload a new file'**
  String get resubmitUploadNew;

  /// Under the 08d upload slot.
  ///
  /// In en, this message translates to:
  /// **'PDF or image, max {mb} MB'**
  String resubmitHint(int mb);

  /// Swap the picked file on 08d.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get resubmitChange;

  /// Screen-reader label of the x on a picked file.
  ///
  /// In en, this message translates to:
  /// **'Remove this file'**
  String get resubmitRemove;

  /// 08d secondary button.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get resubmitNotNow;

  /// Toast after 08d.
  ///
  /// In en, this message translates to:
  /// **'Documents sent — we will review them within a day or two.'**
  String get resubmitSent;

  /// Toast when an 08d upload fails.
  ///
  /// In en, this message translates to:
  /// **'A file did not go through. Nothing else was lost — try again.'**
  String get resubmitFailed;

  /// 14's empty state for a provider.
  ///
  /// In en, this message translates to:
  /// **'When a client writes to you, the conversation appears here.'**
  String get messagesEmptyBodyProvider;

  /// 18f link at the end of the form.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetDelete;

  /// Sheet title before deleting the budget.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget ?'**
  String get budgetDeleteTitle;

  /// Sheet body before deleting the budget.
  ///
  /// In en, this message translates to:
  /// **'Your budget and all its expense lines are removed for good. The bookings they were linked to are not touched.'**
  String get budgetDeleteBody;

  /// Destructive button of the delete-budget sheet.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetDeleteConfirm;

  /// Toast after deleting the budget.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted.'**
  String get budgetDeleted;

  /// Toast when the server has no delete route yet.
  ///
  /// In en, this message translates to:
  /// **'Deleting a budget is not available yet.'**
  String get budgetDeleteUnavailable;
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
