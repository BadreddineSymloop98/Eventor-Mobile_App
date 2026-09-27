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
  String get priceOnQuote => 'On quote';

  @override
  String get ratingNew => 'New';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get stateErrorTitle => 'We could not load this';

  @override
  String get stateRetry => 'Try again';

  @override
  String get verifiedProvider => 'Verified provider';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Read less';

  @override
  String get seeAll => 'See all';

  @override
  String seeAllCount(int count) {
    return 'See all $count';
  }

  @override
  String get noLongerAvailable => 'No longer available';

  @override
  String get undo => 'Undo';

  @override
  String get favouriteSave => 'Save';

  @override
  String get favouriteSaved => 'Saved';

  @override
  String get favouriteFailed =>
      'We could not update your favourites. Try again.';

  @override
  String get favouriteRemoved => 'Removed from favourites';

  @override
  String get priceUnitPerEvent => 'per event';

  @override
  String get priceUnitPerHour => 'per hour';

  @override
  String get priceUnitPerPerson => 'per person';

  @override
  String get priceUnitPerDay => 'per day';

  @override
  String get eventTypeWedding => 'Wedding';

  @override
  String get eventTypeEngagement => 'Engagement';

  @override
  String get eventTypeHenna => 'Henna';

  @override
  String get eventTypeBirthday => 'Birthday';

  @override
  String get eventTypeCircumcision => 'Circumcision';

  @override
  String get eventTypeGraduation => 'Graduation';

  @override
  String get eventTypeCorporate => 'Corporate';

  @override
  String get eventTypeConference => 'Conference';

  @override
  String get eventTypeOther => 'Other';

  @override
  String get calendarSelected => 'Selected';

  @override
  String get calendarAvailable => 'Available';

  @override
  String get calendarBooked => 'Fully booked';

  @override
  String get calendarUnavailable => 'Unavailable';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarMinNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dates need at least $count days\' notice.',
      one: 'Dates need at least $count day\'s notice.',
    );
    return '$_temp0';
  }

  @override
  String get notAcceptingTitle => 'Not taking new bookings';

  @override
  String get notAcceptingBody => 'Messages are still open';

  @override
  String get sendMessage => 'Send a message';

  @override
  String get messageProvider => 'Message the provider';

  @override
  String get requestBooking => 'Request booking';

  @override
  String get requestPack => 'Request pack';

  @override
  String get packSave => 'Save';

  @override
  String basedOnReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count reviews',
      one: 'Based on $count review',
    );
    return '$_temp0';
  }

  @override
  String bookedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Booked $count times',
      one: 'Booked once',
      zero: 'Not booked yet',
    );
    return '$_temp0';
  }

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '$count service',
    );
    return '$_temp0';
  }

  @override
  String packBy(String name) {
    return 'by $name';
  }

  @override
  String photoCounterLabel(int index, int count) {
    return 'Photo $index of $count';
  }

  @override
  String get backLabelOnPhoto => 'Back';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get tabComingSoonTitle => 'Coming soon';

  @override
  String get tabComingSoonBody => 'This part of Eventor is on its way.';

  @override
  String get profileFavourites => 'Favorites';

  @override
  String get profileMoreSoon => 'More settings are coming soon.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get chooseCity => 'Choose your city';

  @override
  String get chooseCitySubtitle =>
      'We show services that cover it. Only wilayas open on Eventor are listed.';

  @override
  String get cityChangeFailed => 'We could not change your city. Try again.';

  @override
  String get homeSearchHint => 'Search a service or a provider';

  @override
  String get homeFiltersLabel => 'Filters';

  @override
  String get homeNotificationsLabel => 'Notifications';

  @override
  String get homeNotificationsUnread => 'Notifications, unread';

  @override
  String get homeYourBookings => 'Your bookings';

  @override
  String get homeYourBudget => 'Your budget';

  @override
  String get budgetDetails => 'Details';

  @override
  String get budgetOf => 'of';

  @override
  String get budgetPlanned => 'planned';

  @override
  String budgetBooked(int booked, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '$count service',
    );
    return '$booked of $_temp0 booked';
  }

  @override
  String get budgetEmptyTitle => 'Plan your budget';

  @override
  String get budgetEmptyBody =>
      'Set a total, then track what each service really costs. Only you can see it.';

  @override
  String get budgetCreate => 'Create a budget';

  @override
  String get homeReadyPacks => 'Ready Packs';

  @override
  String get homeServicesNearYou => 'Services near you';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersClose => 'Close filters';

  @override
  String get filtersSortBy => 'Sort by';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortPriceLow => 'Lowest price';

  @override
  String get sortPriceHigh => 'Highest price';

  @override
  String get sortRating => 'Top rated';

  @override
  String get sortPopular => 'Most popular';

  @override
  String get sortNewest => 'Newest';

  @override
  String get filtersCategory => 'Category';

  @override
  String get filtersWilaya => 'Wilaya';

  @override
  String get filtersAllWilayas => 'All wilayas';

  @override
  String get filtersBudget => 'Budget';

  @override
  String get filtersEventDate => 'Event date';

  @override
  String get filtersEventDateAny => 'Any date';

  @override
  String get filtersEventDateHint => 'Only providers free on that day.';

  @override
  String get filtersEventDateClear => 'Clear the date';

  @override
  String get filtersRating => 'Rating';

  @override
  String get filtersRatingAny => 'Any';

  @override
  String get filtersSaved => 'Saved';

  @override
  String get filtersFavouritesOnly => 'Favorites only';

  @override
  String get filtersClearAll => 'Clear all';

  @override
  String filtersShowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count services',
      one: 'Show $count service',
      zero: 'No services',
    );
    return '$_temp0';
  }

  @override
  String get filtersShow => 'Show services';

  @override
  String wilayaDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done · $count selected',
      one: 'Done · $count selected',
      zero: 'Done',
    );
    return '$_temp0';
  }

  @override
  String get wilayaClear => 'Clear';

  @override
  String get eventDateSheetTitle => 'Pick your event date';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClear => 'Clear';

  @override
  String searchRemoveRecent(String query) {
    return 'Remove $query';
  }

  @override
  String get searchBrowseCategories => 'Browse categories';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '$count service',
      zero: 'No services',
    );
    return '$_temp0';
  }

  @override
  String resultsSortChip(String order) {
    return 'Sort · $order';
  }

  @override
  String resultsFiltersChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filters · $count',
      zero: 'Filters',
    );
    return '$_temp0';
  }

  @override
  String get resultsAllServices => 'All services';

  @override
  String get resultsEmptyTitle => 'Nothing matches those filters';

  @override
  String get resultsEmptyBody =>
      'Try a wider budget, another wilaya or fewer filters.';

  @override
  String resultsEmptySearch(String query) {
    return 'No services for “$query”.';
  }

  @override
  String get resultsClearFilters => 'Clear all filters';

  @override
  String get resultsLoadMoreFailed => 'We could not load more results.';

  @override
  String resultsRemoveFilter(String label) {
    return 'Remove filter $label';
  }

  @override
  String get filterChipFavourites => 'Favorites';

  @override
  String get serviceAbout => 'About this service';

  @override
  String get serviceGoodToKnow => 'Good to know';

  @override
  String serviceCancellation(String policy) {
    return 'Provider\'s policy: $policy';
  }

  @override
  String get serviceExtras => 'Extras';

  @override
  String get servicePickDate => 'Pick a date';

  @override
  String get selectedDateLabel => 'Your date';

  @override
  String get calendarConfirmNote =>
      'The provider confirms the exact time after your request.';

  @override
  String get monthLoadFailed => 'We could not load this month.';

  @override
  String get serviceReviews => 'Reviews';

  @override
  String get serviceNoReviews => 'No reviews yet';

  @override
  String get servicePacksFromProvider => 'Packs from this provider';

  @override
  String get serviceReport => 'Report this service';

  @override
  String upToGuests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count guests',
      one: 'Up to $count guest',
    );
    return '$_temp0';
  }

  @override
  String yearsInBusiness(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years in business',
      one: '$count year in business',
    );
    return '$_temp0';
  }

  @override
  String repliesIn(String time) {
    return 'Usually replies in $time';
  }

  @override
  String get detailGoneTitle => 'This is no longer available';

  @override
  String get detailGoneBody => 'It may have been removed by the provider.';

  @override
  String get detailGoneBack => 'Go back';

  @override
  String get profileChecked => 'What we checked';

  @override
  String get checkIdentity => 'Identity verified';

  @override
  String get checkRegistration => 'Registered activity';

  @override
  String get checkReplyTime => 'Replies quickly';

  @override
  String get profileAbout => 'About';

  @override
  String get profileServices => 'Services';

  @override
  String get profileWhereTheyWork => 'Where they work';

  @override
  String profileLanguages(String languages) {
    return 'Speaks $languages';
  }

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profileReport => 'Report this provider';

  @override
  String get langAr => 'Arabic';

  @override
  String get langFr => 'French';

  @override
  String get langEn => 'English';

  @override
  String statReviewsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reviews',
      one: 'review',
    );
    return '$_temp0';
  }

  @override
  String statCompletedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bookings completed',
      one: 'booking completed',
    );
    return '$_temp0';
  }

  @override
  String statYearsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years in business',
      one: 'year in business',
    );
    return '$_temp0';
  }

  @override
  String get packsSubtitle =>
      'Bundles put together by one provider — a single price, everything included.';

  @override
  String get packsAll => 'All';

  @override
  String packsSortedBy(String order) {
    return 'Sorted by $order';
  }

  @override
  String get packOrderSavings => 'best savings';

  @override
  String get packOrderPriceAsc => 'lowest price';

  @override
  String get packOrderPriceDesc => 'highest price';

  @override
  String get packOrderRating => 'top rated';

  @override
  String get packOrderPopular => 'most popular';

  @override
  String get packsEmptyTitle => 'No packs here yet';

  @override
  String get packsEmptyBody => 'Try another event type.';

  @override
  String packBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ready Pack · $count services',
      one: 'Ready Pack · $count service',
    );
    return '$_temp0';
  }

  @override
  String packBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Booked $count times',
      one: 'Booked once',
      zero: 'Not booked yet',
    );
    return '$_temp0';
  }

  @override
  String get packVersus => 'versus booking separately';

  @override
  String get packInside => 'What is inside';

  @override
  String get packBookedSeparately => 'Booked separately';

  @override
  String get packCalendarHint =>
      'Only days when every service in the pack is free.';

  @override
  String get packAbout => 'About this pack';

  @override
  String packAvailableIn(String wilayas) {
    return 'Available in $wilayas';
  }

  @override
  String packAllServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'all $count services',
      one: '$count service included',
    );
    return '$_temp0';
  }

  @override
  String get favouritesTitle => 'Favorites';

  @override
  String get favouritesServices => 'Services';

  @override
  String get favouritesPacks => 'Packs';

  @override
  String get favouritesAll => 'All';

  @override
  String get favouritesEmptyServices => 'No saved services yet';

  @override
  String get favouritesEmptyPacks => 'No saved packs yet';

  @override
  String get favouritesEmptyBody =>
      'Tap the heart on a service or a pack to keep it here.';

  @override
  String get favouritesExplore => 'Explore';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';
}
