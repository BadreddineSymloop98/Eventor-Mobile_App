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

  /// Where a signed-in user lands.
  static const String home = '/home';

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
