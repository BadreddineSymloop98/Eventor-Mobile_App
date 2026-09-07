/// Names of every route the app can navigate to.
abstract final class AppRoutes {
  /// The screen the app opens on, matching "01 Splash" in the design.
  static const String splash = '/';

  static const String onboarding = '/onboarding';

  /// Where an unauthenticated user lands: the choice between creating an
  /// account and signing in.
  static const String welcome = '/welcome';

  /// Where "Create an account" leads: the fork that decides what the rest of
  /// the app looks like for this person.
  static const String roleSelection = '/role-selection';

  /// The sign-up form. Role selection leads here, carrying the chosen role as
  /// its route argument.
  static const String register = '/register';

  /// Asks where to send a reset link. Reached from the login form.
  static const String forgotPassword = '/forgot-password';

  /// Where a one-time code is entered. Reached from sign-up and from a
  /// password reset, carrying where the code was sent as its argument.
  static const String verifyCode = '/verify-code';

  static const String login = '/login';
  static const String home = '/home';

  /// The app always opens on the splash — it is what covers the moment the
  /// app is working out where to send the user, so it cannot itself depend on
  /// that answer.
  static const String initial = splash;

  /// Where the splash hands over to once it knows.
  ///
  /// Onboarding is a one-time flow: once it has been completed, later launches
  /// go straight to [welcome], which is the design's landing point for anyone
  /// without a session. [login] is reached from there rather than directly —
  /// it is one of two choices, not the default one.
  static String afterSplash({required bool hasSeenOnboarding}) =>
      hasSeenOnboarding ? welcome : onboarding;
}
