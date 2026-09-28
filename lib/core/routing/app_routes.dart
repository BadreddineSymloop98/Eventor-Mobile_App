import '../bookings/bookings_repository.dart';
import '../budget/budget_repository.dart';
import '../catalog/models/pack.dart';
import '../catalog/service_query.dart';
import '../models/account.dart';

/// Every place the app can be, as a path.
///
/// Paths rather than names because go_router matches on them — and one of
/// them, [setPassword], has to match a web link an admin's invite email sends
/// (`${APP_PUBLIC_URL}/set-password?token=…`) so the app can open it.
abstract final class AppRoutes {
  /// The splash — `01`. Also where every route waits while the app is still
  /// starting up.
  static const String splash = '/';

  static const String onboarding = '/onboarding';

  /// `05` — where anyone without a session lands, until they have taken one
  /// of its two doors once. After that, [login] is the landing.
  static const String welcome = '/welcome';

  /// `06` — the fork between client and provider.
  static const String roleSelection = '/role';

  /// `08` / `08a`. Carries the chosen role as `?role=`.
  static const String register = '/register';

  /// `10b`–`10d` — confirming the email after sign-up. Carries
  /// [VerifyEmailArgs] as `extra`.
  static const String verifyEmail = '/verify-email';

  /// `08e` — a new provider's documents. Signed in.
  static const String documents = '/documents';

  /// `07`–`07d`. Takes an optional `?email=` to prefill.
  static const String login = '/login';

  /// `09`.
  static const String forgotPassword = '/forgot-password';

  /// `10` — the code for a password reset. Carries the email as `?email=`.
  static const String resetCode = '/reset/code';

  /// `10a` — the new password. Carries [ResetPasswordArgs] as `extra`.
  static const String resetPassword = '/reset/password';

  /// `10f` / `10g` — an admin's invite link. `?token=`.
  static const String setPassword = '/set-password';

  /// `11` — the client's first tab.
  static const String home = '/home';

  // The client shell's other tabs.
  static const String search = '/search';
  static const String bookings = '/bookings';
  static const String messages = '/messages';
  static const String profile = '/profile';

  /// `S2` / `S2a` / `S2b`, inside the Search tab. Filters travel as query
  /// parameters — see [resultsFor].
  static const String results = '/search/results';

  /// The same results, opened from Home — inside the Home tab, so Back
  /// returns to Home rather than to Search.
  static const String homeResults = '/home/results';

  /// `12`. See [serviceFor].
  static const String services = '/services';

  /// `13`. See [providerFor].
  static const String providers = '/providers';

  /// `19`, and `20` below it. See [packsFor] and [packFor].
  static const String packs = '/packs';

  /// `17`.
  static const String favourites = '/favourites';

  /// `14` — the conversations list. See [chatFor] and [chatDraftFor].
  static const String conversations = '/conversations';

  /// `15`, before the first message has picked a conversation id — a chat
  /// started from a profile's Message button.
  static const String chatDraft = '/conversations/new';

  /// `16` — the bell's list.
  static const String notifications = '/notifications';

  /// `18` — the budget, or `18a` in its place until there is one.
  static const String budget = '/budget';

  /// `18f`. Carries the [Budget] as `extra`.
  static const String budgetEdit = '/budget/edit';

  /// `18d`. Carries [ExpenseLineArgs] as `extra`.
  static const String budgetNewLine = '/budget/lines/new';

  /// `18b`, under `/budget/lines/<id>` — see [budgetLineFor]. Carries
  /// [ExpenseLineArgs].
  static const String budgetLines = '/budget/lines';

  /// `18h`. Carries [LinkBookingArgs] as `extra`.
  static const String budgetLinkBooking = '/budget/link';

  /// Section 9: one booking, and what can be done to it. `/booking`, not
  /// `/bookings`, so a booking never reads as the Bookings tab.
  static const String booking = '/booking';

  /// `B2` — carries [RequestSentArgs] as `extra`.
  static const String bookingSent = '/booking/sent';

  /// `21` / `21a` / `21b` — the provider's first tab.
  static const String providerHome = '/provider';

  // The provider shell's other tabs.
  static const String providerRequests = '/provider/requests';
  static const String providerServices = '/provider/services';
  static const String providerMessages = '/provider/messages';
  static const String providerProfile = '/provider/profile';

  // Section 10 · Provider · Booking module. Everything sits under
  // `/provider/` so the role gate ([isProviderOnly]) covers it; none of these
  // is inside the shell — they open full screen, over the tabs.

  /// `P2`–`P2e` — a request or booking, by id.
  static const String providerBooking = '/provider/booking';

  /// `P6` opened on its Packs chip (`P10`) — the Services tab's second list.
  static const String providerPacksTab = '/provider/services?view=packs';

  /// `P7` — a new service.
  static const String providerNewService = '/provider/service/new';

  /// `P11` — a new pack.
  static const String providerNewPack = '/provider/pack/new';

  /// `P11a` — the services a pack is made of; carries [ChooseServicesArgs].
  static const String providerChooseServices = '/provider/pack/services';

  /// `P15` — the availability calendar.
  static const String providerAvailability = '/provider/availability';

  /// `08d` — sending again the documents a reviewer refused. Full screen,
  /// over the provider's tabs.
  static const String resubmitDocuments = '/documents/resubmit';

  /// The component gallery. Only registered in debug builds.
  static const String gallery = '/gallery';

  /// The routes someone without a session may visit.
  static const Set<String> public = <String>{
    onboarding,
    welcome,
    roleSelection,
    register,
    verifyEmail,
    login,
    forgotPassword,
    resetCode,
    resetPassword,
    setPassword,
    gallery,
  };

  static String registerFor(UserRole role) =>
      Uri(path: register, queryParameters: <String, String>{
        'role': role.apiValue,
      }).toString();

  /// Login, optionally prefilled, optionally announcing a finished reset.
  static String loginWith({String? email, bool afterReset = false}) {
    final Map<String, String> query = <String, String>{
      if (email != null && email.isNotEmpty) 'email': email,
      if (afterReset) 'reset': '1',
    };
    // An empty map would still add a bare "?".
    return query.isEmpty
        ? login
        : Uri(path: login, queryParameters: query).toString();
  }

  static String serviceFor(String id) => '$services/$id';

  static String providerFor(String id) => '$providers/$id';

  static String packFor(String id) => '$packs/$id';

  static String budgetLineFor(String id) => '$budgetLines/$id';

  /// `B1`, from 12, on the day picked there.
  static String bookServiceFor(String id, {DateTime? date}) =>
      _withDate('$services/$id/book', date);

  /// `B9`, from 20, on the day picked there.
  static String bookPackFor(String id, {DateTime? date}) =>
      _withDate('$packs/$id/book', date);

  /// `B9a` — carries B9's view model as `extra`.
  static String packReviewFor(String id) => '$packs/$id/book/review';

  /// `B4` and its variants.
  static String bookingFor(String id) => '$booking/$id';

  /// `B6` — carries the [BookingDetail] as `extra`.
  static String rescheduleFor(String id) => '$booking/$id/reschedule';

  /// `B7` — carries the [BookingDetail] as `extra`.
  static String checkInFor(String id) => '$booking/$id/check-in';

  /// `B8`.
  static String invoiceFor(String id) => '$booking/$id/invoice';

  /// `P2`–`P2e`.
  static String providerBookingFor(String id) => '$providerBooking/$id';

  /// `P4` — carries the [BookingDetail] as `extra`.
  static String providerRescheduleFor(String id) => '$providerBooking/$id/reschedule';

  /// `P5` — the booking as `extra` when it is at hand; loaded by id when it
  /// is not (the post-event notification).
  static String providerCheckInFor(String id) => '$providerBooking/$id/check-in';

  /// `P7a`.
  static String providerEditServiceFor(String id) => '/provider/service/$id';

  /// `P8`.
  static String providerServicePhotosFor(String id) => '/provider/service/$id/photos';

  /// `P12`.
  static String providerEditPackFor(String id) => '/provider/pack/$id';

  /// `P13`.
  static String providerPackPhotosFor(String id) => '/provider/pack/$id/photos';

  static String _withDate(String path, DateTime? date) => Uri(
        path: path,
        queryParameters: date == null
            ? null
            : <String, String>{'date': apiDate(date)},
      ).toString();

  /// `15`'s own thread.
  static String chatFor(String id) => '$conversations/$id';

  /// `15` opened before any conversation exists, from a Message button —
  /// carries who it is with and their name, since there is no id yet to look
  /// either up by.
  static String chatDraftFor({required String userId, required String name}) =>
      Uri(
        path: chatDraft,
        queryParameters: <String, String>{'user': userId, 'name': name},
      ).toString();

  /// 19, optionally opened on one event type.
  static String packsFor({EventType? eventType}) => eventType == null
      ? packs
      : Uri(path: packs, queryParameters: <String, String>{
          'eventType': eventType.apiValue,
        }).toString();

  /// Results for [query] — the search text, a category, the filters — at
  /// [base]: [results] from Search, [homeResults] from Home.
  static String resultsFor(ServiceQuery query, {String base = results}) {
    final Map<String, Object> params = query.toRouteParams();
    return Uri(
      path: base,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  /// The screens only a client may see: the shell's tabs and the catalog.
  /// A provider is sent to [providerHome] instead.
  static bool isClientOnly(String path) =>
      path == home ||
      path.startsWith('$home/') ||
      path == search ||
      path.startsWith('$search/') ||
      path == bookings ||
      path == messages ||
      path == profile ||
      path.startsWith('$services/') ||
      path.startsWith('$providers/') ||
      path == packs ||
      path.startsWith('$packs/') ||
      path == favourites ||
      path == budget ||
      path.startsWith('$budget/') ||
      path.startsWith('$booking/');

  /// The screens only a provider may see: their shell and their documents.
  /// A client is sent to [home] instead. Chat (`15`) and the bell (`16`) are
  /// shared, so they are in neither list.
  static bool isProviderOnly(String path) =>
      path == providerHome ||
      path.startsWith('$providerHome/') ||
      path == documents ||
      path.startsWith('$documents/');

  static String resetCodeFor(String email) => Uri(
        path: resetCode,
        queryParameters: <String, String>{'email': email},
      ).toString();
}

/// What `10b` needs to know about the code that was just sent.
class VerifyEmailArgs {
  const VerifyEmailArgs({
    required this.email,
    required this.resendAfterSeconds,
  });

  final String email;
  final int resendAfterSeconds;
}

/// What `10a` carries forward from `10`.
class ResetPasswordArgs {
  const ResetPasswordArgs({required this.email, required this.code});

  final String email;
  final String code;
}

/// Why `10a` sent the user back to `10`.
enum ResetCodeProblem { invalid, expired }

/// What 18d and 18b open with: the budget as it stands — for the line limit
/// and the bookings already in use — and, on 18b, the line.
class ExpenseLineArgs {
  const ExpenseLineArgs({required this.budget, this.item});

  final Budget budget;
  final BudgetItem? item;
}

/// A booking as a line shows it once linked: "EVT-2044 · Fleurs de Yasmina".
class LinkedBooking {
  const LinkedBooking({
    required this.id,
    required this.reference,
    required this.providerName,
  });

  final String id;
  final String reference;
  final String providerName;
}

/// What 18h opens with.
class LinkBookingArgs {
  const LinkBookingArgs({required this.current, required this.usedBy});

  /// The line's booking now, or `null` when it is not linked.
  final LinkedBooking? current;

  /// Bookings already on *other* lines → that line's label. Shown greyed
  /// out, so one amount is never counted twice.
  final Map<String, String> usedBy;
}

/// What 18h hands back when "Link booking" is tapped. A `null` [booking]
/// unlinks the line.
class BookingLinkChoice {
  const BookingLinkChoice(this.booking);

  final LinkedBooking? booking;
}

/// What B2 shows: the booking just made, and how soon the provider
/// usually answers.
class RequestSentArgs {
  const RequestSentArgs({required this.booking, this.replyTime});

  final BookingDetail booking;

  /// "2 h", from the provider's profile.
  final String? replyTime;
}

/// What `P11a` opens with: the services already chosen, in order, and the
/// pack's wilaya — a service that does not cover it cannot be picked. `P11a`
/// pops with the new ordered list of service ids.
class ChooseServicesArgs {
  const ChooseServicesArgs({required this.selected, this.wilayaCode});

  final List<String> selected;
  final int? wilayaCode;
}
