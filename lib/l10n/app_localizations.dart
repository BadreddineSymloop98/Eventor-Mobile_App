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

  /// Heading over the photograph on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// Line under the login heading.
  ///
  /// In en, this message translates to:
  /// **'Log in to pick up where you left off.'**
  String get loginSubtitle;

  /// Link under the login form, for a user who cannot remember their password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password ?'**
  String get forgotPassword;

  /// Question beside the create-account link at the bottom of the login screen.
  ///
  /// In en, this message translates to:
  /// **'New to Eventor ?'**
  String get loginNewPrompt;

  /// Heading shown on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Line under the logo on the splash screen, describing what the app is for.
  ///
  /// In en, this message translates to:
  /// **'Everything your event needs, in one place'**
  String get splashTagline;

  /// Attribution at the very bottom of the splash screen. SYMLOOP is the studio name and is not translated, but the word before it is.
  ///
  /// In en, this message translates to:
  /// **'by SYMLOOP'**
  String get splashByline;

  /// Title of the first onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Every service your event needs'**
  String get onboardingServicesTitle;

  /// Body of the first onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Photographers, venues, caterers, DJs, florists and decorators, all in one place.'**
  String get onboardingServicesDescription;

  /// Title of the second onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Compare, then book with confidence'**
  String get onboardingCompareTitle;

  /// Body of the second onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Real reviews, clear prices and open dates. Message a provider before you commit.'**
  String get onboardingCompareDescription;

  /// Title of the third onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Keep the whole event on track'**
  String get onboardingTrackTitle;

  /// Body of the third onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Follow every booking and watch your budget as the day comes together.'**
  String get onboardingTrackDescription;

  /// Heading on the welcome screen, shown after onboarding.
  ///
  /// In en, this message translates to:
  /// **'Let’s get started'**
  String get welcomeTitle;

  /// Body under the welcome heading, explaining the two choices below it.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start booking or log in if you have been here before.'**
  String get welcomeSubtitle;

  /// Offers account creation. The primary button on the welcome screen, and the link at the foot of the login form.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// Secondary button on the welcome screen, which goes to the login form.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeHaveAccount;

  /// Heading on the role selection screen. The space before the question mark is the design's own.
  ///
  /// In en, this message translates to:
  /// **'How will you use Eventor ?'**
  String get roleSelectionTitle;

  /// Warning under the role selection heading that the choice is permanent.
  ///
  /// In en, this message translates to:
  /// **'This shapes your whole experience in the app. It cannot be changed later.'**
  String get roleSelectionSubtitle;

  /// Title of the role for someone booking services for their own event.
  ///
  /// In en, this message translates to:
  /// **'I\'m planning an event'**
  String get rolePlannerTitle;

  /// One-line description of the event planner role.
  ///
  /// In en, this message translates to:
  /// **'Find and book my event team'**
  String get rolePlannerDescription;

  /// Title of the role for someone selling a service on the marketplace.
  ///
  /// In en, this message translates to:
  /// **'I offer a service'**
  String get roleProviderTitle;

  /// One-line description of the service provider role.
  ///
  /// In en, this message translates to:
  /// **'List my services and manage bookings'**
  String get roleProviderDescription;

  /// Title of the role for someone requesting events for an organisation.
  ///
  /// In en, this message translates to:
  /// **'I represent an institution'**
  String get roleInstitutionTitle;

  /// One-line description of the institution role.
  ///
  /// In en, this message translates to:
  /// **'Submit and track event requests'**
  String get roleInstitutionDescription;

  /// Button that confirms a choice and moves to the next step. Named with a suffix because `continue` is a Dart keyword.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Screen-reader label for the back control in a screen's top bar.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// Heading in the register screen's header. Stays visible as the header collapses.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// Body under the register heading. Hidden once the header collapses.
  ///
  /// In en, this message translates to:
  /// **'Just a few details, then you can start booking your event team.'**
  String get registerSubtitle;

  /// Button that submits the register form.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerCreateAccount;

  /// Toast shown after the account has been created.
  ///
  /// In en, this message translates to:
  /// **'Account creation successful'**
  String get registerSuccess;

  /// First half of the terms line under the register form, before the linked text. The trailing space is deliberate.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our '**
  String get registerTermsPrefix;

  /// The linked portion of the terms line, shown in the brand colour.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Policy'**
  String get registerTermsLink;

  /// Question beside the log in link at the bottom of the register screen.
  ///
  /// In en, this message translates to:
  /// **'Already have an account ?'**
  String get registerHasAccountPrompt;

  /// Link that leaves the register form for the login form.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Label of the full name field.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get nameLabel;

  /// Label of the phone number field.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Validation message shown when the name field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get nameRequired;

  /// Validation message shown when the name is below the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use at least {count} character.} other{Use at least {count} characters.}}'**
  String nameTooShort(int count);

  /// Validation message shown when the phone field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get phoneRequired;

  /// Validation message shown when the phone number is not a whole local number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Enter {count} digit, starting with {leadingDigit}.} other{Enter {count} digits, starting with {leadingDigit}.}}'**
  String phoneInvalid(int count, String leadingDigit);

  /// Heading over the photograph on the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// Line under the forgot-password heading, explaining what the field is for.
  ///
  /// In en, this message translates to:
  /// **'Enter the email on your account and we will send you a reset link.'**
  String get forgotPasswordSubtitle;

  /// Button that submits the forgot-password form.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// Link under the send button that returns to the login form.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get backToLogIn;

  /// Heading over the photograph on the code-entry screen.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyCodeTitle;

  /// Line under the code-entry heading, naming where the code was sent.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {destination}.'**
  String verifyCodeSubtitle(String destination);

  /// Stands in for the phone number or address when the screen was opened without one.
  ///
  /// In en, this message translates to:
  /// **'your number'**
  String get verifyCodeDestinationFallback;

  /// Label above the row of digit boxes.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeLabel;

  /// Button that submits the verification code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyAction;

  /// Question beside the resend link.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code ?'**
  String get verifyNoCodePrompt;

  /// Shown in place of the resend line while the wait for another code is still running. Counts down once a second.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You can resend after {count} second.} other{You can resend after {count} seconds.}}'**
  String verifyResendCountdown(int count);

  /// Link that asks for a new verification code.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Toast shown after a new verification code has been requested.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way'**
  String get verifyCodeResent;

  /// Screen-reader label for the EN / Arabic switch. The two options label themselves, each in its own script.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitchLabel;

  /// Button that leaves onboarding without reading it.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Button that advances to the next onboarding section.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Button on the last onboarding section, which finishes the flow. Replaces `next` there so the final step reads as an ending rather than as one more page.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Screen-reader announcement of the position within a paged flow. Not shown visually.
  ///
  /// In en, this message translates to:
  /// **'Section {current} of {total}'**
  String sectionProgress(int current, int total);

  /// Label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Tooltip and screen-reader label of the button that reveals the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip and screen-reader label of the button that re-hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Instruction under the full name field, stating the minimum length and the characters it refuses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{At least {count} letter, no digits or symbols.} other{At least {count} letters, no digits or symbols.}}'**
  String nameHint(int count);

  /// Instruction under the phone field, stating the exact length of a local number and the digit it opens with.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} digit, starting with {leadingDigit}.} other{{count} digits, starting with {leadingDigit}.}}'**
  String phoneHint(int count, String leadingDigit);

  /// Instruction under the email field, describing the expected format.
  ///
  /// In en, this message translates to:
  /// **'Example: name@example.com'**
  String get emailHint;

  /// Instruction under the password field, stating the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{At least {count} character, no spaces.} other{At least {count} characters, no spaces.}}'**
  String passwordHint(int count);

  /// Validation message shown when the email field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get emailRequired;

  /// Validation message shown when the email is not a plausible address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address, like name@example.com.'**
  String get emailInvalid;

  /// Validation message shown when the password field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// Validation message shown when the password is below the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use at least {count} character.} other{Use at least {count} characters.}}'**
  String passwordTooShort(int count);

  /// App bar title of the screen shown for an unrecognised route.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get unknownRouteTitle;

  /// Body of the screen shown for an unrecognised route.
  ///
  /// In en, this message translates to:
  /// **'No route defined for \"{routeName}\".'**
  String unknownRouteMessage(String routeName);

  /// Fallback message for a failure the app has no specific wording for.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// Message shown when writing to on-device storage failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes on this device.'**
  String get errorStorage;
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
