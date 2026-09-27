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

  /// Home app bar title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Greeting on the placeholder home.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// Body of the placeholder home.
  ///
  /// In en, this message translates to:
  /// **'Your home screen is being built. You are signed in.'**
  String get homeComingSoon;

  /// Provider pending card title.
  ///
  /// In en, this message translates to:
  /// **'Your profile is under review'**
  String get homeProviderPendingTitle;

  /// Provider pending card body.
  ///
  /// In en, this message translates to:
  /// **'You can browse the app. Services go live once your documents are approved.'**
  String get homeProviderPendingBody;

  /// Provider rejected card title.
  ///
  /// In en, this message translates to:
  /// **'Some documents need your attention'**
  String get homeProviderRejectedTitle;

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

  /// Shown instead of a star score for something nobody has reviewed yet.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get ratingNew;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;
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
