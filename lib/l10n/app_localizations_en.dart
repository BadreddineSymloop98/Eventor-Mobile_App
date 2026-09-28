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

  @override
  String get offlineTitle => 'You are offline';

  @override
  String get offlineRetry => 'Retry';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesSearchHint => 'Search a conversation';

  @override
  String get messagesFilterAll => 'All';

  @override
  String get messagesFilterUnread => 'Unread';

  @override
  String get messagesFilterBookings => 'Bookings';

  @override
  String get messagesEmptyTitle => 'No messages yet';

  @override
  String get messagesEmptyBody =>
      'When you write to a provider, your conversations appear here.';

  @override
  String get messagesEmptyAction => 'Find a provider';

  @override
  String get messagesUnreadEmpty => 'You\'re all caught up';

  @override
  String get messagesBookingsEmpty => 'No booking conversations yet';

  @override
  String messagesNoMatch(String query) {
    return 'No conversations match \"$query\"';
  }

  @override
  String get offlineMessagesBody =>
      'These are your last messages. New ones arrive when you reconnect.';

  @override
  String chatDispute(String reference) {
    return 'Dispute · $reference';
  }

  @override
  String get chatDisputeNoRef => 'Dispute';

  @override
  String get chatSupport => 'Eventor support';

  @override
  String get chatDeletedAccount => 'Deleted account';

  @override
  String get chatPhoto => 'Photo';

  @override
  String get chatRemoved => 'Removed by Eventor';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String messagesUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String get chatComposerHint => 'Write a message';

  @override
  String get chatComposerDisputeHint => 'Write to both parties';

  @override
  String get chatClosed =>
      'This conversation was closed by Eventor. You can still read it.';

  @override
  String get chatOtherBlocked =>
      'This account is no longer active. You can still read the conversation.';

  @override
  String get chatMaskedNote => 'Number hidden until the booking is accepted';

  @override
  String get chatNotSent => 'Not sent · Tap to retry';

  @override
  String get chatNewMessages => 'New messages';

  @override
  String chatSayHello(String name) {
    return 'Say hello to $name';
  }

  @override
  String get chatToday => 'Today';

  @override
  String chatGroupSubtitle(String name) {
    return 'You, $name and Eventor support';
  }

  @override
  String get chatViewProfile => 'View profile';

  @override
  String chatReportUser(String name) {
    return 'Report $name';
  }

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatReportMessage => 'Report';

  @override
  String get photoReload => 'Tap to reload';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportReasonInappropriate => 'Inappropriate';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonContact => 'Sharing contact details';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonFake => 'Fake or scam';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportNoteHint => 'Add a note (optional)';

  @override
  String get reportSend => 'Send report';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAttach => 'Add a photo';

  @override
  String get chatMore => 'More options';

  @override
  String get chatRemoveAttachment => 'Remove photo';

  @override
  String get chatSending => 'Sending';

  @override
  String get chatOlderFailed => 'Could not load older messages';

  @override
  String get photoViewerClose => 'Close';

  @override
  String get chatUnavailable => 'This conversation is no longer available';

  @override
  String get chatCopied => 'Copied';

  @override
  String get chatPhotoNeedsText => 'Send a message first';

  @override
  String photoTooLarge(int mb) {
    return 'This photo is larger than $mb MB';
  }

  @override
  String get photoWrongType => 'Use a JPEG, PNG, WebP or HEIC photo';

  @override
  String get reportSent => 'Thanks — we\'ll look into it';

  @override
  String get reportAlready => 'You already reported this';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAll => 'Mark all read';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsThisWeek => 'This week';

  @override
  String get notificationsEarlier => 'Earlier';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody =>
      'Booking updates, messages and reminders will show up here.';

  @override
  String get notificationUnread => 'Unread';

  @override
  String get offlineNotificationsBody =>
      'These are your last notifications. New ones arrive when you reconnect.';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetEdit => 'Edit';

  @override
  String get budgetCreateIntroTitle => 'Plan your event budget';

  @override
  String get budgetEditIntroTitle => 'Edit your budget';

  @override
  String get budgetEditIntroBody =>
      'Changing the total leaves your expense lines untouched. Only you can see this.';

  @override
  String get budgetNameLabel => 'Budget name';

  @override
  String get budgetNameHint => 'e.g. Our wedding';

  @override
  String get budgetEventDateLabel => 'Event date';

  @override
  String get budgetEventDateClear => 'Remove the date';

  @override
  String get optionalField => 'Optional';

  @override
  String get budgetTotalLabel => 'Total budget';

  @override
  String get amountFieldSuffix => 'DA';

  @override
  String get budgetCreateAction => 'Create budget';

  @override
  String get budgetSaveChanges => 'Save changes';

  @override
  String get budgetSpent => 'spent';

  @override
  String budgetAllocatedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DA allocated across $count lines',
      one: 'DA allocated across 1 line',
      zero: 'DA allocated across 0 lines',
    );
    return '$_temp0';
  }

  @override
  String get budgetRemaining => 'Remaining';

  @override
  String get budgetServicesBooked => 'Services booked';

  @override
  String budgetBookedOf(int booked, int count) {
    return '$booked of $count';
  }

  @override
  String get budgetExpenseLines => 'Expense lines';

  @override
  String get budgetActualVsPlanned => 'Actual vs planned';

  @override
  String get budgetNotBookedYet => 'Not booked yet';

  @override
  String get budgetLineOnPlan => 'on plan';

  @override
  String get budgetLinePlanned => 'planned';

  @override
  String get budgetNoLinesTitle => 'No expense lines yet';

  @override
  String get budgetNoLinesBody =>
      'Add a line for each service you are paying for, and the remaining amount keeps itself up to date.';

  @override
  String get budgetAddExpense => 'Add an expense';

  @override
  String get budgetOverTitle => 'You are over your budget';

  @override
  String get budgetOverBody =>
      'You have spent more than your total. Raise the budget, or trim a line.';

  @override
  String get expenseNewTitle => 'New expense line';

  @override
  String get expenseNewBody =>
      'A name and a planned amount are enough to start. Everything else can wait.';

  @override
  String get expenseLineTitle => 'Expense line';

  @override
  String get expenseEditBody =>
      'Linking a booking shows who it is with and counts it as booked. You still enter what you actually paid.';

  @override
  String get expenseDelete => 'Delete';

  @override
  String get expenseCategoryLabel => 'Category';

  @override
  String get expenseCategoryPlaceholder => 'Choose a category';

  @override
  String get expenseNoCategory => 'No category';

  @override
  String get expenseLabelLabel => 'Label';

  @override
  String get expenseLabelHint => 'e.g. Wedding cake';

  @override
  String get expensePlannedLabel => 'Planned amount';

  @override
  String get expenseSpentLabel => 'Spent so far';

  @override
  String get expenseBookingLabel => 'Linked booking';

  @override
  String get expenseNotLinked => 'Not linked';

  @override
  String get expenseAddLine => 'Add line';

  @override
  String get expenseSaveLine => 'Save line';

  @override
  String get expenseFullTitle => 'This budget is full';

  @override
  String get expenseFullBody =>
      'You have reached the maximum number of expense lines. Delete one you no longer need, or merge two into a single line.';

  @override
  String get expenseDeleteTitle => 'Delete this line ?';

  @override
  String get expenseDeleteBody =>
      'It disappears from your budget and the remaining amount is recalculated. The booking it is linked to is not touched.';

  @override
  String get expenseDeleteSpent => 'Spent';

  @override
  String get expenseDeletePlanned => 'Planned';

  @override
  String get expenseDeleteConfirm => 'Delete line';

  @override
  String get expenseDeleteKeep => 'Keep it';

  @override
  String get linkBookingTitle => 'Link a booking';

  @override
  String get linkBookingIntro =>
      'Only your own bookings appear here. Linking one fills in the provider and counts this line in “services booked”.';

  @override
  String get linkBookingNoneBody => 'This line is not tied to any booking';

  @override
  String linkBookingUsedOn(String label) {
    return 'On “$label”';
  }

  @override
  String get linkBookingNote =>
      'A booking already used on another line is shown greyed out, so the same amount is never counted twice.';

  @override
  String get linkBookingAction => 'Link booking';

  @override
  String get linkBookingEmptyTitle => 'No bookings yet';

  @override
  String get linkBookingEmptyBody =>
      'Once you book a service, you can link it to this line.';

  @override
  String get discardTitle => 'Discard your changes ?';

  @override
  String get discardBody => 'What you changed here will not be saved.';

  @override
  String get discardConfirm => 'Discard';

  @override
  String get discardKeep => 'Keep editing';

  @override
  String get navRequests => 'Requests';

  @override
  String get navServices => 'Services';

  @override
  String get profileDocuments => 'My documents';

  @override
  String get providerAccepting => 'Accepting bookings';

  @override
  String get providerPaused => 'Bookings paused';

  @override
  String get providerAcceptingHint => 'Clients can send you new requests.';

  @override
  String get providerPausedHint =>
      'No new requests until you turn it back on. Your services stay visible.';

  @override
  String get providerAvailabilityTitle => 'Your availability';

  @override
  String get providerAvailabilityBody =>
      'Pausing keeps the bookings you already have.';

  @override
  String get providerNowAccepting => 'You are accepting bookings again.';

  @override
  String get providerNowPaused => 'New bookings are paused.';

  @override
  String get providerStatRequests => 'Requests';

  @override
  String get providerStatUpcoming => 'Upcoming';

  @override
  String get providerStatServices => 'Services';

  @override
  String get providerRequestsTitle => 'Booking requests';

  @override
  String get providerNoRequestsTitle => 'No new requests';

  @override
  String providerNoRequestsBody(int hours) {
    return 'New booking requests show up here, and you have $hours h to answer each one.';
  }

  @override
  String get providerNoRequestsPausedBody =>
      'Your bookings are paused, so clients cannot send new requests.';

  @override
  String providerReplyWithin(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'reply within $hours h',
      zero: 'reply now',
    );
    return '$_temp0';
  }

  @override
  String providerAccepted(String name) {
    return 'Request from $name accepted.';
  }

  @override
  String get providerDeclined => 'Request declined.';

  @override
  String get providerUpcomingTitle => 'Upcoming bookings';

  @override
  String get providerNoUpcoming => 'No confirmed bookings ahead yet.';

  @override
  String get providerAvailabilityCalendar => 'Availability calendar';

  @override
  String get providerServicesTitle => 'Your services';

  @override
  String get providerManage => 'Manage';

  @override
  String get providerAddService => 'Add a service';

  @override
  String get providerServicesAfterApproval =>
      'Available once your profile is approved.';

  @override
  String get serviceStatusPublished => 'Published';

  @override
  String get serviceStatusDraft => 'Draft';

  @override
  String get serviceStatusHidden => 'Hidden';

  @override
  String get documentStateInReview => 'In review';

  @override
  String get documentStateApproved => 'Approved';

  @override
  String get documentStateRejected => 'Rejected';

  @override
  String get documentStateMissing => 'Missing';

  @override
  String get documentRegisterShort => 'Register or artisan card';

  @override
  String get documentPhraseNationalId => 'national ID card';

  @override
  String get documentPhraseRegister => 'register or artisan card';

  @override
  String get documentPhraseTaxCard => 'tax card (NIF)';

  @override
  String get providerFinishTitle => 'Finish your verification';

  @override
  String providerMissingOne(String document) {
    return 'Send your $document so we can start the review. It usually takes one to two days.';
  }

  @override
  String providerMissingMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Send your remaining $count documents so we can start the review. It usually takes one to two days.',
    );
    return '$_temp0';
  }

  @override
  String get providerReviewTitle => 'Profile under review';

  @override
  String get providerReviewBody =>
      'We are checking your documents. It usually takes one to two days — we will let you know.';

  @override
  String get providerRejectedTitle => 'Profile not approved';

  @override
  String providerRejectedOne(String document) {
    return 'Your $document was not accepted. Send a new one to go back into review.';
  }

  @override
  String providerRejectedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents were not accepted. Send new ones to go back into review.',
    );
    return '$_temp0';
  }

  @override
  String get providerStepAccount => 'Account created';

  @override
  String get providerStepDocuments => 'Documents sent';

  @override
  String providerStepDocumentsCount(int sent, int total) {
    return 'Documents sent · $sent of $total';
  }

  @override
  String get providerStepUnderReview => 'Under review';

  @override
  String get providerStepReviewed => 'Reviewed';

  @override
  String get providerStepApproved => 'Approved';

  @override
  String get providerStepNotApproved => 'Not approved';

  @override
  String get providerYourDocuments => 'Your documents';

  @override
  String get providerResubmit => 'Resubmit documents';

  @override
  String get providerUploadNationalId => 'Upload ID card';

  @override
  String get providerUploadRegister => 'Upload register card';

  @override
  String get providerUploadTaxCard => 'Upload tax card';

  @override
  String get declineTitle => 'Decline this request ?';

  @override
  String declineBody(String name) {
    return '$name is told straight away and the date is released on your calendar. You cannot undo this — a new request would be needed.';
  }

  @override
  String get declineReasonLabel => 'Why are you declining ?';

  @override
  String get declineReasonHint => 'e.g. Already booked that day';

  @override
  String declineReasonHelper(String name) {
    return '$name will see this reason.';
  }

  @override
  String get declineNote =>
      'The date opens up for other clients as soon as you decline.';

  @override
  String get declineConfirm => 'Decline request';

  @override
  String get declineGoBack => 'Go back';

  @override
  String get resubmitTitle => 'Action needed';

  @override
  String resubmitBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents were not accepted. Upload them again and your services go back for review.',
      one: 'One document was not accepted. Upload it again and your services go back for review.',
    );
    return '$_temp0';
  }

  @override
  String resubmitMissingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents are still missing. Send them and your profile goes into review.',
      one: 'One document is still missing. Send it and your profile goes into review.',
    );
    return '$_temp0';
  }

  @override
  String get resubmitNothingBody =>
      'Nothing to fix: your documents are with the reviewers.';

  @override
  String resubmitRejectedOn(String date) {
    return 'Rejected $date';
  }

  @override
  String get resubmitReasonGiven => 'Reason given';

  @override
  String get resubmitNoReason => 'Not accepted';

  @override
  String get resubmitUploadNew => 'Upload a new file';

  @override
  String resubmitHint(int mb) {
    return 'PDF or image, max $mb MB';
  }

  @override
  String get resubmitChange => 'Change';

  @override
  String get resubmitRemove => 'Remove this file';

  @override
  String get resubmitNotNow => 'Not now';

  @override
  String get resubmitSent =>
      'Documents sent — we will review them within a day or two.';

  @override
  String get resubmitFailed =>
      'A file did not go through. Nothing else was lost — try again.';

  @override
  String get messagesEmptyBodyProvider =>
      'When a client writes to you, the conversation appears here.';

  @override
  String get budgetDelete => 'Delete budget';

  @override
  String get budgetDeleteTitle => 'Delete this budget ?';

  @override
  String get budgetDeleteBody =>
      'Your budget and all its expense lines are removed for good. The bookings they were linked to are not touched.';

  @override
  String get budgetDeleteConfirm => 'Delete budget';

  @override
  String get budgetDeleted => 'Budget deleted.';

  @override
  String get budgetDeleteUnavailable =>
      'Deleting a budget is not available yet.';

  @override
  String messagesPreviewMine(String message) {
    return 'You: $message';
  }

  @override
  String get chatClosedPlain =>
      'This conversation is closed. You can still read it.';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get notificationDelete => 'Delete notification';

  @override
  String get providerBlockedTitle => 'Your account is blocked';

  @override
  String get providerBlockedBody =>
      'You cannot receive or answer requests while the block is in place. Your bookings, messages and history are kept.';

  @override
  String get providerBlockedServices =>
      'Your services are hidden from clients while the account is blocked.';

  @override
  String loginBlockedUntil(String date) {
    return 'Blocked until $date.';
  }

  @override
  String get bookingAddress => 'Address (optional)';

  @override
  String get bookingAddressHint => 'Venue, street…';

  @override
  String get bookingAddressLabel => 'Address';

  @override
  String get bookingCancelBooking => 'Cancel booking';

  @override
  String get bookingCancelRequest => 'Cancel request';

  @override
  String get bookingCancellationPolicy => 'Cancellation policy';

  @override
  String get bookingCommune => 'Commune';

  @override
  String get bookingCommunePlaceholder => 'Choose a commune (optional)';

  @override
  String get bookingContact => 'Contact';

  @override
  String get bookingDate => 'Date';

  @override
  String get bookingDateError => 'Pick an available day.';

  @override
  String get bookingDateRefused =>
      'This day can no longer be booked — pick another.';

  @override
  String get bookingDateTime => 'Date and time';

  @override
  String get bookingDetailTitle => 'Booking';

  @override
  String get bookingEventType => 'Event type';

  @override
  String get bookingEventTypeError => 'Pick the type of event.';

  @override
  String get bookingExtras => 'Extras';

  @override
  String get bookingFailedKept =>
      'Nothing was lost — everything you filled in is still here.';

  @override
  String get bookingFailedOffline =>
      'You appear to be offline. Nothing was lost — everything you filled in is still here. Tap Try again when you have a connection.';

  @override
  String get bookingFailedTitle => 'Couldn’t send your request';

  @override
  String get bookingFindSimilar => 'Find similar services';

  @override
  String get bookingFrom => 'From';

  @override
  String get bookingGuests => 'Guests';

  @override
  String get bookingGuestsError =>
      'Add the number of guests — the price is per person.';

  @override
  String get bookingGuestsHelper => 'Helps the provider prepare.';

  @override
  String get bookingLeaveReview => 'Leave a review';

  @override
  String get bookingNoCommune => 'Not specified';

  @override
  String get bookingNoDate => 'No date selected — choose an available day';

  @override
  String get bookingNoTime => 'No time';

  @override
  String get bookingNoWilayas => 'This service lists no wilaya yet.';

  @override
  String get bookingNotAcceptingBody =>
      'They are not taking requests right now. Everything you entered is saved; you can message them meanwhile.';

  @override
  String get bookingNote => 'Note for the provider (optional)';

  @override
  String get bookingNoteHint => 'Anything they should know';

  @override
  String get bookingPackSaving => 'Pack saving';

  @override
  String get bookingPackSection => 'Pack';

  @override
  String get bookingPhoneHidden => 'Hidden';

  @override
  String get bookingPickNewDate => 'Pick a new date';

  @override
  String get bookingPrice => 'Price';

  @override
  String get bookingProposeDate => 'Propose a new date';

  @override
  String get bookingProviderConfirmsTime =>
      'The provider confirms the exact time after your request.';

  @override
  String get bookingReportProblem => 'Report a problem';

  @override
  String get bookingSearchCommune => 'Search a commune';

  @override
  String get bookingSearchWilaya => 'Search a wilaya';

  @override
  String get bookingSend => 'Send request';

  @override
  String get bookingServiceSection => 'Service';

  @override
  String get bookingTakenTitleUndated => 'That date was just taken';

  @override
  String get bookingTime => 'Time';

  @override
  String get bookingTimeHelper =>
      'Optional — the provider confirms the exact time.';

  @override
  String get bookingTimeHelperHourly => 'Needed: the price is per hour.';

  @override
  String get bookingTimeOverline => 'TIME';

  @override
  String get bookingTo => 'To';

  @override
  String get bookingTooSoonBody =>
      'Dates now need more notice. Everything else you entered is saved — pick a later day.';

  @override
  String get bookingTooSoonTitle => 'That date is now too soon';

  @override
  String get bookingTotalCaption => 'total';

  @override
  String get bookingTotalOnSite => 'Total · pay on site';

  @override
  String get bookingTryAgain => 'Try again';

  @override
  String get bookingViewInvoice => 'View invoice';

  @override
  String get bookingWhere => 'Where';

  @override
  String get bookingWilaya => 'Wilaya';

  @override
  String get bookingWilayaError => 'Choose where the event takes place.';

  @override
  String get bookingWilayaPlaceholder => 'Choose a wilaya';

  @override
  String get bookingYourEvent => 'Your event';

  @override
  String get bookingYourNote => 'Your note';

  @override
  String get bookingsEmptyCancelled => 'Nothing cancelled';

  @override
  String get bookingsEmptyCancelledBody =>
      'Cancelled and declined bookings show up here.';

  @override
  String get bookingsEmptyPast => 'No past bookings yet';

  @override
  String get bookingsEmptyPastBody =>
      'Once an event is behind you, it moves here with its invoice.';

  @override
  String get bookingsEmptyPending => 'No requests waiting';

  @override
  String get bookingsEmptyPendingBody =>
      'Requests you send wait here until the provider answers.';

  @override
  String get bookingsEmptyUpcoming => 'No upcoming bookings';

  @override
  String get bookingsEmptyUpcomingBody =>
      'Accepted bookings with the event still ahead show up here.';

  @override
  String get bookingsFindService => 'Find a service';

  @override
  String get bookingsTabCancelled => 'Cancelled';

  @override
  String get bookingsTabPast => 'Past';

  @override
  String get bookingsTabPending => 'Pending';

  @override
  String get bookingsTabUpcoming => 'Upcoming';

  @override
  String get bookingsTitle => 'My bookings';

  @override
  String get cancelBookingConfirm => 'Yes, cancel booking';

  @override
  String get cancelBookingDone => 'Booking cancelled.';

  @override
  String get cancelBookingKeep => 'Keep my booking';

  @override
  String get cancelBookingTitle => 'Cancel this booking?';

  @override
  String get cancelReasonHint => 'A few words for the provider';

  @override
  String get cancelReasonLabel => 'Why are you cancelling?';

  @override
  String get cancelRequestConfirm => 'Yes, cancel request';

  @override
  String get cancelRequestDone => 'Request cancelled.';

  @override
  String get cancelRequestKeep => 'Keep my request';

  @override
  String get cancelRequestTitle => 'Cancel this request?';

  @override
  String get cancelNothingPaid =>
      'Payment is cash on the day, so nothing has been paid through Eventor.';

  @override
  String get cancelledByOtherBody =>
      'You owe nothing — no payment had been made.';

  @override
  String get cancelledByYouTitle => 'You cancelled this booking';

  @override
  String get checkInAllGood => 'All good';

  @override
  String get checkInAllGoodBody =>
      'The service happened as agreed. We close the booking and you can leave a review.';

  @override
  String get checkInCalloutAction => 'Tell us how it went';

  @override
  String get checkInCalloutTitle => 'How did it go?';

  @override
  String get checkInClosed => 'Thanks — the booking is closed.';

  @override
  String get checkInFootnote =>
      'If nothing is reported, the booking closes on its own 3 days after the event.';

  @override
  String get checkInHeading => 'How did it go?';

  @override
  String get checkInNotNow => 'Not now';

  @override
  String get checkInProblem => 'There was a problem';

  @override
  String get checkInProblemBody =>
      'No-show, late, or not what was agreed. We open a dispute and support steps in.';

  @override
  String get checkInTitle => 'After the event';

  @override
  String get contactNoteAccepted =>
      'Phone numbers are shared because this booking is accepted.';

  @override
  String get contactNoteCancelled =>
      'Phone numbers are no longer shared for cancelled bookings.';

  @override
  String get contactNoteCompleted =>
      'Phone numbers stay visible after the event.';

  @override
  String get contactNoteDeclined =>
      'Phone numbers are not shared for declined requests.';

  @override
  String get declinedBody =>
      'Nothing was charged, and nothing is held for you.';

  @override
  String get disputeOpenBody =>
      'Eventor support is looking into it and will write to you in Messages.';

  @override
  String get invoiceBackToBooking => 'Back to booking';

  @override
  String get invoiceBilledTo => 'BILLED TO';

  @override
  String get invoiceBooking => 'BOOKING';

  @override
  String get invoiceDiscount => 'Discount';

  @override
  String get invoiceDownload => 'Download PDF';

  @override
  String get invoiceFrom => 'FROM';

  @override
  String get invoiceOverline => 'INVOICE';

  @override
  String get invoicePaidInCash => 'Paid in cash';

  @override
  String get invoicePayOnTheDay => 'Pay in cash on the day';

  @override
  String get invoiceServiceBy => 'SERVICE BY';

  @override
  String get invoiceSubtotal => 'Subtotal';

  @override
  String get invoiceTitle => 'Invoice';

  @override
  String get invoiceTotalPaid => 'Total paid';

  @override
  String get invoiceTotalToPay => 'Total to pay';

  @override
  String get invoiceVoidedBody =>
      'It was voided when the booking was cancelled. Nothing is owed.';

  @override
  String get invoiceVoidedTitle => 'This invoice is void';

  @override
  String get packBookingContinue => 'Continue';

  @override
  String get packBookingTitle => 'Book this pack';

  @override
  String get packLegendBusy => 'A service is busy';

  @override
  String get packLegendTooSoon => 'Too soon / past';

  @override
  String get packPriceCaption => 'pack price';

  @override
  String get packReviewDatePlace => 'Date and place';

  @override
  String get packReviewPackPrice => 'Pack price';

  @override
  String get packReviewSend => 'Send pack request';

  @override
  String get packReviewTitle => 'Review your pack';

  @override
  String get packReviewYouSave => 'You save';

  @override
  String get problemBehaviour => 'Behaviour';

  @override
  String get problemCancel => 'Cancel';

  @override
  String get problemDamage => 'Damage or safety';

  @override
  String get problemDescriptionHelper =>
      'Eventor support reads this, along with your chat.';

  @override
  String get problemDescriptionHint => 'What happened, and when';

  @override
  String get problemDescriptionLabel => 'What happened?';

  @override
  String get problemDone =>
      'Problem reported. Eventor support will contact you in Messages.';

  @override
  String get problemLate => 'Late or incomplete';

  @override
  String get problemNoShow => 'The provider didn’t come';

  @override
  String get problemNotAsDescribed => 'Not as described';

  @override
  String get problemOther => 'Something else';

  @override
  String get problemPrice => 'Price disagreement';

  @override
  String get problemSubmit => 'Report the problem';

  @override
  String get problemTitle => 'What went wrong?';

  @override
  String get problemTypeLabel => 'What was the problem?';

  @override
  String get proposalCurrent => 'current';

  @override
  String get proposalDecline => 'Decline';

  @override
  String get proposalDeclined => 'You kept the original date.';

  @override
  String get proposalProposed => 'proposed';

  @override
  String get proposalWithdraw => 'Withdraw my proposal';

  @override
  String get proposalWithdrawn =>
      'Proposal withdrawn — the date stays as it was.';

  @override
  String get requestBookingTitle => 'Request booking';

  @override
  String get requestSentHeading => 'Your request is on its way';

  @override
  String get requestSentNext => 'What happens next';

  @override
  String get requestSentReference => 'Reference';

  @override
  String get requestSentTitle => 'Request sent';

  @override
  String get requestSentViewBooking => 'View booking';

  @override
  String get requestSentStep2 => 'They accept, or suggest another date';

  @override
  String get requestSentStep2Body =>
      'Their phone number is shared once accepted.';

  @override
  String get requestSentStep3 => 'You pay on the day';

  @override
  String get requestSentStep3Body =>
      'In cash, directly to the provider. Eventor charges you nothing.';

  @override
  String get rescheduleCurrentlyBooked => 'CURRENTLY BOOKED';

  @override
  String get rescheduleCurrentlyRequested => 'CURRENTLY REQUESTED';

  @override
  String get rescheduleFailedTitle => 'Couldn’t send the new date';

  @override
  String get rescheduleLegendCurrent => 'Current booking';

  @override
  String get rescheduleMove => 'Change the date';

  @override
  String get rescheduleMoved => 'Date changed.';

  @override
  String get rescheduleNewDate => 'New date and time';

  @override
  String get rescheduleProposedCaption => 'proposed';

  @override
  String get rescheduleReasonError =>
      'Say why — the provider reads this first.';

  @override
  String get rescheduleReasonHint => 'The hall was double-booked…';

  @override
  String get rescheduleReasonLabel => 'Why the change?';

  @override
  String get rescheduleSend => 'Send proposal';

  @override
  String get rescheduleSent =>
      'Proposal sent. You’ll be notified when they answer.';

  @override
  String get rescheduleTitle => 'Propose a new date';

  @override
  String get rescheduleTitlePending => 'Change the date';

  @override
  String get reviewBody => 'Your review helps other clients choose.';

  @override
  String get reviewCalloutTitle => 'How was it?';

  @override
  String get reviewCommentHelper => 'Published on their profile.';

  @override
  String get reviewCommentHint => 'What went well, what could be better';

  @override
  String get reviewCommentLabel => 'Your review';

  @override
  String get reviewDone => 'Thanks — your review is published.';

  @override
  String get reviewLater => 'Later';

  @override
  String get reviewSubmit => 'Publish review';

  @override
  String get stepCancelledByYou => 'Cancelled by you';

  @override
  String get stepCompleted => 'Completed';

  @override
  String get stepConfirmAfter => 'Confirm after the event';

  @override
  String get stepEventDay => 'Event day';

  @override
  String get stepHowDidItGo => 'Tell us how it went';

  @override
  String get stepNewDateProposed => 'New date proposed';

  @override
  String get stepNotApplicable => 'Not applicable';

  @override
  String get stepRequested => 'Requested';

  @override
  String get stepWaitingForYou => 'waiting for you';

  @override
  String get stepYouConfirmed => 'you confirmed all went well';

  @override
  String get stepperLess => 'Less';

  @override
  String get stepperMore => 'More';

  @override
  String bookingBasePrice(String unit) {
    return 'Base price · $unit';
  }

  @override
  String bookingBookAgain(String provider) {
    return 'Book $provider again';
  }

  @override
  String bookingCallLabel(String provider) {
    return 'Call $provider';
  }

  @override
  String bookingCashFootnote(String provider) {
    return 'Payment is cash, directly to $provider on the day. Eventor charges you nothing.';
  }

  @override
  String bookingCompletedOn(String date) {
    return 'Completed $date';
  }

  @override
  String bookingGuestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String bookingGuestsMax(int max) {
    return 'Up to $max guests.';
  }

  @override
  String bookingMessageProvider(String provider) {
    return 'Message $provider';
  }

  @override
  String bookingNotAcceptingTitle(String provider) {
    return '$provider paused new bookings';
  }

  @override
  String bookingNoticeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dates need at least $count days’ notice.',
      one: 'Dates need at least 1 day’s notice.',
    );
    return '$_temp0';
  }

  @override
  String bookingPolicySetBy(String provider) {
    return 'Set by $provider';
  }

  @override
  String bookingRequestedOn(String date) {
    return 'Requested $date';
  }

  @override
  String bookingTakenBody(String provider) {
    return '$provider accepted another booking for that date while you were filling this in. Everything else you entered is saved — pick another date to carry on.';
  }

  @override
  String bookingTakenTitle(String date) {
    return '$date was just taken';
  }

  @override
  String bookingWilayaSheetBody(String provider) {
    return 'Where $provider works.';
  }

  @override
  String cancelBodyShort(String provider) {
    return '$provider is told straight away and the slot is released.';
  }

  @override
  String cancelBookingBody(String provider) {
    return '$provider is told straight away and the slot is released. This cannot be undone — you would have to request the date again.';
  }

  @override
  String cancelDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'You are $days days before the event.',
      one: 'Your event is tomorrow.',
      zero: 'Your event is today.',
    );
    return '$_temp0';
  }

  @override
  String cancelPolicyQuote(String provider, String policy) {
    return '$provider’s policy: “$policy”';
  }

  @override
  String cancelReasonHelper(String provider) {
    return '$provider will see this reason.';
  }

  @override
  String cancelRequestBody(String provider) {
    return '$provider is told straight away and your hold on the date is released.';
  }

  @override
  String cancelledByOtherTitle(String provider) {
    return '$provider cancelled this booking';
  }

  @override
  String cancelledByYouBody(String provider) {
    return '$provider has been notified. You owe nothing — no payment had been made.';
  }

  @override
  String checkInBody(String date) {
    return 'Your event was on $date. Let us know before we close the booking — it takes one tap.';
  }

  @override
  String checkInCalloutBody(String provider) {
    return 'Confirm that $provider delivered as agreed, or report a problem.';
  }

  @override
  String checkInWaiting(String provider) {
    return 'Thanks! It closes once $provider confirms too.';
  }

  @override
  String contactNotePending(String provider) {
    return 'The phone number appears once $provider accepts your request.';
  }

  @override
  String declinedTitle(String provider) {
    return '$provider declined this request';
  }

  @override
  String disputeOpenTitle(String reference) {
    return 'Problem reported · $reference';
  }

  @override
  String invoiceFootnote(String provider) {
    return 'Issued by Eventor for your records. The payment itself goes directly to $provider.';
  }

  @override
  String invoiceIssued(String date) {
    return 'Issued $date';
  }

  @override
  String invoicePaidNote(String provider, String date) {
    return 'Paid in cash to $provider on $date. Nothing was added to your total.';
  }

  @override
  String invoiceShareSubject(String number) {
    return 'Eventor invoice $number';
  }

  @override
  String invoiceToPayNote(String provider, String date) {
    return 'To pay in cash to $provider on $date. Eventor adds nothing to your total.';
  }

  @override
  String packBookingDaysIntro(int count) {
    return 'Only days when all $count services in the pack are free can be selected.';
  }

  @override
  String packBookingSummary(int count, String provider, String wilaya) {
    return '$count services, all from $provider · $wilaya';
  }

  @override
  String packLegendAllFree(int count) {
    return 'All $count free';
  }

  @override
  String packReviewOneRequest(int count, String provider) {
    return 'All $count services are provided by $provider. Booking the pack sends one request for all of them.';
  }

  @override
  String packReviewSum(int count) {
    return 'Sum of the $count services';
  }

  @override
  String problemBody(String provider) {
    return 'Tell us what happened with $provider. Eventor support steps in; payment was cash, so there are no refunds or fees.';
  }

  @override
  String problemDescriptionTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more characters, please.',
      one: '1 more character, please.',
    );
    return '$_temp0';
  }

  @override
  String proposalAccept(String date) {
    return 'Accept $date';
  }

  @override
  String proposalAccepted(String date) {
    return 'New date accepted: $date.';
  }

  @override
  String proposalConsequence(String date, String provider) {
    return 'If you decline, the $date booking stands and $provider may cancel it.';
  }

  @override
  String proposalMineBody(String provider) {
    return 'Your current date stays held until $provider answers.';
  }

  @override
  String proposalMineTitle(String date) {
    return 'You proposed $date';
  }

  @override
  String proposalTitle(String provider) {
    return '$provider proposes a new date';
  }

  @override
  String reasonGiven(String reason) {
    return 'Reason given: “$reason”';
  }

  @override
  String requestSentStep1(String provider) {
    return '$provider reviews your request';
  }

  @override
  String requestSentStep1Deadline(int hours) {
    return 'They have $hours h to answer — we’ll notify you.';
  }

  @override
  String requestSentStep1Usually(String time) {
    return 'Usually within $time — we’ll notify you.';
  }

  @override
  String rescheduleBookedDays(String provider) {
    return 'Days $provider is already booked are struck through.';
  }

  @override
  String rescheduleHoldNote(String date, String provider) {
    return 'Your $date slot stays held until $provider answers. If they decline, the original booking is unchanged and the price does not change.';
  }

  @override
  String reschedulePendingNote(String provider) {
    return 'Your request moves to the new date straight away; $provider still has to accept it.';
  }

  @override
  String rescheduleReasonHelper(String provider) {
    return '$provider will read this.';
  }

  @override
  String rescheduleTakenBody(String provider) {
    return '$provider is no longer free that day. Pick another date.';
  }

  @override
  String reviewCalloutBody(String provider) {
    return 'Your review of $provider helps other clients choose.';
  }

  @override
  String reviewCommentTooShort(int count) {
    return 'At least $count characters.';
  }

  @override
  String reviewStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String reviewTitle(String provider) {
    return 'Review $provider';
  }

  @override
  String stepAcceptedBy(String provider) {
    return 'Accepted by $provider';
  }

  @override
  String stepCancelledBy(String provider) {
    return 'Cancelled by $provider';
  }

  @override
  String stepDeclinedBy(String provider) {
    return 'Declined by $provider';
  }

  @override
  String stepRepliesWithinHours(int hours) {
    return 'Replies within $hours h';
  }

  @override
  String stepUsuallyReplies(String time) {
    return 'Usually replies within $time';
  }

  @override
  String stepWaitingFor(String provider) {
    return 'Waiting for $provider';
  }

  @override
  String stepYouConfirmedWaiting(String provider) {
    return 'You confirmed · waiting for $provider';
  }

  @override
  String get bookingNextDay => 'next day';

  @override
  String get bookingNextDayMark => '+1 day';

  @override
  String get bookingDurationHalfHour => '30 min';

  @override
  String bookingDurationHours(int count) {
    return '$count h';
  }

  @override
  String bookingDurationHoursHalf(int count) {
    return '$count h 30 min';
  }

  @override
  String bookingGuestsTooMany(int max) {
    return 'Up to $max guests for this booking.';
  }

  @override
  String get invoiceShare => 'Share';

  @override
  String get invoiceSavedToDownloads => 'Invoice saved to Downloads.';

  @override
  String get invoiceSavedToFiles => 'Invoice saved to Files › Eventor.';

  @override
  String get invoiceOpen => 'Open';

  @override
  String get invoiceSaveFailed =>
      'Couldn’t save the invoice on this phone. Try again.';

  @override
  String get invoiceSaveDenied => 'Allow storage access to save the invoice.';

  @override
  String get invoiceNoPdfApp => 'No app on this phone can open PDFs.';

  @override
  String get downloadsChannelName => 'Downloads';

  @override
  String get invoiceDownloadNoticeText => 'Download complete · Tap to open';

  @override
  String get availabilityTitle => 'Availability';

  @override
  String get availabilityLegendFree => 'Free';

  @override
  String get availabilityLegendPartial => 'Partly blocked';

  @override
  String get availabilityLegendBlocked => 'Blocked';

  @override
  String get availabilityLegendHeld => 'Request held';

  @override
  String get availabilityLegendBooked => 'Booked';

  @override
  String get availabilityToday => 'Today';

  @override
  String availabilityNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clients must book at least $count days ahead.',
      one: 'Clients must book at least $count day ahead.',
    );
    return '$_temp0';
  }

  @override
  String get availabilityTapHint =>
      'Tap a day to see what is on it, or to block it.';

  @override
  String get availabilityBlockDay => 'Block a day';

  @override
  String availabilityDaySummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things are on this day.',
      one: 'One thing is on this day.',
      zero: 'Nothing is on this day yet.',
    );
    return '$_temp0';
  }

  @override
  String get availabilityDayRemoveHint =>
      'Only blocks you added can be removed.';

  @override
  String get availabilityDayPast =>
      'This day has passed. Nothing on it can be changed.';

  @override
  String get availabilityItemBlockedAllDay => 'Blocked all day';

  @override
  String get availabilityItemBlockedSlot => 'Blocked';

  @override
  String availabilityItemBooked(String reference) {
    return 'Booked — $reference';
  }

  @override
  String availabilityItemHeld(String reference) {
    return 'Request held — $reference';
  }

  @override
  String get availabilityAllServices => 'All services';

  @override
  String availabilityItemNote(String note) {
    return '“$note”';
  }

  @override
  String get availabilityRemove => 'Remove';

  @override
  String get availabilityCannotRemove => 'Cannot be removed';

  @override
  String get availabilityWhyBooked =>
      'An accepted booking. Cancel or move it from the booking.';

  @override
  String get availabilityWhyHeld =>
      'A request waiting for your answer holds this day.';

  @override
  String get availabilityBlockWholeDay => 'Block the whole day';

  @override
  String get availabilityBlockSlot => 'Block a time slot';

  @override
  String get availabilityBlockAnotherSlot => 'Block another slot';

  @override
  String get availabilityClose => 'Close';

  @override
  String get availabilityAlreadyBlocked =>
      'This day is already blocked for every service.';

  @override
  String get availabilityFullyBooked =>
      'This day is fully booked, so there is nothing left to block.';

  @override
  String availabilityBlockDayTitle(String day) {
    return 'Block $day';
  }

  @override
  String availabilityBlockSlotTitle(String day) {
    return 'Block part of $day';
  }

  @override
  String get availabilityBlockDayBody =>
      'Clients will not be able to book this day. You can remove the block at any time.';

  @override
  String get availabilityBlockSlotBody =>
      'Clients can still book the rest of the day. You can remove the block at any time.';

  @override
  String get availabilityModeWholeDay => 'Whole day';

  @override
  String get availabilityModeSlot => 'Time slot';

  @override
  String get availabilityModeSelected => 'Selected';

  @override
  String get availabilityServicesLabel => 'Which services';

  @override
  String get availabilityServicesSubtitle =>
      'Block every service, or just one.';

  @override
  String get availabilityServicesFailed =>
      'We could not load your services. Try again.';

  @override
  String get availabilityNoteLabel => 'Note (only you see it)';

  @override
  String get availabilityNoteHint => 'e.g. Family wedding';

  @override
  String get availabilityConfirmDay => 'Block the day';

  @override
  String get availabilityConfirmSlot => 'Block the slot';

  @override
  String get availabilityCancel => 'Cancel';

  @override
  String get availabilitySlotHelper =>
      'Clients can still book outside these hours.';

  @override
  String get availabilityTimesMissing => 'Pick when the slot starts and ends.';

  @override
  String get availabilityHeldWarning =>
      'A request is waiting on this day. Blocking it does not decline the request.';

  @override
  String get availabilityBookedWarning =>
      'This day already has a booking. Blocking it does not cancel the booking.';

  @override
  String get availabilityErrorDatePast =>
      'This day has already passed. Pick another day.';

  @override
  String get availabilityErrorServiceInvalid =>
      'That service can no longer be blocked. Pick another one, or block all services.';

  @override
  String get availabilityErrorNotRemovable =>
      'This block can no longer be removed. The calendar is up to date again.';

  @override
  String get availabilityErrorNotFound =>
      'This block was already removed. The calendar is up to date again.';

  @override
  String availabilityBlockedDayToast(String day) {
    return '$day is blocked.';
  }

  @override
  String availabilityBlockedSlotToast(String day) {
    return 'Part of $day is blocked.';
  }

  @override
  String get availabilityRemovedToast => 'Block removed.';

  @override
  String get availabilityRestoredToast => 'Block put back.';

  @override
  String get providerRequestsTabTitle => 'Requests';

  @override
  String get providerRequestsChipRequests => 'Requests';

  @override
  String get providerRequestsChipUpcoming => 'Upcoming';

  @override
  String get providerRequestsChipPast => 'Past';

  @override
  String get providerRequestsEmptyTitle => 'No requests yet';

  @override
  String providerRequestsEmptyBody(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return 'When a client asks to book one of your services, it arrives here. You have $_temp0 to accept or decline before the request expires.';
  }

  @override
  String get providerRequestsEmptyUpcomingTitle => 'No bookings ahead';

  @override
  String get providerRequestsEmptyUpcomingBody =>
      'Requests you accept show up here until the event day.';

  @override
  String get providerRequestsEmptyPastTitle => 'No past bookings yet';

  @override
  String get providerRequestsEmptyPastBody =>
      'Once an event is behind you, it moves here with its invoice.';

  @override
  String get providerRequestsReviewBody =>
      'We are checking your documents. Your services stay unpublished until then, so clients cannot send you requests yet.';

  @override
  String get providerRequestsRejectedBody =>
      'Some of your documents were not accepted. Your services stay unpublished until your profile is approved, so clients cannot send you requests yet.';

  @override
  String get providerRequestsSeeDocuments => 'See my documents';

  @override
  String providerRequestsReplyWithin(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Reply within $hours h',
      zero: 'Reply now',
    );
    return '$_temp0';
  }

  @override
  String providerRequestsAccepted(String name) {
    return 'Request from $name accepted — it is now under Upcoming.';
  }

  @override
  String get providerBookingTitleRequest => 'Request';

  @override
  String providerBookingStepRequestedBy(String client) {
    return 'Requested by $client';
  }

  @override
  String get providerBookingStepYourReply => 'Your reply';

  @override
  String get providerBookingStepYouAccepted => 'You accepted';

  @override
  String get providerBookingStepYouDeclined => 'You declined';

  @override
  String providerBookingStepCancelledBy(String client) {
    return 'Cancelled by $client';
  }

  @override
  String get providerBookingStepCancelledByEventor => 'Cancelled by Eventor';

  @override
  String get providerBookingStepConfirmEvent => 'Confirm the event';

  @override
  String get providerBookingStepWaitingBoth => 'Waiting for both of you';

  @override
  String providerBookingStepYouConfirmed(String client) {
    return 'You confirmed · waiting for $client';
  }

  @override
  String providerBookingStepClientConfirmed(String client) {
    return '$client confirmed · waiting for you';
  }

  @override
  String get providerBookingStepBothConfirmed => 'both of you confirmed';

  @override
  String providerBookingStepClientProposed(String client) {
    return '$client proposed a new date';
  }

  @override
  String get providerBookingStepYouProposed => 'You proposed a new date';

  @override
  String providerBookingStepWaitingFor(String client) {
    return 'waiting for $client';
  }

  @override
  String providerBookingYourService(String category) {
    return 'Your service · $category';
  }

  @override
  String get providerBookingYourPack => 'Your pack';

  @override
  String get providerBookingTheEvent => 'The event';

  @override
  String get providerBookingClientNote => 'Client’s note';

  @override
  String get providerBookingTotalOnSite => 'Total · client pays on site';

  @override
  String get providerBookingCashNote =>
      'The client pays you in cash on the day. Nothing is collected through Eventor.';

  @override
  String get providerBookingClientSection => 'Client';

  @override
  String get providerBookingContactHidden => 'Hidden until you accept';

  @override
  String get providerBookingContactNotShared => 'Not shared';

  @override
  String providerBookingContactPending(String client) {
    return '$client’s phone and email appear here as soon as you accept the request.';
  }

  @override
  String providerBookingContactAccepted(String client) {
    return '$client’s phone and email are shared because you accepted this booking.';
  }

  @override
  String providerBookingContactUntilClosed(String client) {
    return '$client’s phone and email stay visible until the booking is closed.';
  }

  @override
  String get providerBookingContactDeclined =>
      'Contact details are never shared for a request you declined.';

  @override
  String get providerBookingContactHistory =>
      'Contact details stay visible while this booking is in your history.';

  @override
  String get providerBookingContactWithdrawn =>
      'Contact details are not shared for a request that was cancelled.';

  @override
  String get providerBookingPolicySetByYou => 'Set by you';

  @override
  String providerBookingMessageClient(String client) {
    return 'Message $client';
  }

  @override
  String get providerBookingAcceptRequest => 'Accept request';

  @override
  String get providerBookingConfirmEvent => 'Confirm the event';

  @override
  String get providerBookingDeclinedTitle => 'You declined this request';

  @override
  String providerBookingDeclinedBody(String client) {
    return 'The date is free again on your calendar and $client has been told.';
  }

  @override
  String providerBookingCancelledByClientTitle(String client) {
    return '$client cancelled this booking';
  }

  @override
  String get providerBookingCancelledByClientBody =>
      'The date is free again on your calendar and the invoice has been voided.';

  @override
  String providerBookingCancelledByYouBody(String client) {
    return '$client has been told, the date is free again on your calendar and the invoice has been voided.';
  }

  @override
  String get providerBookingCancelledByEventorTitle =>
      'Eventor cancelled this booking';

  @override
  String providerBookingRequestWithdrawnTitle(String client) {
    return '$client cancelled this request';
  }

  @override
  String get providerBookingRequestWithdrawnBody =>
      'The date is free again on your calendar.';

  @override
  String providerBookingReviewTitle(String client) {
    return '$client can review this booking';
  }

  @override
  String get providerBookingReviewBody =>
      'Their review appears in Reviews, where you can reply to it once. Clients have 60 days after the event to leave one.';

  @override
  String providerBookingProposalTitle(String client) {
    return '$client proposes a new date';
  }

  @override
  String providerBookingProposalHelper(String date, String client) {
    return 'If you decline, the $date booking stands and $client may cancel it.';
  }

  @override
  String providerBookingProposalSentTitle(String date) {
    return 'Proposal sent: $date';
  }

  @override
  String providerBookingProposalSentBody(String date, String client) {
    return 'The booking stays on $date until $client answers.';
  }

  @override
  String get providerBookingWithdraw => 'Withdraw';

  @override
  String providerBookingProposalSentToast(String client) {
    return 'Proposal sent. $client will be told.';
  }

  @override
  String providerBookingCancelBody(String client) {
    return '$client is told straight away, the date is released on your calendar and the invoice is voided. This cannot be undone.';
  }

  @override
  String get providerBookingCancelReasonHint =>
      'e.g. The hall is closed for repairs that day';

  @override
  String get providerBookingCancelNote =>
      'Clients count on you: cancel only when there is no other way. Proposing a new date is often better.';

  @override
  String get providerBookingCancelKeep => 'Keep the booking';

  @override
  String get providerBookingDeclineTitle => 'Decline this request?';

  @override
  String get providerBookingDeclineReasonLabel => 'Why are you declining?';

  @override
  String get providerBookingProblemClientNoShow => 'The client didn’t show up';

  @override
  String get providerBookingProblemCancellation => 'Cancellation disagreement';

  @override
  String get providerBookingLegendFree => 'Free';

  @override
  String get providerBookingLegendBlocked => 'Blocked by you';

  @override
  String get providerBookingRescheduleFootnote =>
      'Days you are already booked or have blocked are greyed out.';

  @override
  String get providerBookingTimeHelper =>
      'The times the client asked for, until you change them.';

  @override
  String get providerBookingRescheduleReasonHint =>
      'e.g. The hall is only free the week after';

  @override
  String providerBookingRescheduleReasonError(String client) {
    return 'Say why — $client reads this first.';
  }

  @override
  String providerBookingRescheduleHold(String date, String client) {
    return 'The $date booking stays in place until $client answers. If the proposal is declined, nothing changes and the price stays the same.';
  }

  @override
  String providerBookingReschedulePendingNote(String client) {
    return 'The request moves to the new date straight away and $client is told. You can then accept it.';
  }

  @override
  String get providerBookingRescheduleTakenBody =>
      'You are no longer free that day. Pick another date.';

  @override
  String providerBookingCheckInBody(String client, String date) {
    return 'The event with $client was on $date. Confirm before we close the booking — it takes one tap.';
  }

  @override
  String providerBookingAllGoodBody(String client) {
    return 'The event went ahead as agreed. We close the booking and $client can leave a review.';
  }

  @override
  String get providerBookingProblemBody =>
      'The client did not show up, or something else went wrong. We open a dispute and support steps in.';

  @override
  String get providerBookingRemindTomorrow => 'Remind me tomorrow';

  @override
  String get providerBookingCheckInFootnote =>
      'If neither of you answers, the booking closes on its own 72 hours after the event.';

  @override
  String providerBookingCheckInWaiting(String client) {
    return 'Thanks! It closes once $client confirms too.';
  }

  @override
  String get providerBookingCheckInNothing =>
      'There is nothing to confirm on this booking now.';

  @override
  String get providerBookingOpen => 'See the booking';

  @override
  String get providerServiceTabTitle => 'My services';

  @override
  String get providerPackTabTitle => 'My packs';

  @override
  String get providerServiceChipServices => 'Services';

  @override
  String get providerServiceChipPacks => 'Packs';

  @override
  String get providerServiceEmptyTitle => 'No services yet';

  @override
  String get providerServiceEmptyBody =>
      'A service is what clients find and book — a package, a session, a hire. Add one, then publish it when it is ready.';

  @override
  String providerServiceRatingLine(int count, String rating) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating · $count reviews',
      one: '$rating · 1 review',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceNoReviews => 'No reviews yet';

  @override
  String get providerServiceNotPublishedYet => 'Not published yet';

  @override
  String providerServiceHiddenOn(String date) {
    return 'Hidden on $date';
  }

  @override
  String providerServicePhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'no photos',
    );
    return '$_temp0';
  }

  @override
  String providerServiceBookingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings',
      one: '1 booking',
      zero: 'no bookings',
    );
    return '$_temp0';
  }

  @override
  String providerServiceMissingNote(String items) {
    return 'Missing before publishing: $items';
  }

  @override
  String get providerServiceMissingTitleEn => 'English title';

  @override
  String get providerServiceMissingTitleAr => 'Arabic title';

  @override
  String get providerServiceMissingDescriptionEn => 'English description';

  @override
  String get providerServiceMissingDescriptionAr => 'Arabic description';

  @override
  String get providerServiceMissingPrice => 'a base price';

  @override
  String get providerServiceMissingPhotos => 'a photo';

  @override
  String get providerServiceMissingCategory => 'a category';

  @override
  String get providerServiceMissingWilayas => 'an open wilaya';

  @override
  String get providerServiceListSeparator => ', ';

  @override
  String providerServiceNotVisibleClosed(int count, String wilayas) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Not visible to clients — $wilayas are closed on Eventor right now',
      one: 'Not visible to clients — $wilayas is closed on Eventor right now',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceNotVisibleNoWilaya =>
      'Not visible to clients — it covers no wilaya open on Eventor';

  @override
  String get providerServiceNotVisibleReview =>
      'Not visible to clients — your profile is still being reviewed';

  @override
  String get providerServiceNotVisibleBlocked =>
      'Not visible to clients — your account is blocked';

  @override
  String get providerServiceHiddenFinal =>
      'Eventor hid this service. Clients cannot see it and you cannot publish it again. Edits are still saved.';

  @override
  String get providerServiceHiddenReviewable =>
      'Eventor hid this service. Clients cannot see it. Fix it, then contact support to have it reviewed again. Edits are still saved.';

  @override
  String providerServiceHiddenMessage(String message) {
    return 'Eventor’s note: “$message”';
  }

  @override
  String get providerServiceUnpublish => 'Unpublish';

  @override
  String get providerServiceEdit => 'Edit';

  @override
  String get providerServicePublish => 'Publish';

  @override
  String get providerServicePublished => 'Published — clients can find it now';

  @override
  String get providerServiceUnpublished => 'Unpublished — it is a draft again';

  @override
  String get providerServiceDraftSaved => 'Draft saved';

  @override
  String get providerServiceChangesSaved => 'Changes saved';

  @override
  String get providerServiceDeleted => 'Service deleted';

  @override
  String get providerServiceUnpublishTitle => 'Unpublish this service?';

  @override
  String get providerServiceUnpublishBody =>
      'It leaves search and your profile straight away and goes back to your drafts. Bookings already accepted are kept.';

  @override
  String get providerServiceKeepPublished => 'Keep it published';

  @override
  String get providerServiceDeleteTitle => 'Delete this service?';

  @override
  String get providerServiceDeleteBody =>
      'Deleting is permanent. Requests still waiting for your answer on it are cancelled.';

  @override
  String get providerServiceDeleteConfirm => 'Delete';

  @override
  String get providerServiceDeleteKeep => 'Keep it';

  @override
  String get providerServiceDeleteButton => 'Delete this service';

  @override
  String get providerServiceDeleteCaption =>
      'Deleting is permanent. It is refused while the service still has upcoming bookings or sits in a pack.';

  @override
  String get providerServiceDeleteRefusedTitle =>
      'This service cannot be deleted yet';

  @override
  String get providerServiceDeleteRefusedBody =>
      'Deleting is blocked while this is true. Unpublishing is available now and takes it out of search straight away.';

  @override
  String get providerServiceDeleteRefusedBodyPlain =>
      'Deleting is blocked while this is true.';

  @override
  String providerServiceBlockerBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accepted bookings are still ahead',
      one: '1 accepted booking is still ahead',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceBlockerBookingsUncounted =>
      'Accepted bookings are still ahead';

  @override
  String providerServiceBlockerPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It belongs to $count of your packs',
      one: 'It belongs to 1 of your packs',
    );
    return '$_temp0';
  }

  @override
  String get providerServiceBlockerPacksUncounted =>
      'It still sits in one of your packs';

  @override
  String get providerServiceUnpublishInstead => 'Unpublish instead';

  @override
  String get providerServiceCancel => 'Cancel';

  @override
  String get providerServiceEditTitle => 'Edit service';

  @override
  String get providerServiceLangEnglish => 'English';

  @override
  String get providerServiceLangArabic => 'عربي';

  @override
  String providerServiceLangArabicMissing(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'both': 'Arabic still needs a title and a description. Both are required before you can publish.',
      'title':
          'Arabic still needs a title. It is required before you can publish.',
      'other': 'Arabic still needs a description. It is required before you can publish.',
    });
    return '$_temp0';
  }

  @override
  String providerServiceLangEnglishMissing(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'both': 'English still needs a title and a description. Both are required before you can publish.',
      'title':
          'English still needs a title. It is required before you can publish.',
      'other': 'English still needs a description. It is required before you can publish.',
    });
    return '$_temp0';
  }

  @override
  String get providerServiceLangComplete =>
      'English and Arabic are both complete.';

  @override
  String get providerServiceLangCompleteLive =>
      'English and Arabic are both complete. This service is live, so edits show to clients straight away.';

  @override
  String get providerServiceBasics => 'Basics';

  @override
  String get providerServicePricing => 'Pricing';

  @override
  String get providerServiceCapacity => 'Capacity';

  @override
  String get providerServiceIncluded => 'What is included';

  @override
  String get providerServiceExtras => 'Extras';

  @override
  String get providerServiceWilayas => 'Wilayas covered';

  @override
  String get providerServicePolicy => 'Cancellation policy';

  @override
  String get providerServicePhotos => 'Photos';

  @override
  String get providerServiceCategory => 'Category';

  @override
  String get providerServiceChoose => 'Choose';

  @override
  String providerServiceTitleLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'Title (Arabic)',
      'other': 'Title (English)',
    });
    return '$_temp0';
  }

  @override
  String providerServiceDescriptionLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'Description (Arabic)',
      'other': 'Description (English)',
    });
    return '$_temp0';
  }

  @override
  String providerServicePolicyLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'Shown to clients before they book (Arabic)',
      'other': 'Shown to clients before they book (English)',
    });
    return '$_temp0';
  }

  @override
  String get providerServiceBasePriceLabel => 'Base price (DA)';

  @override
  String get providerServiceBasePriceHelper =>
      'The starting price, before any extras.';

  @override
  String get providerServiceStartingPriceLabel => 'Starting price (DA)';

  @override
  String get providerServiceStartingPriceHelper =>
      'Clients see “On quote”. This figure is what a pack counts for it.';

  @override
  String get providerServicePriceTypeLabel => 'Price type';

  @override
  String providerServicePriceTypeOption(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'per_event': 'Per event',
      'per_hour': 'Per hour',
      'per_person': 'Per person',
      'per_day': 'Per day',
      'other': 'On quote',
    });
    return '$_temp0';
  }

  @override
  String get providerServiceMaxEventsLabel => 'Max events per day';

  @override
  String get providerServiceMaxGuestsLabel => 'Max guests';

  @override
  String get providerServiceMaxGuestsNone => 'Leave empty for no limit';

  @override
  String providerServiceRange(int min, int max) {
    return 'Between $min and $max';
  }

  @override
  String get providerServiceFieldRequired => 'Required';

  @override
  String get providerServiceAddFact => 'Add a fact';

  @override
  String get providerServiceEditFact => 'Edit a fact';

  @override
  String get providerServiceNoFacts =>
      'Nothing listed yet — duration, team, delivery…';

  @override
  String get providerServiceFactSheetBody =>
      'Clients read it in their own language, so both are needed.';

  @override
  String get providerServiceFactLabelEn => 'Label (English)';

  @override
  String get providerServiceFactValueEn => 'Value (English)';

  @override
  String get providerServiceFactLabelAr => 'Label (Arabic)';

  @override
  String get providerServiceFactValueAr => 'Value (Arabic)';

  @override
  String get providerServiceSheetSave => 'Save';

  @override
  String get providerServiceRemove => 'Remove';

  @override
  String get providerServiceAddExtra => 'Add an extra';

  @override
  String get providerServiceEditExtra => 'Edit an extra';

  @override
  String get providerServiceNoExtras => 'No extras yet';

  @override
  String get providerServiceExtraSheetBody =>
      'A paid option clients can add to their booking.';

  @override
  String get providerServiceExtraNameEn => 'Name (English)';

  @override
  String get providerServiceExtraNameAr => 'Name (Arabic)';

  @override
  String get providerServiceExtraNameArHelper =>
      'Until you add it, clients reading Arabic see the English name.';

  @override
  String get providerServiceExtraPrice => 'Price (DA)';

  @override
  String get providerServiceAddWilaya => '+ Add wilaya';

  @override
  String get providerServiceWilayaPickerBody =>
      'Only wilayas open on Eventor are listed.';

  @override
  String providerServiceRemoveWilaya(String name) {
    return 'Remove $name';
  }

  @override
  String get providerServiceNoWilayas =>
      'Add at least one open wilaya before you publish.';

  @override
  String providerServicePhotosAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count added',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String get providerServicePhotosNeedDraft =>
      'To add photos, first give the service a category, an English title, a base price and a price type.';

  @override
  String get providerServiceDraftSavedForPhotos =>
      'Draft saved — now add your photos';

  @override
  String get providerServiceSaveDraft => 'Save draft';

  @override
  String get providerServiceSave => 'Save';

  @override
  String get providerServiceSaveChanges => 'Save changes';

  @override
  String get providerServiceFixFields => 'Fill in the fields marked in red.';

  @override
  String get providerServiceNotVerifiedTitle =>
      'Publishing unlocks after approval';

  @override
  String get providerServiceNotVerifiedBody =>
      'Your documents are still being reviewed. Your draft is saved — publish it as soon as your profile is approved.';

  @override
  String get providerServiceGotIt => 'Got it';

  @override
  String get providerServiceChecklistTitle => 'Not ready to publish yet';

  @override
  String get providerServiceChecklistBody =>
      'Clients cannot see this service until everything below is filled in. Your draft is already saved.';

  @override
  String get providerServiceCheckEnglish => 'English title and description';

  @override
  String get providerServiceCheckArabic => 'Arabic title and description';

  @override
  String get providerServiceCheckPrice => 'A base price';

  @override
  String get providerServiceCheckPhotos => 'At least one photo';

  @override
  String get providerServiceCheckCategory => 'A category clients can browse';

  @override
  String get providerServiceCheckWilayas => 'At least one open wilaya';

  @override
  String get providerServiceCheckDone => 'Done';

  @override
  String get providerServiceCheckMissing => 'Missing';

  @override
  String get providerServiceFixEnglish => 'Add the English';

  @override
  String get providerServiceFixArabic => 'Add the Arabic';

  @override
  String get providerServiceFixPrice => 'Add a price';

  @override
  String get providerServiceFixPhotos => 'Add photos';

  @override
  String get providerServiceFixCategory => 'Choose a category';

  @override
  String get providerServiceFixWilayas => 'Add a wilaya';

  @override
  String get providerServiceKeepDraft => 'Keep as draft';

  @override
  String get providerServicePhotosHelper =>
      'The first photo is the cover clients see. Tap a photo to make it the cover, move it or remove it.';

  @override
  String get providerPackPhotosHelper =>
      'The first photo is the cover clients see in search. Tap a photo to make it the cover, move it or remove it.';

  @override
  String providerServicePhotosCounter(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count of $max photos',
    );
    return '$_temp0';
  }

  @override
  String get providerServicePhotoCover => 'Cover';

  @override
  String get providerServicePhotoProcessing => 'Processing';

  @override
  String get providerServicePhotoFailed => 'Could not process';

  @override
  String get providerServicePhotoUploading => 'Uploading';

  @override
  String get providerServicePhotoUploadFailed => 'Not sent';

  @override
  String get providerServicePhotoRetry => 'Retry';

  @override
  String get providerServiceAddPhoto => 'Add photo';

  @override
  String providerServicePhotosFull(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other:
          'That is as many as a gallery holds — $max photos. Remove one to add another.',
    );
    return '$_temp0';
  }

  @override
  String get providerServicePhotosEmpty =>
      'No photos yet — the first one you add becomes the cover.';

  @override
  String get providerServicePhotoActionsTitle => 'This photo';

  @override
  String get providerServicePhotoMakeCover => 'Make cover';

  @override
  String get providerServicePhotoMoveEarlier => 'Move earlier';

  @override
  String get providerServicePhotoMoveLater => 'Move later';

  @override
  String get providerServicePhotoRemoveTitle => 'Remove this photo?';

  @override
  String get providerServicePhotoRemoveBody =>
      'It leaves the gallery for good.';

  @override
  String get providerServicePhotoLastRefused =>
      'A published service needs at least one photo. Unpublish it first to remove the last one.';

  @override
  String providerServicePhotoLabel(int index) {
    return 'Photo $index';
  }

  @override
  String get providerPackEmptyTitle => 'No packs yet';

  @override
  String get providerPackEmptyBody =>
      'A pack bundles two or more of your published services at a price below their total — for clients planning a whole event.';

  @override
  String providerPackEmptyNeedsServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A pack bundles two or more of your published services at a price below their total.',
      one: 'A pack bundles two or more of your published services at a price below their total. You have one published service, so there is nothing to bundle yet.',
      zero: 'A pack bundles two or more of your published services at a price below their total. You have no published service yet, so there is nothing to bundle.',
    );
    return '$_temp0';
  }

  @override
  String get providerPackCreate => 'Create a pack';

  @override
  String get providerPackPublishAnother => 'Publish another service';

  @override
  String get providerPackStatusUnpublished => 'Unpublished';

  @override
  String providerPackServicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
    );
    return '$_temp0';
  }

  @override
  String get providerPackSaves => 'Saves';

  @override
  String get providerPackSumOfItems => 'Sum of items';

  @override
  String providerPackAttentionItem(String service) {
    return 'Needs attention — “$service” is no longer published, so clients cannot book this pack';
  }

  @override
  String get providerPackAttentionDeleted =>
      'Needs attention — a service in it was deleted, so clients cannot book this pack';

  @override
  String get providerPackAttentionProfile =>
      'Needs attention — clients cannot book it while your profile is not approved';

  @override
  String get providerPackPriceRule =>
      'The pack price must be below the sum of its services before you can publish';

  @override
  String get providerPackUnpublishTitle => 'Unpublish this pack?';

  @override
  String get providerPackUnpublishBody =>
      'Clients can no longer find or book it. Bookings already accepted are kept.';

  @override
  String get providerPackPublished =>
      'Pack published — clients can book it now';

  @override
  String get providerPackUnpublished => 'Pack unpublished';

  @override
  String get providerPackDeleted => 'Pack deleted';

  @override
  String get providerPackCreateTitle => 'Create pack';

  @override
  String get providerPackEditTitle => 'Edit pack';

  @override
  String get providerPackLangArabicMissing =>
      'Arabic still needs a name. It is required before you can publish.';

  @override
  String get providerPackLangEnglishMissing =>
      'English still needs a name. It is required before you can save.';

  @override
  String get providerPackLangCompleteLive =>
      'English and Arabic are both complete. This pack is live, so edits show to clients straight away.';

  @override
  String providerPackNameLabel(String language) {
    String _temp0 = intl.Intl.selectLogic(language, {
      'ar': 'Pack name (Arabic)',
      'other': 'Pack name (English)',
    });
    return '$_temp0';
  }

  @override
  String get providerPackServicesSection => 'Services in this pack';

  @override
  String get providerPackEditServices => 'Add or remove services';

  @override
  String get providerPackNoServices =>
      'Choose 2 to 6 of your published services.';

  @override
  String providerPackSumCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sum of the $count services',
      two: 'Sum of the two services',
      one: 'Sum of the service',
    );
    return '$_temp0';
  }

  @override
  String providerPackItemNotCovering(String wilaya) {
    return 'Doesn’t cover $wilaya';
  }

  @override
  String get providerPackItemDraft =>
      'Not published — clients cannot book the pack';

  @override
  String get providerPackItemHidden =>
      'Hidden by Eventor — clients cannot book the pack';

  @override
  String get providerPackPriceLabel => 'Pack price (DA)';

  @override
  String get providerPackPriceHelper => 'Must be below the sum of the items.';

  @override
  String get providerPackPriceNotBelow =>
      'That is not below the sum of the items — clients would pay as much or more than booking them one by one.';

  @override
  String get providerPackClientsSave => 'Clients save';

  @override
  String providerPackSavingPercent(int percent) {
    return '· $percent% off booking them separately';
  }

  @override
  String get providerPackEventPlace => 'Event and place';

  @override
  String get providerPackEventType => 'Event type';

  @override
  String get providerPackWilaya => 'Wilaya';

  @override
  String get providerPackWilayaPickerBody =>
      'Every service in the pack must cover it.';

  @override
  String providerPackWilayaCovering(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services cover it',
      one: '1 service covers it',
      zero: 'No service covers it',
    );
    return '$_temp0';
  }

  @override
  String get providerPackPhotosTitle => 'Pack photos';

  @override
  String get providerPackDeleteButton => 'Delete this pack';

  @override
  String get providerPackDeleteCaption =>
      'Deleting is permanent and is refused while the pack still has upcoming bookings. The services inside it are not affected.';

  @override
  String get providerPackDeleteTitle => 'Delete this pack?';

  @override
  String get providerPackDeleteBody =>
      'Deleting is permanent. The services inside it are not affected.';

  @override
  String get providerPackDeleteRefusedTitle =>
      'This pack cannot be deleted yet';

  @override
  String get providerPackServicesRange => 'Choose 2 to 6 services.';

  @override
  String get providerPackPhotosNeedDraft =>
      'To add photos, first give the pack an English name, 2 to 6 services, a price, an event type and a wilaya.';

  @override
  String get providerPackChecklistBody =>
      'Clients cannot see this pack until everything below is filled in. Your draft is already saved.';

  @override
  String get providerPackCheckEnglish => 'English name';

  @override
  String get providerPackCheckArabic => 'Arabic name';

  @override
  String get providerPackCheckServices => 'At least 2 published services';

  @override
  String get providerPackCheckPrice => 'A price below the sum of the items';

  @override
  String get providerPackCheckWilaya => 'A wilaya every service covers';

  @override
  String get providerPackCheckProfile => 'An approved profile';

  @override
  String providerPackFixThese(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fix these $count',
      two: 'Fix these two',
      one: 'Fix this',
    );
    return '$_temp0';
  }

  @override
  String get providerPackChooseTitle => 'Choose services';

  @override
  String get providerPackChooseRule =>
      'Pick 2 to 6 of your published services. Drafts and hidden services cannot go in a pack.';

  @override
  String providerPackChosenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chosen',
      zero: 'None chosen',
    );
    return '$_temp0';
  }

  @override
  String get providerPackChosenSum => 'sum';

  @override
  String providerPackChooseDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done · $count chosen',
      zero: 'Done',
    );
    return '$_temp0';
  }

  @override
  String get providerPackReasonDraft => 'Draft — cannot go in a pack';

  @override
  String get providerPackReasonHidden => 'Hidden — cannot go in a pack';

  @override
  String get providerPackReasonNotCoveringAny =>
      'Doesn’t cover the pack’s wilaya';

  @override
  String get providerPackChooseFull => 'A pack holds up to 6 services.';

  @override
  String get providerPackChooseMin => 'Choose at least 2.';

  @override
  String get providerPackChooseEmpty => 'You have no services yet.';
}
