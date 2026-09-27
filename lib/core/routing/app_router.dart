import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/documents_repository.dart';
import '../../features/documents/view/documents_view.dart';
import '../../features/documents/view_model/documents_view_model.dart';
import '../../features/forgot_password/view/forgot_password_view.dart';
import '../../features/forgot_password/view_model/forgot_password_view_model.dart';
import '../../features/gallery/view/gallery_view.dart';
import '../../features/home/view/home_view.dart';
import '../../features/home/view_model/home_view_model.dart';
import '../../features/login/view/login_view.dart';
import '../../features/login/view_model/login_view_model.dart';
import '../../features/onboarding/view/onboarding_view.dart';
import '../../features/onboarding/view_model/onboarding_view_model.dart';
import '../../features/register/view/register_view.dart';
import '../../features/register/view_model/register_view_model.dart';
import '../../features/reset_password/view/reset_code_view.dart';
import '../../features/reset_password/view/reset_password_view.dart';
import '../../features/reset_password/view_model/reset_code_view_model.dart';
import '../../features/reset_password/view_model/reset_password_view_model.dart';
import '../../features/role_selection/view/role_selection_view.dart';
import '../../features/role_selection/view_model/role_selection_view_model.dart';
import '../../features/set_password/view/set_password_view.dart';
import '../../features/set_password/view_model/set_password_view_model.dart';
import '../../features/splash/view/splash_view.dart';
import '../../features/verify_email/view/verify_email_view.dart';
import '../../features/verify_email/view_model/verify_email_view_model.dart';
import '../../features/welcome/view/welcome_view.dart';
import '../../features/welcome/view_model/welcome_view_model.dart';
import '../config/app_config.dart';
import '../localization/locale_controller.dart';
import '../models/account.dart';
import '../reference/reference_repository.dart';
import '../services/preferences_service.dart';
import '../session/session_controller.dart';
import '../startup/app_startup.dart';
import 'app_routes.dart';
import 'unknown_route_view.dart';

/// Where a user may be, decided in one place.
///
/// Pulled out of the router so every rule can be tested without a widget:
///
/// * nothing is routed until [AppStartup] is ready — every path waits on the
///   splash, remembering where it was headed (an invite link opened cold);
/// * the splash then hands over to the user's landing: onboarding the first
///   time, then Welcome until one of its doors has been taken, then Login;
///   home (or a one-off landing like `08e`) with a session;
/// * with a session, the pre-auth screens are off limits;
/// * without one, the signed-in screens send the user to that same signed-out
///   landing — or to Login with the "session ended" banner when the session
///   died mid-use.
class AppRedirect {
  const AppRedirect({
    required this.startup,
    required this.session,
    required this.preferences,
  });

  final AppStartup startup;
  final SessionController session;
  final PreferencesService preferences;

  static const String _nextKey = 'next';
  static const String expiredKey = 'expired';

  String? call(Uri uri) {
    final String path = uri.path;

    // The gallery is a developer tool, reachable in any state.
    if (path == AppRoutes.gallery) return null;

    if (!startup.isReady) {
      if (path == AppRoutes.splash) return null;
      return Uri(
        path: AppRoutes.splash,
        queryParameters: <String, String>{_nextKey: uri.toString()},
      ).toString();
    }

    if (path == AppRoutes.splash) {
      final String? next = uri.queryParameters[_nextKey];
      // A deep link that arrived during startup gets its turn now. Only the
      // invite link is honoured this way; anything else lands normally.
      if (next != null && Uri.parse(next).path == AppRoutes.setPassword) {
        return next;
      }
      return _landing();
    }

    final bool isPublic = AppRoutes.public.contains(path);

    if (session.isSignedIn) {
      final AppUser user = session.user!;
      if (isPublic) return _landing();
      if (path == AppRoutes.documents && !user.isProvider) {
        return AppRoutes.home;
      }
      // Reached the one-off landing (a new provider's documents): retire it.
      session.arrivedAt(path);
      return null;
    }

    if (!isPublic) {
      return session.consumeExpired()
          ? Uri(
              path: AppRoutes.login,
              queryParameters: <String, String>{expiredKey: '1'},
            ).toString()
          : _signedOutLanding();
    }
    return null;
  }

  String _landing() {
    if (session.isSignedIn) {
      return session.landing ?? AppRoutes.home;
    }
    return _signedOutLanding();
  }

  /// Onboarding and Welcome are each shown once; after both, the door a
  /// returning user wants is Login — and it links to sign-up for anyone who
  /// does not have an account yet.
  String _signedOutLanding() {
    if (!preferences.hasSeenOnboarding) return AppRoutes.onboarding;
    if (!preferences.hasSeenWelcome) return AppRoutes.welcome;
    return AppRoutes.login;
  }
}

/// Builds the app's [GoRouter].
///
/// Each screen is paired with its view model here, so a view never has to know
/// how its view model is constructed and the view model is disposed together
/// with the route.
abstract final class AppRouter {
  static GoRouter create({
    required AppStartup startup,
    required SessionController session,
    required PreferencesService preferences,
    String initialLocation = AppRoutes.splash,
  }) {
    final AppRedirect redirect = AppRedirect(
      startup: startup,
      session: session,
      preferences: preferences,
    );

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: Listenable.merge(<Listenable>[startup, session]),
      redirect: (BuildContext context, GoRouterState state) =>
          redirect(state.uri),
      errorBuilder: (BuildContext context, GoRouterState state) =>
          UnknownRouteView(routeName: state.uri.toString()),
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, _) => const SplashView(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => _withViewModel<OnboardingViewModel>(
            (BuildContext context) =>
                OnboardingViewModel(context.read<PreferencesService>()),
            const OnboardingView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (_, _) => _withViewModel<WelcomeViewModel>(
            (BuildContext context) =>
                WelcomeViewModel(context.read<PreferencesService>()),
            const WelcomeView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.roleSelection,
          builder: (_, _) => _withViewModel<RoleSelectionViewModel>(
            (_) => RoleSelectionViewModel(),
            const RoleSelectionView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, GoRouterState state) {
            // A register link without a role — typed, or from an old build —
            // is treated as a client's, the one that needs no documents.
            final UserRole role = UserRole.fromApi(
                  state.uri.queryParameters['role'],
                ) ??
                UserRole.client;
            return _withViewModel<RegisterViewModel>(
              (BuildContext context) => RegisterViewModel(
                auth: context.read<AuthRepository>(),
                reference: context.read<ReferenceRepository>(),
                config: context.read<AppConfigRepository>().current,
                role: role,
                languageCode: () => _languageOf(context),
              ),
              const RegisterView(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          redirect: (_, GoRouterState state) =>
              state.extra is VerifyEmailArgs ? null : AppRoutes.login,
          builder: (_, GoRouterState state) =>
              _withViewModel<VerifyEmailViewModel>(
            (BuildContext context) => VerifyEmailViewModel(
              auth: context.read<AuthRepository>(),
              session: context.read<SessionController>(),
              args: state.extra! as VerifyEmailArgs,
            ),
            const VerifyEmailView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.documents,
          builder: (_, _) => _withViewModel<DocumentsViewModel>(
            (BuildContext context) => DocumentsViewModel(
              documents: context.read<DocumentsRepository>(),
              session: context.read<SessionController>(),
            ),
            const DocumentsView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, GoRouterState state) {
            final Map<String, String> query = state.uri.queryParameters;
            return _withViewModel<LoginViewModel>(
              (BuildContext context) => LoginViewModel(
                auth: context.read<AuthRepository>(),
                session: context.read<SessionController>(),
                initialEmail: query['email'],
                sessionExpired: query[AppRedirect.expiredKey] == '1',
              ),
              LoginView(announceReset: query['reset'] == '1'),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => _withViewModel<ForgotPasswordViewModel>(
            (BuildContext context) => ForgotPasswordViewModel(
              auth: context.read<AuthRepository>(),
            ),
            const ForgotPasswordView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetCode,
          redirect: (_, GoRouterState state) =>
              (state.uri.queryParameters['email'] ?? '').isEmpty
                  ? AppRoutes.forgotPassword
                  : null,
          builder: (_, GoRouterState state) => _withViewModel<ResetCodeViewModel>(
            (BuildContext context) => ResetCodeViewModel(
              auth: context.read<AuthRepository>(),
              email: state.uri.queryParameters['email']!,
            ),
            const ResetCodeView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          redirect: (_, GoRouterState state) =>
              state.extra is ResetPasswordArgs ? null : AppRoutes.forgotPassword,
          builder: (_, GoRouterState state) =>
              _withViewModel<ResetPasswordViewModel>(
            (BuildContext context) => ResetPasswordViewModel(
              auth: context.read<AuthRepository>(),
              config: context.read<AppConfigRepository>().current,
              args: state.extra! as ResetPasswordArgs,
            ),
            const ResetPasswordView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.setPassword,
          builder: (_, GoRouterState state) => _withViewModel<SetPasswordViewModel>(
            (BuildContext context) => SetPasswordViewModel(
              auth: context.read<AuthRepository>(),
              session: context.read<SessionController>(),
              config: context.read<AppConfigRepository>().current,
              token: state.uri.queryParameters['token'],
            ),
            const SetPasswordView(),
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => _withViewModel<HomeViewModel>(
            (_) => HomeViewModel(),
            const HomeView(),
          ),
        ),
        if (kDebugMode)
          GoRoute(
            path: AppRoutes.gallery,
            builder: (_, _) => const GalleryView(),
          ),
      ],
    );
  }

  /// Wraps [child] in a [ChangeNotifierProvider] holding its view model,
  /// created from the route's own context so it can read the app's services.
  static Widget _withViewModel<V extends ChangeNotifier>(
    V Function(BuildContext context) create,
    Widget child, {
    Key? key,
  }) {
    return ChangeNotifierProvider<V>(key: key, create: create, child: child);
  }

  /// The language the app is showing, for requests that must name it.
  static String _languageOf(BuildContext context) {
    final Locale? chosen = context.read<LocaleController>().locale;
    return (chosen ?? Localizations.localeOf(context)).languageCode == 'ar'
        ? 'ar'
        : 'en';
  }
}
